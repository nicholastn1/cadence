// Cadence sync server: sign in with Google, then keep each person's scripts in one JSON file.
//
//	GOOGLE_CLIENT_ID  OAuth client the app signs in with (required)
//	ALLOWED_EMAILS    comma-separated; empty = anyone with a Google account
//	DATA_DIR, PORT    default /data and 8080
package main

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"log"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"
)

// Script is opaque to the server except for what merging needs.
type Script struct {
	ID       string
	Modified float64
	Raw      json.RawMessage
}

func (s *Script) UnmarshalJSON(b []byte) error {
	var head struct {
		ID       string  `json:"id"`
		Modified float64 `json:"modified"`
	}
	if err := json.Unmarshal(b, &head); err != nil {
		return err
	}
	s.ID, s.Modified, s.Raw = head.ID, head.Modified, append(json.RawMessage(nil), b...)
	return nil
}

func (s Script) MarshalJSON() ([]byte, error) { return s.Raw, nil }

// merge keeps the newest copy of each script; deletions are scripts too (tombstones), so they win the same way.
func merge(stored, incoming []Script) []Script {
	out := append([]Script(nil), stored...)
	at := map[string]int{}
	for i, s := range out {
		at[s.ID] = i
	}
	for _, s := range incoming {
		if i, ok := at[s.ID]; !ok {
			at[s.ID] = len(out)
			out = append(out, s)
		} else if s.Modified > out[i].Modified {
			out[i] = s
		}
	}
	return out
}

type session struct {
	Sub     string `json:"sub"`
	Email   string `json:"email"`
	Created int64  `json:"created"` // unix seconds
}

const (
	sessionTTL     = 180 * 24 * time.Hour // then the app asks you to sign in again
	sessionsPerSub = 10                   // a new sign-in past this drops your oldest session
	maxStored      = 20 << 20             // bytes of scripts per person, tombstones included
)

func (s session) expired() bool { return time.Since(time.Unix(s.Created, 0)) > sessionTTL }

// prune drops expired sessions and keeps only the newest few per person, so the file can't grow forever.
func prune(sessions map[string]session) {
	bySub := map[string][]string{}
	for h, s := range sessions {
		if s.expired() {
			delete(sessions, h)
		} else {
			bySub[s.Sub] = append(bySub[s.Sub], h)
		}
	}
	for _, hs := range bySub {
		sort.Slice(hs, func(i, j int) bool { return sessions[hs[i]].Created > sessions[hs[j]].Created })
		for _, h := range hs[min(len(hs), sessionsPerSub):] {
			delete(sessions, h)
		}
	}
}

var (
	dataDir  = env("DATA_DIR", "/data")
	clientID = os.Getenv("GOOGLE_CLIENT_ID")
	allowed  = os.Getenv("ALLOWED_EMAILS")
	mu       sync.Mutex // ponytail: one lock for every user's file; per-user locks if this ever has many users
	subRe    = regexp.MustCompile(`^[0-9]+$`)
)

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func hash(s string) string { h := sha256.Sum256([]byte(s)); return hex.EncodeToString(h[:]) }

func readJSON(path string, v any) {
	if b, err := os.ReadFile(path); err == nil {
		json.Unmarshal(b, v)
	}
}

// writeJSON replaces the file in one step, so a crash never leaves half a file.
func writeJSON(path string, v any) error {
	b, err := json.Marshal(v)
	if err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, b, 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

// verifyGoogle asks Google whether the ID token is real and was issued to our app.
func verifyGoogle(idToken string) (session, bool) {
	resp, err := http.Get("https://oauth2.googleapis.com/tokeninfo?id_token=" + url.QueryEscape(idToken))
	if err != nil {
		return session{}, false
	}
	defer resp.Body.Close()
	var info struct {
		Aud, Sub, Email, Iss string
		EmailVerified        string `json:"email_verified"`
	}
	if resp.StatusCode != 200 || json.NewDecoder(resp.Body).Decode(&info) != nil {
		return session{}, false
	}
	ok := info.Aud == clientID && info.EmailVerified == "true" && subRe.MatchString(info.Sub) &&
		(info.Iss == "accounts.google.com" || info.Iss == "https://accounts.google.com")
	return session{Sub: info.Sub, Email: info.Email, Created: time.Now().Unix()}, ok
}

func emailAllowed(email string) bool {
	if allowed == "" {
		return true
	}
	for _, a := range strings.Split(allowed, ",") {
		if strings.EqualFold(strings.TrimSpace(a), email) {
			return true
		}
	}
	return false
}

func signIn(w http.ResponseWriter, r *http.Request) {
	var body struct {
		IDToken string `json:"id_token"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		http.Error(w, "bad request", 400)
		return
	}
	s, ok := verifyGoogle(body.IDToken)
	if !ok {
		http.Error(w, "invalid Google sign-in", 401)
		return
	}
	if !emailAllowed(s.Email) {
		http.Error(w, "this account isn't allowed on this server", 403)
		return
	}
	b := make([]byte, 32)
	rand.Read(b)
	token := hex.EncodeToString(b)

	mu.Lock()
	defer mu.Unlock()
	sessions := map[string]session{}
	path := filepath.Join(dataDir, "sessions.json")
	readJSON(path, &sessions)
	sessions[hash(token)] = s // only the hash is stored: a leaked file doesn't leak sessions
	prune(sessions)
	if writeJSON(path, sessions) != nil {
		http.Error(w, "couldn't save the session", 500)
		return
	}
	json.NewEncoder(w).Encode(map[string]string{"token": token, "email": s.Email})
}

func syncScripts(w http.ResponseWriter, r *http.Request) {
	token, _ := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
	var body struct {
		Scripts []Script `json:"scripts"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		http.Error(w, "bad request", 400)
		return
	}

	mu.Lock()
	defer mu.Unlock()
	sessions := map[string]session{}
	readJSON(filepath.Join(dataDir, "sessions.json"), &sessions)
	s, ok := sessions[hash(token)]
	if token == "" || !ok || s.expired() {
		http.Error(w, "signed out", 401)
		return
	}
	path := filepath.Join(dataDir, "users", s.Sub+".json")
	var stored []Script
	readJSON(path, &stored)
	merged := merge(stored, body.Scripts)
	if b, _ := json.Marshal(merged); len(b) > maxStored {
		http.Error(w, "you've reached the storage limit for scripts", 413)
		return
	}
	if writeJSON(path, merged) != nil {
		http.Error(w, "couldn't save your scripts", 500)
		return
	}
	json.NewEncoder(w).Encode(map[string][]Script{"scripts": merged})
}

// signOut ends this session on the server, not just in the app.
func signOut(w http.ResponseWriter, r *http.Request) {
	token, _ := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
	mu.Lock()
	defer mu.Unlock()
	path := filepath.Join(dataDir, "sessions.json")
	sessions := map[string]session{}
	readJSON(path, &sessions)
	delete(sessions, hash(token))
	writeJSON(path, sessions)
	w.WriteHeader(204)
}

func main() {
	if clientID == "" {
		log.Fatal("GOOGLE_CLIENT_ID is required")
	}
	if err := os.MkdirAll(filepath.Join(dataDir, "users"), 0o700); err != nil {
		log.Fatal(err)
	}
	limit := func(h http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) { r.Body = http.MaxBytesReader(w, r.Body, 10<<20); h(w, r) }
	}
	http.HandleFunc("POST /auth/google", limit(signIn))
	http.HandleFunc("POST /auth/signout", limit(signOut))
	http.HandleFunc("POST /sync", limit(syncScripts))
	http.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) })
	port := env("PORT", "8080")
	log.Printf("listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
