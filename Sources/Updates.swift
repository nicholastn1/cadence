import SwiftUI

let repo = "nicholastn1/cadence"

/// "0.10.0" is newer than "0.9.2". Pre-release suffixes ("-dev") are ignored.
func isNewer(_ a: String, than b: String) -> Bool {
    func parts(_ v: String) -> [Int] {
        v.split(separator: "-").first.map { $0.split(separator: ".").map { Int($0) ?? 0 } } ?? []
    }
    let x = parts(a), y = parts(b)
    for i in 0..<max(x.count, y.count) {
        let l = i < x.count ? x[i] : 0, r = i < y.count ? y[i] : 0
        if l != r { return l > r }
    }
    return false
}

/// Checks GitHub Releases for a newer version and installs it through Homebrew when possible.
final class Updater: ObservableObject {
    struct Release: Decodable {
        let tag_name: String
        let body: String?
        let html_url: String
        var version: String { String(tag_name.drop { $0 == "v" }) }
    }

    @Published var latest: Release?
    @Published var status: String?          // result of the last manual check or update attempt
    @Published var busy = false

    let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0-dev"
    var isDevBuild: Bool { current.hasSuffix("-dev") }
    var available: Release? { latest.flatMap { isNewer($0.version, than: current) ? $0 : nil } }

    var brew: String? { ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"].first { FileManager.default.isExecutableFile(atPath: $0) } }
    var installedWithBrew: Bool {
        brew != nil && ["/opt/homebrew/Caskroom/cadence", "/usr/local/Caskroom/cadence"].contains { FileManager.default.fileExists(atPath: $0) }
    }

    /// Daily background check; dev builds only check when asked.
    func startChecking() {
        guard !isDevBuild else { return }
        Task { await check() }
        Timer.scheduledTimer(withTimeInterval: 24 * 3600, repeats: true) { _ in Task { await self.check() } }
    }

    @MainActor func check(manual: Bool = false) async {
        busy = true
        defer { busy = false }
        do {
            var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!)
            req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, _) = try await URLSession.shared.data(for: req)
            latest = try JSONDecoder().decode(Release.self, from: data)
            if manual { status = available.map { String(localized: "Cadence \($0.version) is available.") } ?? String(localized: "You're up to date. \(current) is the latest version.") }
        } catch {
            if manual { status = String(localized: "Couldn't reach GitHub to check for updates. Check your connection and try again.") }
        }
    }

    @MainActor func update() {
        guard let release = available else { return }
        guard installedWithBrew, let brew else {
            NSWorkspace.shared.open(URL(string: release.html_url)!)
            return
        }
        busy = true
        status = String(localized: "Updating with Homebrew…")
        let p = Process()
        p.executableURL = URL(fileURLWithPath: brew)
        p.arguments = ["upgrade", "--cask", "cadence"]
        var env = ProcessInfo.processInfo.environment
        env["HOMEBREW_AUTO_UPDATE_SECS"] = "0" // refresh the tap first, or brew may not see the new version yet
        env["HOMEBREW_NO_ENV_HINTS"] = "1"
        p.environment = env
        p.terminationHandler = { p in
            DispatchQueue.main.async {
                self.busy = false
                let path = "/Applications/Cadence.app" // where the cask installs it
                let installed = Bundle(path: path)?.infoDictionary?["CFBundleShortVersionString"] as? String
                guard p.terminationStatus == 0, installed == release.version else {
                    self.status = String(localized: "Homebrew didn't install \(release.version). Run `brew upgrade --cask cadence` in Terminal to see why.")
                    return
                }
                // Relaunch the new version once this one has quit.
                let relaunch = Process()
                relaunch.executableURL = URL(fileURLWithPath: "/bin/sh")
                relaunch.arguments = ["-c", "sleep 1; open \"\(path)\""]
                try? relaunch.run()
                AppDelegate.quitting = true
                NSApp.terminate(nil)
            }
        }
        do { try p.run() } catch { busy = false; status = String(localized: "Homebrew didn't start: \(error.localizedDescription)") }
    }

    /// True once per version: the first launch after an update.
    func justUpdated() -> Bool {
        let seen = defaults.string(forKey: "lastSeenVersion")
        defaults.set(current, forKey: "lastSeenVersion")
        return seen != nil && seen != current
    }
}

let updater = Updater()

/// What's New: an available update with its notes, then the changelog that shipped with this version.
struct WhatsNewView: View {
    @ObservedObject var u: Updater
    var changelog: String {
        Bundle.main.url(forResource: "CHANGELOG", withExtension: "md").flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 14) {
                    Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cadence \(u.current)").font(.title2.weight(.semibold))
                        (u.status.map { Text($0) } ?? Text(u.available == nil ? "Teleprompter in your notch" as LocalizedStringKey : "A new version is ready."))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if u.busy { ProgressView().controlSize(.small) }
                    Button("Check for Updates") { Task { await u.check(manual: true) } }.disabled(u.busy)
                }

                if let r = u.available {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Cadence \(r.version) is available").font(.headline)
                            Spacer()
                            Button(u.installedWithBrew ? "Update and Relaunch" as LocalizedStringKey : "Download") { u.update() }
                                .buttonStyle(.borderedProminent)
                                .disabled(u.busy)
                        }
                        MarkdownNotes(markdown: r.body ?? "")
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.accentColor.opacity(0.08)))
                }

                Text("Release history").font(.headline).padding(.top, 4)
                MarkdownNotes(markdown: changelog.range(of: "\n## ").map { String(changelog[$0.lowerBound...]) } ?? changelog)
            }
            .padding(24)
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 420, idealHeight: 560)
    }
}

/// Just enough Markdown for a changelog: version headings, bullets, and inline styles.
struct MarkdownNotes: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(markdown.components(separatedBy: .newlines).enumerated()), id: \.offset) { _, raw in
                let line = raw.trimmingCharacters(in: .whitespaces)
                if line.hasPrefix("## ") {
                    let title = line.dropFirst(3).replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
                    Text(title.replacingOccurrences(of: " - ", with: "   ")).font(.title3.weight(.semibold)).padding(.top, 10)
                } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•").foregroundStyle(.secondary)
                        Text(inline(String(line.dropFirst(2))))
                    }
                } else if !line.isEmpty, !line.hasPrefix("# ") {
                    Text(inline(line)).foregroundStyle(.secondary)
                }
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func inline(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
    }
}
