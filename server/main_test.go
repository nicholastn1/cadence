package main

import (
	"encoding/json"
	"fmt"
	"testing"
	"time"
)

func TestMerge(t *testing.T) {
	var stored, incoming []Script
	json.Unmarshal([]byte(`[{"id":"a","modified":1,"text":"old"},{"id":"b","modified":5,"text":"keep"}]`), &stored)
	json.Unmarshal([]byte(`[{"id":"a","modified":2,"text":"new"},{"id":"b","modified":4,"text":"stale"},{"id":"c","modified":1,"deleted":true}]`), &incoming)
	out, _ := json.Marshal(merge(stored, incoming))
	want := `[{"id":"a","modified":2,"text":"new"},{"id":"b","modified":5,"text":"keep"},{"id":"c","modified":1,"deleted":true}]`
	if string(out) != want {
		t.Fatalf("got %s", out)
	}
}

func TestPrune(t *testing.T) {
	now := time.Now().Unix()
	sessions := map[string]session{"old": {Sub: "1", Created: now - int64(sessionTTL.Seconds()) - 1}}
	for i := 0; i < sessionsPerSub+2; i++ {
		sessions[fmt.Sprint(i)] = session{Sub: "1", Created: now - int64(i)}
	}
	sessions["other"] = session{Sub: "2", Created: now}
	prune(sessions)
	_, old := sessions["old"]
	_, newest := sessions["0"]
	_, oldest := sessions[fmt.Sprint(sessionsPerSub)]
	if old || !newest || oldest || len(sessions) != sessionsPerSub+1 {
		t.Fatalf("got %v", sessions)
	}
}
