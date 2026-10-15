import AppKit

let defaults = UserDefaults.standard

func persist<T: Encodable>(_ value: T, _ key: String) { defaults.set(try? JSONEncoder().encode(value), forKey: key) }
func load<T: Decodable>(_ key: String) -> T? { defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) } }

struct TakeSummary: Equatable {
    var seconds: Double
    var wpm: Int
    var slowest: String?    // first words of the slowest sentence
    var slowestWPM: Int?
}

/// Reads a script file. Bold text in Word and RTF documents becomes **stress**.
func readScript(_ url: URL) -> String? {
    let ext = url.pathExtension.lowercased()
    if ext == "docx" || ext == "rtf" {
        let type: NSAttributedString.DocumentType = ext == "docx" ? .officeOpenXML : .rtf
        guard let doc = try? NSAttributedString(url: url, options: [.documentType: type], documentAttributes: nil) else { return nil }
        let out = NSMutableString(string: doc.string)
        var bold: [NSRange] = []
        doc.enumerateAttribute(.font, in: NSRange(location: 0, length: doc.length)) { value, range, _ in
            guard let f = value as? NSFont, NSFontManager.shared.traits(of: f).contains(.boldFontMask) else { return }
            let text = (doc.string as NSString).substring(with: range)
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !text.contains("\n") { bold.append(range) }
        }
        for r in bold.reversed() { out.insert("**", at: NSMaxRange(r)); out.insert("**", at: r.location) }
        return out as String
    }
    guard let text = (try? String(contentsOf: url, encoding: .utf8)) ?? (try? String(contentsOf: url, encoding: .isoLatin1)) else { return nil }
    // Markdown headings would show their # marks on the notch.
    return ext == "md" || ext == "markdown" ? text.replacingOccurrences(of: #"(?m)^#{1,6}\s+"#, with: "", options: .regularExpression) : text
}

/// Bold survives import from RTF and Word; Markdown heading marks are dropped.
func importSelfTest() {
    let dir = FileManager.default.temporaryDirectory
    let doc = NSMutableAttributedString(string: "Hello ", attributes: [.font: NSFont.systemFont(ofSize: 12)])
    doc.append(NSAttributedString(string: "big", attributes: [.font: NSFont.boldSystemFont(ofSize: 12)]))
    doc.append(NSAttributedString(string: " world", attributes: [.font: NSFont.systemFont(ofSize: 12)]))
    let rtf = dir.appendingPathComponent("cadence-test.rtf"), docx = dir.appendingPathComponent("cadence-test.docx")
    try! doc.rtf(from: NSRange(location: 0, length: doc.length))!.write(to: rtf)
    try! doc.data(from: NSRange(location: 0, length: doc.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.officeOpenXML]).write(to: docx)
    precondition(readScript(rtf) == "Hello **big** world")
    precondition(readScript(docx)?.trimmingCharacters(in: .whitespacesAndNewlines) == "Hello **big** world")
    let md = dir.appendingPathComponent("cadence-test.md")
    try! "# Title\nBody".write(to: md, atomically: true, encoding: .utf8)
    precondition(readScript(md) == "Title\nBody")
}

struct Script: Codable, Identifiable, Equatable {
    var id = UUID()
    var text: String
    var modified = Date()
    var language: String?   // speech locale picked for this script; nil = detect from the text
    var name: String?       // set by renaming; nil = the first line
    var deleted: Bool?      // a tombstone, kept so the deletion reaches your other Macs

    var title: String {
        if let name { return name }
        let line = text.split(whereSeparator: \.isNewline).first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let clean = String(line ?? "").replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "==", with: "")
            .trimmingCharacters(in: .whitespaces)
        return clean.isEmpty ? String(localized: "Untitled script") : String(clean.prefix(60))
    }
    var wordCount: Int { text.split(whereSeparator: \.isWhitespace).count }
    var readTime: String { // at a speaking pace of ~150 words a minute
        let minutes = Double(wordCount) / 150
        return minutes < 1 ? String(localized: "under a minute") : String(localized: "about \(Int(minutes.rounded())) min")
    }
}

/// The newest copy of each script wins; scripts only one side has are kept. The server merges the same way.
func mergeScripts(_ local: [Script], _ remote: [Script]) -> [Script] {
    var out = local, added: [Script] = []
    for r in remote {
        if let i = out.firstIndex(where: { $0.id == r.id }) {
            if r.modified > out[i].modified { out[i] = r }
        } else { added.append(r) }
    }
    return added + out
}

func mergeSelfTest() {
    let t = Date()
    var a = Script(text: "one"), b = Script(text: "two")
    a.modified = t; b.modified = t
    var newerA = a; newerA.text = "one, edited"; newerA.modified = t + 1
    var staleB = b; staleB.text = "old"; staleB.modified = t - 1
    let c = Script(text: "from the other Mac")
    precondition(mergeScripts([a, b], [newerA, staleB, c]) == [c, newerA, b])
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

let welcomeScript = String(localized: "welcome-script", defaultValue: """
Welcome to Cadence.
This text sits in your MacBook's notch, right under the camera, so you keep eye contact while you read.

Press Play to scroll at a steady pace, or turn on the microphone and just start reading out loud. [pause]

Cadence listens on your Mac and scrolls as you speak. If you stop, it waits. If you go back, it follows.

Use **double asterisks** for words to stress, ==double equals== to highlight, and square brackets for notes to yourself, like [smile] or [breathe]. Notes are never read.

Make a new script with Command N. Everything saves automatically.
""")

final class Prompter: ObservableObject {
    @Published var scripts: [Script] { didSet { persist(scripts, "scripts"); syncer.changed() } } // includes tombstones
    var visible: [Script] { scripts.filter { $0.deleted != true } }
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
                take = []
                lastTake = nil
                listener.start()
            } else {
                listener.stop()
                listening = false
                offScript = false
                summarizeTake()
                notch.markProgress()
                voiceTarget = nil
            }
        }
    }
    @Published var listening = false        // mic is live: drives the tally light
    @Published var onDevice = true          // false: recognition goes through Apple's servers
    @Published var offScript = false        // you're saying things that aren't in the script
    @Published var voiceError: String?
    @Published var lastTake: TakeSummary?   // shown after a voice take ends

    var tokens: [Token] = []                // spoken words of the current script
    var locale = Locale.current             // the script's language
    var cursor = 0                          // index of the last word you said
    var voiceTarget: CGFloat?               // scroll position that puts that word on the top line
    var sentences: [(chars: NSRange, words: Range<Int>)] = []
    var take: [(t: Double, i: Int)] = []    // when each word was reached in this voice take
    private var countdownRun = UUID()

    init() {
        scripts = load("scripts") ?? []
        settings = Settings.saved()
        if visible.isEmpty { scripts.insert(Script(text: defaults.string(forKey: "text") ?? welcomeScript), at: 0) } // "text": v0.1's single script
        let saved = UUID(uuidString: defaults.string(forKey: "selected") ?? "")
        _selectedID = Published(initialValue: visible.contains { $0.id == saved } ? saved : visible.first?.id) // no didSet during init
    }

    var current: Script? { visible.first { $0.id == selectedID } }
    var currentText: String {
        get { current?.text ?? "" }
        set {
            guard let i = scripts.firstIndex(where: { $0.id == selectedID }), scripts[i].text != newValue else { return }
            scripts[i].text = newValue
            scripts[i].modified = Date()
            notch.renderText()
        }
    }

    func summarizeTake() {
        defer { take = [] }
        guard let s = takeStats(take, sentences: sentences.map(\.words)) else { return }
        let snippet = s.slowest.map { n -> String in
            let words = (notch.tv.string as NSString).substring(with: sentences[n].chars).split(separator: " ")
            return words.prefix(6).joined(separator: " ") + (words.count > 6 ? "…" : "")
        }
        lastTake = TakeSummary(seconds: s.seconds, wpm: s.wpm, slowest: snippet, slowestWPM: s.slowestWPM)
    }

    func importScripts(_ urls: [URL]) {
        for url in urls {
            guard let text = readScript(url) else { continue }
            let s = Script(text: text)
            scripts.insert(s, at: 0)
            selectedID = s.id
        }
    }

    func setLanguage(_ id: String?) {
        guard let i = scripts.firstIndex(where: { $0.id == selectedID }) else { return }
        scripts[i].language = id
        scripts[i].modified = Date()
        notch.renderText()
        if voice { listener.stop(); listener.run() } // listen in the new language right away
    }

    func newScript() {
        let s = Script(text: "")
        scripts.insert(s, at: 0)
        selectedID = s.id
    }

    func rename(_ id: UUID, to name: String) {
        guard let i = scripts.firstIndex(where: { $0.id == id }) else { return }
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        scripts[i].name = clean.isEmpty ? nil : clean // clearing the name goes back to the first line
        scripts[i].modified = Date()
    }

    func delete(_ id: UUID) {
        guard let i = scripts.firstIndex(where: { $0.id == id }) else { return }
        scripts[i] = Script(id: id, text: "", modified: Date(), deleted: true) // the text goes too, here and on the server
        if visible.isEmpty { scripts.insert(Script(text: ""), at: 0) }
        if !visible.contains(where: { $0.id == selectedID }) { selectedID = visible.first?.id }
    }

    /// Takes in what the server sent, keeping any edits made while the request was out.
    func applyRemote(_ remote: [Script]) {
        let merged = mergeScripts(scripts, remote)
        guard merged != scripts else { return }
        let before = current
        scripts = merged
        if !visible.contains(where: { $0.id == selectedID }) { selectedID = visible.first?.id }
        else if current != before { notch.renderText() }
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
        take = []
        notch.scrollToStart()
        notch.markProgress()
    }
}

let model = Prompter()
