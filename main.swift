import AppKit
import SwiftUI
import Speech
import NaturalLanguage

// MARK: - Voice matching (pure, self-tested with --selftest)

typealias Token = (word: String, range: NSRange)

func tokenize(_ s: String) -> [Token] {
    var out: [Token] = []
    s.enumerateSubstrings(in: s.startIndex..., options: .byWords) { w, r, _, _ in
        let norm = w!.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        out.append((norm, NSRange(r, in: s)))
    }
    return out
}

// Where in the script is the speaker? Aligns the last few heard words against script words
// near the cursor; the best-aligned run wins, ties go to the spot closest to the cursor.
// ponytail: exact word match, no fuzzy/phonetic matching; a misheard word just lowers the score.
func locate(heard: [String], in words: [String], from cursor: Int) -> Int? {
    let tail = Array(heard.suffix(4))
    guard let lastHeard = tail.last, !words.isEmpty else { return nil }
    let lo = max(0, cursor - 3), hi = min(words.count - 1, cursor + 30)
    guard lo <= hi else { return nil }
    var best: (score: Int, i: Int)?
    for i in lo...hi where words[i] == lastHeard {
        var score = 0
        for k in 0..<tail.count where i - k >= 0 && words[i - k] == tail[tail.count - 1 - k] { score += 1 }
        if score > best?.score ?? 0 || (score == best?.score && abs(i - cursor) < abs(best!.i - cursor)) { best = (score, i) }
    }
    // One matching word is only trusted right next to the cursor; jumps need context.
    guard let b = best, b.score >= 2 || b.i - cursor <= 2 else { return nil }
    return b.i
}

if CommandLine.arguments.contains("--selftest") {
    let w = tokenize("Hello there, this is a test. This is only a TÉST!").map(\.word)
    precondition(w.last == "test")                                              // case + accents folded
    precondition(locate(heard: ["hello", "there"], in: w, from: 0) == 1)
    precondition(locate(heard: ["this", "is", "only"], in: w, from: 3) == 8)
    precondition(locate(heard: ["a", "test"], in: w, from: 2) == 5)             // repeated phrase: nearest wins
    precondition(locate(heard: ["a", "test"], in: w, from: 9) == 10)
    precondition(locate(heard: ["test"], in: w, from: 0) == nil)                // lone word far ahead: ignored
    precondition(locate(heard: ["banana"], in: w, from: 0) == nil)
    print("selftest ok"); exit(0)
}

// Knobs
let width: CGFloat = 420       // panel width (the notch itself is ~185pt, too narrow to read)
let textHeight: CGFloat = 90   // visible text area below the notch

let defaults = UserDefaults.standard
let screen = NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main!
let notchH = screen.safeAreaInsets.top
let notchW = screen.auxiliaryTopLeftArea.map { screen.frame.width - $0.width - (screen.auxiliaryTopRightArea?.width ?? 0) } ?? 0
let notchFudge: CGFloat = 2    // collapsed island hides this far inside the real notch; raise if a black sliver peeks out
let flare: CGFloat = 8         // concave top corners that melt into the menu bar, like the hardware notch
let height = notchH + textHeight
let winW = width + 2 * flare
let frame = NSRect(x: screen.frame.midX - winW / 2, y: screen.frame.maxY - height, width: winW, height: height)

// MARK: - Prompter panel (sits on the notch)

final class Panel: NSPanel {
    override var canBecomeKey: Bool { true }
    // AppKit pushes windows below the menu bar; we want to sit on top of it.
    override func constrainFrameRect(_ r: NSRect, to s: NSScreen?) -> NSRect { r }

    override func sendEvent(_ e: NSEvent) {
        switch e.type {
        case .leftMouseDown: model.paused.toggle()
        case .keyDown:
            switch e.keyCode {
            case 49: model.paused.toggle()                    // space
            case 126: model.speed += 5                        // up
            case 125: model.speed = max(5, model.speed - 5)   // down
            case 15: model.restart()                          // r
            default: break
            }
            return
        default: break
        }
        super.sendEvent(e)
    }
}

let panel = Panel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
panel.level = .screenSaver
panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
panel.sharingType = .none // invisible to screen share and screenshots
panel.isOpaque = false
panel.backgroundColor = .clear
panel.hasShadow = false
panel.hidesOnDeactivate = false

let content = NSView(frame: NSRect(origin: .zero, size: frame.size))
content.wantsLayer = true
content.layer!.backgroundColor = NSColor.black.cgColor
let island = CAShapeLayer()
island.frame = content.bounds
content.layer!.mask = island
panel.contentView = content

// Notch silhouette: concave flare at the top, rounded bottom. Same element count in every
// state so Core Animation can morph between them.
func islandPath(w: CGFloat, h: CGFloat, r: CGFloat, t: CGFloat) -> CGPath {
    let x0 = (winW - w) / 2, x1 = x0 + w, y = height - h, H = height
    let p = CGMutablePath()
    p.move(to: CGPoint(x: x0 - t, y: H))
    p.addQuadCurve(to: CGPoint(x: x0, y: H - t), control: CGPoint(x: x0, y: H))
    p.addLine(to: CGPoint(x: x0, y: y + r))
    p.addQuadCurve(to: CGPoint(x: x0 + r, y: y), control: CGPoint(x: x0, y: y))
    p.addLine(to: CGPoint(x: x1 - r, y: y))
    p.addQuadCurve(to: CGPoint(x: x1, y: y + r), control: CGPoint(x: x1, y: y))
    p.addLine(to: CGPoint(x: x1, y: H - t))
    p.addQuadCurve(to: CGPoint(x: x1 + t, y: H), control: CGPoint(x: x1, y: H))
    p.closeSubpath()
    return p
}
let collapsedPath = islandPath(w: max(0, notchW - 2 * notchFudge), h: max(0, notchH - notchFudge), r: min(8, notchH / 3), t: 0)
let expandedPath = islandPath(w: width, h: height, r: 20, t: flare)
island.path = collapsedPath

func setExpanded(_ open: Bool) {
    let spring = CASpringAnimation(keyPath: "path")
    spring.fromValue = island.presentation()?.path ?? island.path // smooth even if interrupted mid-animation
    spring.toValue = open ? expandedPath : collapsedPath
    spring.mass = 1
    spring.stiffness = open ? 170 : 260
    spring.damping = open ? 16 : 26   // open: slight bounce; close: snappy, no overshoot
    spring.duration = spring.settlingDuration
    island.path = (spring.toValue as! CGPath)
    island.add(spring, forKey: "morph")

    panel.ignoresMouseEvents = !open // collapsed: clicks fall through to the menu bar
    DispatchQueue.main.asyncAfter(deadline: .now() + (open ? 0.15 : 0)) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = open ? 0.3 : 0.12
            scroll.animator().alphaValue = open ? 1 : 0
        }
    }
}

let scroll = NSTextView.scrollableTextView()
scroll.frame = NSRect(x: flare, y: 0, width: width, height: textHeight)
scroll.alphaValue = 0
scroll.drawsBackground = false
scroll.hasVerticalScroller = false
scroll.verticalScrollElasticity = .none
let tv = scroll.documentView as! NSTextView
tv.isEditable = false
tv.isSelectable = false
tv.drawsBackground = false
tv.textContainerInset = NSSize(width: 14, height: textHeight) // first line enters from below, last scrolls fully out
tv.textColor = .white
tv.alignment = .center
content.addSubview(scroll)

func scrollTo(_ y: CGFloat) {
    scroll.contentView.scroll(to: NSPoint(x: 0, y: y))
    scroll.reflectScrolledClipView(scroll.contentView)
}

// MARK: - Shared state (saved between launches)

final class Prompter: ObservableObject {
    @Published var paused = true
    @Published var voice = false { didSet { voice ? listener.start() : listener.stop() } }
    var words: [Token] = []
    var cursor = 0                  // index of the last word you said
    var voiceTarget: CGFloat?       // scroll position that puts that word on the top line
    @Published var visible = true { didSet { setExpanded(visible) } }
    @Published var text = defaults.string(forKey: "text") ?? "Paste your script here, then press Play." {
        didSet { defaults.set(text, forKey: "text"); tv.string = text; restart() }
    }
    @Published var speed = defaults.object(forKey: "speed") as? Double ?? 25 { didSet { defaults.set(speed, forKey: "speed") } }
    @Published var fontSize = defaults.object(forKey: "fontSize") as? Double ?? 18 {
        didSet { defaults.set(fontSize, forKey: "fontSize"); applyFont() }
    }

    func applyFont() {
        tv.font = .systemFont(ofSize: fontSize, weight: .medium)
        tv.textColor = .white
    }

    // Back to the top with the first line visible, paused.
    func restart() {
        paused = true
        words = tokenize(text); cursor = 0; voiceTarget = nil
        tv.layoutManager!.ensureLayout(for: tv.textContainer!)
        scrollTo(textHeight - fontSize * 1.5)
    }
}

let model = Prompter()

// MARK: - Listening (on-device speech recognition)

final class Listener {
    let engine = AVAudioEngine()
    var task: SFSpeechRecognitionTask?

    func start() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { status == .authorized ? self.run() : (model.voice = false) }
        }
    }

    // Pick a recognizer in the script's language (a pt-BR script works on an English Mac).
    func recognizer() -> SFSpeechRecognizer? {
        guard let lang = NLLanguageRecognizer.dominantLanguage(for: model.text)?.rawValue else { return SFSpeechRecognizer() }
        let locales = SFSpeechRecognizer.supportedLocales().filter { $0.language.languageCode?.identifier == lang }
        let locale = locales.first { $0.region == Locale.current.region } ?? locales.min { $0.identifier < $1.identifier }
        return locale.flatMap(SFSpeechRecognizer.init(locale:)) ?? SFSpeechRecognizer()
    }

    func run() {
        guard model.voice, let rec = recognizer(), rec.isAvailable else { model.voice = false; return }
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = rec.supportsOnDeviceRecognition // private, and no 1-minute cap
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buf, _ in req.append(buf) }
        engine.prepare()
        do { try engine.start() } catch { model.voice = false; return }

        var me: SFSpeechRecognitionTask?
        me = rec.recognitionTask(with: req) { result, error in
            DispatchQueue.main.async {
                guard self.task === me else { return } // stale callback from a previous task
                if let result { self.heard(result.bestTranscription.formattedString) }
                // Recognition tasks end on long silences; quietly start a fresh one.
                if error != nil || result?.isFinal == true {
                    self.stop()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { if model.voice { self.run() } }
                }
            }
        }
        task = me
    }

    func heard(_ transcript: String) {
        let heard = tokenize(transcript).map(\.word)
        guard let i = locate(heard: heard, in: model.words.map(\.word), from: model.cursor) else { return }
        model.cursor = i
        let lm = tv.layoutManager!
        let glyphs = lm.glyphRange(forCharacterRange: model.words[i].range, actualCharacterRange: nil)
        let lineY = lm.lineFragmentRect(forGlyphAt: glyphs.location, effectiveRange: nil).minY + tv.textContainerOrigin.y
        model.voiceTarget = lineY - 4
    }

    func stop() {
        task?.cancel(); task = nil
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
    }
}
let listener = Listener()
tv.string = model.text
model.applyFont()

// MARK: - Control window

struct ControlView: View {
    @ObservedObject var p: Prompter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $p.text)
                .font(.body)
                .frame(minHeight: 200)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
            HStack {
                Text("Speed").frame(width: 40, alignment: .leading)
                Slider(value: $p.speed, in: 5...120).disabled(p.voice)
                Text("\(Int(p.speed))").monospacedDigit().frame(width: 30)
            }
            HStack {
                Text("Size").frame(width: 40, alignment: .leading)
                Slider(value: $p.fontSize, in: 12...32)
                Text("\(Int(p.fontSize))").monospacedDigit().frame(width: 30)
            }
            HStack {
                Button(p.paused ? "▶ Play" : "⏸ Pause") { p.paused.toggle() }
                    .keyboardShortcut(.return, modifiers: .command)
                Button("↺ Restart") { p.restart() }
                    .keyboardShortcut("r", modifiers: .command)
                Toggle("🎙 Follow my voice", isOn: $p.voice)
                Spacer()
                Toggle("Open on notch", isOn: $p.visible)
            }
            Text("Voice mode scrolls as you read aloud · ⌘↩ play/pause · ⌘R restart · click the notch to pause · scroll on it to move")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 460, minHeight: 380)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

// Without a main menu, ⌘V/⌘C/⌘Q don't work.
let mainMenu = NSMenu()
let appItem = NSMenuItem(), editItem = NSMenuItem()
mainMenu.addItem(appItem); mainMenu.addItem(editItem)
appItem.submenu = NSMenu()
appItem.submenu!.addItem(withTitle: "About Cadence", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
appItem.submenu!.addItem(withTitle: "Quit Cadence", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
editItem.submenu = NSMenu(title: "Edit")
for (title, sel, key) in [("Undo", "undo:", "z"), ("Redo", "redo:", "Z"), ("Cut", "cut:", "x"),
                          ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
    editItem.submenu!.addItem(withTitle: title, action: Selector(sel), keyEquivalent: key)
}
app.mainMenu = mainMenu

let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
                      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
window.title = "Cadence"
window.contentView = NSHostingView(rootView: ControlView(p: model))
window.isReleasedWhenClosed = false
window.center()
// Closing the control window quits the app (and removes the notch panel).
NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
    NSApp.terminate(nil)
}

panel.orderFrontRegardless()
model.restart()
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { setExpanded(true) }
window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)

final class Ticker: NSObject {
    var last: CFTimeInterval = 0
    @objc func tick(_ link: CADisplayLink) {
        let dt = last == 0 ? 0 : min(0.1, link.timestamp - last); last = link.timestamp
        if model.voice {
            // Glide toward the line you're reading instead of jumping (~200ms ease-out).
            guard let target = model.voiceTarget else { return }
            let y = scroll.contentView.bounds.origin.y
            if abs(target - y) > 0.25 { scrollTo(y + (target - y) * (1 - exp(-dt * 8))) }
            return
        }
        guard !model.paused else { return }
        let maxY = tv.frame.height - scroll.contentView.bounds.height
        let y = scroll.contentView.bounds.origin.y
        if y < maxY { scrollTo(min(maxY, y + model.speed * dt)) } else { model.paused = true }
    }
}
let ticker = Ticker()
scroll.displayLink(target: ticker, selector: #selector(Ticker.tick)).add(to: .main, forMode: .common)

// Self-check: panel is centered on the notch and flush with the top edge.
precondition(abs(panel.frame.midX - screen.frame.midX) < 1 && abs(panel.frame.maxY - screen.frame.maxY) < 1, "panel misplaced: \(panel.frame)")

app.run()
