import AppKit
import AuthenticationServices
import CryptoKit

/// Sign in with Google, then keep scripts in step across Macs through the Cadence server. The newest edit wins.
final class Sync: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    static let server = URL(string: "https://cadence.nicholastn.dev")!
    static let clientID = "392431029605-0e0qkej78f3kj72gufkfpek8974dbjqf.apps.googleusercontent.com" // an "iOS" OAuth client for this bundle ID
    var scheme: String { "com.googleusercontent.apps." + Self.clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "") }
    var redirect: String { scheme + ":/oauth2redirect" }

    @Published var email: String?
    @Published var status: String?          // why the last sign-in or sync failed
    @Published var busy = false
    private var token: String?
    private var auth: ASWebAuthenticationSession?
    private var pending: DispatchWorkItem?

    // The session token lives in a file only you can read. Not the Keychain: Cadence is ad-hoc signed,
    // so every update would make macOS ask again for access to it.
    private let file = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Cadence/session.json")

    override init() {
        super.init()
        if let d = try? Data(contentsOf: file), let s = try? JSONDecoder().decode([String: String].self, from: d) {
            token = s["token"]
            email = s["email"]
        }
    }

    /// Syncs when Cadence comes to the front and every minute while it's open.
    func start() {
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            Task { await self.sync() }
        }
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in Task { await self.sync() } }
        Task { await sync() }
    }

    /// Called on every change to the scripts: sync once you pause.
    func changed() {
        guard token != nil else { return }
        pending?.cancel()
        let work = DispatchWorkItem { Task { await self.sync() } }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.keyWindow ?? NSApp.windows.first { $0.isVisible } ?? NSWindow()
    }

    /// Google's sign-in page in a browser sheet, with PKCE, so the app needs no client secret.
    func signIn() {
        let verifier = Data((0..<32).map { _ in UInt8.random(in: 0...255) }).base64URL
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URL
        var url = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        url.queryItems = [
            .init(name: "client_id", value: Self.clientID), .init(name: "redirect_uri", value: redirect),
            .init(name: "response_type", value: "code"), .init(name: "scope", value: "openid email"),
            .init(name: "code_challenge", value: challenge), .init(name: "code_challenge_method", value: "S256"),
        ]
        status = nil
        auth = ASWebAuthenticationSession(url: url.url!, callbackURLScheme: scheme) { callback, error in
            let code = callback.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems?.first { $0.name == "code" }?.value
            guard let code else {
                if (error as? ASWebAuthenticationSessionError)?.code != .canceledLogin {
                    DispatchQueue.main.async { self.status = String(localized: "Google sign-in didn't finish. Try again.") }
                }
                return
            }
            Task { await self.finishSignIn(code: code, verifier: verifier) }
        }
        auth?.presentationContextProvider = self
        auth?.start()
    }

    @MainActor func finishSignIn(code: String, verifier: String) async {
        busy = true
        defer { busy = false }
        do {
            var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
            req.httpMethod = "POST"
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            var form = URLComponents()
            form.queryItems = [
                .init(name: "code", value: code), .init(name: "client_id", value: Self.clientID),
                .init(name: "code_verifier", value: verifier), .init(name: "redirect_uri", value: redirect),
                .init(name: "grant_type", value: "authorization_code"),
            ]
            req.httpBody = form.percentEncodedQuery?.data(using: .utf8)
            let (d, _) = try await URLSession.shared.data(for: req)
            guard let idToken = (try? JSONSerialization.jsonObject(with: d) as? [String: Any])?["id_token"] as? String else {
                status = String(localized: "Google didn't confirm the sign-in. Try again.")
                return
            }
            let s: [String: String] = try await post("auth/google", ["id_token": idToken])
            guard let t = s["token"] else { return }
            token = t
            email = s["email"]
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(s).write(to: file)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
            await sync()
        } catch {
            status = error.localizedDescription
        }
    }

    /// Scripts stay on this Mac; it just stops syncing them. The server forgets the session too.
    func signOut() {
        if let token {
            var req = URLRequest(url: Self.server.appendingPathComponent("auth/signout"))
            req.httpMethod = "POST"
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: req).resume()
        }
        token = nil
        email = nil
        try? FileManager.default.removeItem(at: file)
    }

    private var syncing = false

    @MainActor func sync() async {
        guard token != nil, !syncing else { return }
        syncing = true
        defer { syncing = false }
        do {
            let r: [String: [Script]] = try await post("sync", ["scripts": model.scripts])
            status = nil
            model.applyRemote(r["scripts"] ?? [])
        } catch SyncError.signedOut {
            signOut()
            status = String(localized: "You were signed out. Sign in again to keep syncing.")
        } catch {
            status = String(localized: "Couldn't sync: \(error.localizedDescription)")
        }
    }

    enum SyncError: LocalizedError {
        case signedOut, server(String)
        var errorDescription: String? { if case .server(let m) = self { m } else { nil } }
    }

    private func post<In: Encodable, Out: Decodable>(_ path: String, _ body: In) async throws -> Out {
        var req = URLRequest(url: Self.server.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONEncoder().encode(body)
        let (d, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if code == 401, path == "sync" { throw SyncError.signedOut }
        guard code == 200 else {
            let message = String(data: d, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw SyncError.server(message.isEmpty ? String(localized: "The server answered \(code).") : message)
        }
        return try JSONDecoder().decode(Out.self, from: d)
    }
}

extension Data {
    var base64URL: String {
        base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}

let syncer = Sync()
