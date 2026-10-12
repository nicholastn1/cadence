import AppKit

let defaults = UserDefaults.standard

func persist<T: Encodable>(_ value: T, _ key: String) { defaults.set(try? JSONEncoder().encode(value), forKey: key) }
func load<T: Decodable>(_ key: String) -> T? { defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) } }

struct Script: Codable, Identifiable, Equatable {
    var id = UUID()
    var text: String
    var modified = Date()
    var language: String?   // speech locale picked for this script; nil = detect from the text

    var title: String {
        let line = text.split(whereSeparator: \.isNewline).first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let clean = String(line ?? "").replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "==", with: "")
            .trimmingCharacters(in: .whitespaces)
        return clean.isEmpty ? "Untitled script" : String(clean.prefix(60))
    }
    var wordCount: Int { text.split(whereSeparator: \.isWhitespace).count }
    var readTime: String { // at a speaking pace of ~150 words a minute
        let minutes = Double(wordCount) / 150
        return minutes < 1 ? "under a minute" : "about \(Int(minutes.rounded())) min"
    }
}

struct Settings: Codable, Equatable {
    var speed = 28.0        // points per second
    var fontSize = 20.0
    var width = 440.0       // the notch itself is ~185pt, too narrow to read
    var lines = 3
    var mirror = false
    var countdown = 3       // seconds, 0 = off
    var hoverToOpen = true
    var showOnNotch = true
    var displayID = 0       // 0 = the screen with a notch, else the main screen
    var showInMenuBar = true

    /// Saved settings layered over the defaults, so fields added in new versions keep their defaults.
    static func saved() -> Settings {
        let base = (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(Settings()))) as? [String: Any] ?? [:]
        let stored = defaults.data(forKey: "settings").flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any] ?? [:]
        let merged = try? JSONSerialization.data(withJSONObject: base.merging(stored) { $1 })
        return merged.flatMap { try? JSONDecoder().decode(Settings.self, from: $0) } ?? Settings()
    }
}

let welcomeScript = """
Welcome to Cadence.
This text sits in your MacBook's notch, right under the camera, so you keep eye contact while you read.

Press Play to scroll at a steady pace, or turn on the microphone and just start reading out loud. [pause]

Cadence listens on your Mac and scrolls as you speak. If you stop, it waits. If you go back, it follows.

Use **double asterisks** for words to stress, ==double equals== to highlight, and square brackets for notes to yourself, like [smile] or [breathe]. Notes are never read.

Make a new script with Command N. Everything saves automatically.
"""

final class Prompter: ObservableObject {
    @Published var scripts: [Script] { didSet { persist(scripts, "scripts") } }
    @Published var selectedID: UUID? {
        didSet {
            guard selectedID != oldValue else { return }
            defaults.set(selectedID?.uuidString, forKey: "selected")
            notch.renderText()
            restart()
        }
    }
    @Published var settings: Settings {
        didSet {
            guard settings != oldValue else { return }
            persist(settings, "settings")
            if settings.fontSize != oldValue.fontSize { notch.renderText() }
            if !settings.showInMenuBar { NSApp.setActivationPolicy(.regular) } // never leave the app with no icon anywhere
            notch.layout()
        }
    }

    @Published var paused = true
    @Published var countdown: Int?          // 3, 2, 1 before playback starts
    @Published var voice = false {
        didSet {
            guard voice != oldValue else { return }
            if voice {
                paused = true
                countdown = nil
                cursor = notch.tokenIndexAtTop()
                listener.start()
            } else {
                listener.stop()
                listening = false
                offScript = false
                voiceTarget = nil
            }
        }
    }
    @Published var listening = false        // mic is live: drives the tally light
    @Published var onDevice = true          // false: recognition goes through Apple's servers
    @Published var offScript = false        // you're saying things that aren't in the script
    @Published var voiceError: String?

    var tokens: [Token] = []                // spoken words of the current script
    var locale = Locale.current             // the script's language
    var cursor = 0                          // index of the last word you said
    var voiceTarget: CGFloat?               // scroll position that puts that word on the top line
    private var countdownRun = UUID()

    init() {
        scripts = load("scripts") ?? []
        settings = Settings.saved()
        if scripts.isEmpty { scripts = [Script(text: defaults.string(forKey: "text") ?? welcomeScript)] } // "text": v0.1's single script
        let saved = UUID(uuidString: defaults.string(forKey: "selected") ?? "")
        _selectedID = Published(initialValue: scripts.contains { $0.id == saved } ? saved : scripts.first?.id) // no didSet during init
    }

    var current: Script? { scripts.first { $0.id == selectedID } }
    var currentText: String {
        get { current?.text ?? "" }
        set {
            guard let i = scripts.firstIndex(where: { $0.id == selectedID }), scripts[i].text != newValue else { return }
            scripts[i].text = newValue
            scripts[i].modified = Date()
            notch.renderText()
        }
    }

    func setLanguage(_ id: String?) {
        guard let i = scripts.firstIndex(where: { $0.id == selectedID }) else { return }
        scripts[i].language = id
        notch.renderText()
        if voice { listener.stop(); listener.run() } // listen in the new language right away
    }

    func newScript() {
        let s = Script(text: "")
        scripts.insert(s, at: 0)
        selectedID = s.id
    }

    func delete(_ id: UUID) {
        scripts.removeAll { $0.id == id }
        if scripts.isEmpty { scripts = [Script(text: "")] }
        if !scripts.contains(where: { $0.id == selectedID }) { selectedID = scripts.first?.id }
    }

    var isRunning: Bool { !paused || countdown != nil || voice }

    func togglePlay() {
        if voice { voice = false; return }
        if isRunning { stop(); return }
        guard settings.countdown > 0 else { paused = false; return }
        countdown = settings.countdown
        let run = UUID()
        countdownRun = run
        func step() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                guard countdownRun == run, let c = countdown else { return } // cancelled
                if c > 1 { countdown = c - 1; step() } else { countdown = nil; paused = false }
            }
        }
        step()
    }

    func stop() {
        paused = true
        countdown = nil
        countdownRun = UUID()
    }

    func restart() {
        stop()
        cursor = 0
        voiceTarget = nil
        notch.scrollToStart()
    }
}

let model = Prompter()
