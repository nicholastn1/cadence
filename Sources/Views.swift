import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var m: Prompter
    @ObservedObject var u = updater
    @Environment(\.openWindow) var openWindow

    var body: some View {
        NavigationSplitView {
            List(selection: $m.selectedID) {
                ForEach(m.scripts) { s in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(s.title).lineLimit(1)
                        Text("\(s.wordCount) words").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 3)
                    .tag(s.id)
                    .contextMenu { Button("Delete Script", role: .destructive) { m.delete(s.id) } }
                }
            }
            .onDeleteCommand { if let id = m.selectedID { m.delete(id) } }
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                for p in providers {
                    _ = p.loadObject(ofClass: URL.self) { url, _ in
                        if let url { DispatchQueue.main.async { model.importScripts([url]) } }
                    }
                }
                return true
            }
            .safeAreaInset(edge: .bottom) {
                if let r = u.available {
                    Button { openWindow(id: "whats-new") } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.down.circle.fill").font(.title3).foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Update available").font(.callout.weight(.semibold))
                                Text("Cadence \(r.version): see what's new").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.background.opacity(0.6)))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 230)
            .toolbar {
                Button { m.newScript() } label: { Label("New Script", systemImage: "square.and.pencil") }
                    .help("New script (⌘N)")
            }
        } detail: {
            ZStack(alignment: .bottom) {
                ScriptEditor(text: Binding(get: { m.currentText }, set: { m.currentText = $0 }))
                VStack(spacing: 12) {
                    if let t = m.lastTake { TakeCard(take: t) { m.lastTake = nil } }
                    Transport(m: m)
                }
                .padding(.bottom, 22)
            }
            .navigationTitle(m.current?.title ?? "Cadence")
            .navigationSubtitle(m.current.map { String(localized: "\($0.wordCount) words, \($0.readTime) to read") } ?? "")
            .toolbar {
                ToolbarItemGroup {
                    Button { editor.wrap("**", "**", placeholder: String(localized: "word")) } label: { Label("Stress", systemImage: "bold") }
                        .help("Stress a word: **word** (⌘B)")
                    Button { editor.wrap("==", "==", placeholder: String(localized: "phrase")) } label: { Label("Highlight", systemImage: "highlighter") }
                        .help("Highlight: ==phrase== (⇧⌘H)")
                    Button { editor.wrap("[", "]", placeholder: String(localized: "pause")) } label: { Label("Note to self", systemImage: "flag") }
                        .help("Note to yourself, never read aloud: [pause] (⌘K)")
                }
                ToolbarItem {
                    Menu {
                        Picker("Voice language", selection: Binding(get: { m.current?.language ?? "" },
                                                                    set: { m.setLanguage($0.isEmpty ? nil : $0) })) {
                            Text("Automatic: \(Locale.current.localizedString(forIdentifier: m.locale.identifier) ?? m.locale.identifier)").tag("")
                            Divider()
                            ForEach(speechLanguages, id: \.id) { l in (l.onDevice ? Text(l.name) : Text("\(l.name) (online)")).tag(l.id) }
                        }
                        .pickerStyle(.inline)
                        Divider()
                        Text("Languages marked online send audio to Apple. To use one offline, add it in System Settings > Keyboard > Dictation.")
                    } label: {
                        Label("Voice Language", systemImage: "globe")
                    }
                    .help("Language Cadence listens for in this script")
                }
                ToolbarItem {
                    Toggle(isOn: $m.settings.showOnNotch) { Label("Show on Notch", systemImage: "menubar.rectangle") }
                        .help("Show on notch")
                }
            }
        }
        .onAppear { if updater.justUpdated() { openWindow(id: "whats-new") } }
        .alert("Voice mode stopped", isPresented: Binding(get: { m.voiceError != nil }, set: { if !$0 { m.voiceError = nil } })) {
            Button("OK") {}
        } message: {
            Text(m.voiceError ?? "")
        }
    }
}

final class Caption: ObservableObject { @Published var text: String? }

/// The playback bar: a small black island echoing the one on the notch.
struct Transport: View {
    @ObservedObject var m: Prompter
    @StateObject private var caption = Caption() // instant caption for the hovered control
    private var hint: String? { caption.text }

    var body: some View {
        HStack(spacing: 18) {
            Button { m.restart() } label: { Image(systemName: "backward.end.fill") }
                .help("Back to the top (⌘R)")
                .onHover { caption.text = $0 ? "Back to the top" : nil }

            Button { m.togglePlay() } label: {
                ZStack {
                    Circle().fill(Color(nsColor: Palette.script))
                    if let c = m.countdown {
                        Text("\(c)").font(.system(size: 19, weight: .bold, design: .rounded)).monospacedDigit()
                    } else {
                        Image(systemName: m.paused ? "play.fill" : "pause.fill").font(.system(size: 16, weight: .black))
                            .offset(x: m.paused ? 1.5 : 0)
                    }
                }
                .foregroundStyle(.black)
                .frame(width: 42, height: 42)
            }
            .disabled(m.voice)
            .opacity(m.voice ? 0.3 : 1)
            .help(m.paused ? "Play (⌘↩)" as LocalizedStringKey : "Pause (⌘↩)")
            .onHover { caption.text = $0 ? (m.voice ? "Your voice is in control" : m.isRunning ? "Pause" : "Play") : nil }

            Button { m.voice.toggle() } label: {
                Image(systemName: m.voice ? "mic.fill" : "mic")
                    .foregroundStyle(m.voice ? Color(nsColor: Palette.tally) : .white)
            }
            .help(m.voice ? "Stop following your voice (⌘L)" as LocalizedStringKey : "Follow my voice (⌘L)")
            .onHover { caption.text = $0 ? (m.voice ? "Stop listening" : "Follow my voice: scrolls as you read aloud") : nil }

            Rectangle().fill(.white.opacity(0.16)).frame(width: 1, height: 24)

            Group {
                if m.voice {
                    HStack(spacing: 8) {
                        Circle().fill(Color(nsColor: Palette.tally)).frame(width: 8, height: 8).opacity(m.listening && !m.offScript ? 1 : 0.3)
                        Text(!m.listening ? "Starting the microphone" as LocalizedStringKey
                             : m.offScript ? "Off script. Waiting for you."
                             : m.onDevice ? "Listening. Start reading." : "Listening online. Start reading.")
                            .foregroundStyle(.white.opacity(0.85))
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "tortoise.fill").foregroundStyle(.white.opacity(0.5))
                        Slider(value: $m.settings.speed, in: 8...120).tint(.white)
                        Image(systemName: "hare.fill").foregroundStyle(.white.opacity(0.5))
                    }
                    .help("Scroll speed")
                    .onHover { caption.text = $0 ? "Scroll speed" : nil }
                }
            }
            .font(.system(size: 13, weight: .medium))
            .frame(width: 200, alignment: .leading)
        }
        .buttonStyle(.plain)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 22)
        .frame(height: 62)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.black))
        .shadow(color: .black.opacity(0.28), radius: 20, y: 10)
        .overlay(alignment: .top) {
            if let hint {
                Text(LocalizedStringKey(hint))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(.black.opacity(0.85)))
                    .fixedSize()
                    .offset(y: -36)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeOut(duration: 0.12), value: hint)
        .environment(\.colorScheme, .dark)
    }
}

/// How the last voice take went: total time, average pace, and the slowest sentence.
struct TakeCard: View {
    let take: TakeSummary
    let close: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 22) {
            stat("Time", Text(Duration.seconds(take.seconds).formatted(.time(pattern: .minuteSecond))))
            stat("Pace", Text("\(take.wpm) words a minute"))
            if let s = take.slowest, let w = take.slowestWPM {
                stat("Slowest part", Text("“\(s)” at \(w)")).frame(maxWidth: 240, alignment: .leading)
            }
            Button(action: close) { Image(systemName: "xmark").font(.system(size: 11, weight: .bold)) }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                .help("Dismiss")
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.regularMaterial))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.separator))
    }

    func stat(_ label: LocalizedStringKey, _ value: Text) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            value.font(.callout.weight(.semibold)).lineLimit(2)
        }
    }
}

/// Opens .txt, .md, .docx and .rtf files as new scripts.
func showImportPanel() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = true
    panel.allowedContentTypes = [.plainText, .rtf] + ["md", "markdown", "docx"].compactMap { UTType(filenameExtension: $0) }
    panel.message = String(localized: "Choose scripts to import. Bold text in Word files becomes stress.")
    if panel.runModal() == .OK { model.importScripts(panel.urls) }
}

/// Lets toolbar buttons and menu commands reach the editor's selection.
final class EditorProxy {
    weak var textView: NSTextView?

    func wrap(_ open: String, _ close: String, placeholder: String) {
        guard let tv = textView else { return }
        let r = tv.selectedRange()
        let selected = (tv.string as NSString).substring(with: r)
        let body = selected.isEmpty ? placeholder : selected
        tv.insertText(open + body + close, replacementRange: r) // goes through undo
        tv.setSelectedRange(NSRange(location: r.location + (open as NSString).length, length: (body as NSString).length))
        tv.window?.makeFirstResponder(tv)
    }
}

let editor = EditorProxy()

struct ScriptEditor: NSViewRepresentable {
    @Binding var text: String
    let column: CGFloat = 640 // ~68 characters of 17pt New York

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        let tv = scroll.documentView as! NSTextView
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.allowsUndo = true
        tv.drawsBackground = false
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.font = editorFont
        tv.textContainerInset = NSSize(width: 40, height: 28)
        tv.string = text
        styleEditor(tv.textStorage!)
        scroll.drawsBackground = false
        scroll.automaticallyAdjustsContentInsets = false
        scroll.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 110, right: 0) // room for the playback bar
        scroll.contentView.postsFrameChangedNotifications = true
        context.coordinator.observer = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification, object: scroll.contentView, queue: .main
        ) { [column] _ in
            tv.textContainerInset.width = max(40, (scroll.contentSize.width - column) / 2) // centered reading column
        }
        editor.textView = tv
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        let tv = scroll.documentView as! NSTextView
        if tv.string != text { // switched scripts
            tv.string = text
            styleEditor(tv.textStorage!)
            tv.setSelectedRange(NSRange(location: 0, length: 0))
            tv.scrollToBeginningOfDocument(nil)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ScriptEditor
        var observer: Any?
        init(_ parent: ScriptEditor) { self.parent = parent }

        func textDidChange(_ n: Notification) {
            let tv = n.object as! NSTextView
            styleEditor(tv.textStorage!)
            tv.typingAttributes = [.font: editorFont, .foregroundColor: NSColor.labelColor]
            parent.text = tv.string
        }
    }
}

struct SettingsView: View {
    @ObservedObject var m: Prompter

    var body: some View {
        Form {
            Section("General") {
                Toggle(isOn: $m.settings.showInMenuBar) {
                    Text("Show in menu bar")
                    Text("Cadence keeps running there when you quit from the Dock.")
                }
            }
            Section("Notch panel") {
                Picker("Display", selection: $m.settings.displayID) {
                    Text("Automatic").tag(0)
                    ForEach(NSScreen.screens, id: \.displayID) { Text($0.localizedName).tag($0.displayID) }
                }
                LabeledContent("Width") { Slider(value: $m.settings.width, in: 320...720) }
                Stepper("Visible lines: \(m.settings.lines)", value: $m.settings.lines, in: 2...6)
                Toggle(isOn: $m.settings.hoverToOpen) {
                    Text("Open on hover")
                    Text("Stays tucked into the notch until you point at it or start reading.")
                }
            }
            Section("Reading") {
                LabeledContent("Text size") { Slider(value: $m.settings.fontSize, in: 14...34) }
                Picker("Countdown", selection: $m.settings.countdown) {
                    Text("Off").tag(0)
                    Text("3 seconds").tag(3)
                    Text("5 seconds").tag(5)
                }
                Toggle(isOn: $m.settings.mirror) {
                    Text("Mirror text")
                    Text("Flips the text for teleprompter glass.")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct PrompterCommands: Commands {
    @ObservedObject var m: Prompter
    @Environment(\.openWindow) var openWindow

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Check for Updates…") {
                openWindow(id: "whats-new")
                Task { await updater.check(manual: true) }
            }
            Button("What's New") { openWindow(id: "whats-new") }
        }
        CommandGroup(replacing: .newItem) {
            Button("New Script") { m.newScript() }.keyboardShortcut("n")
            Button("Import Script…") { showImportPanel() }.keyboardShortcut("o")
        }
        CommandGroup(after: .textFormatting) {
            Button("Stress") { editor.wrap("**", "**", placeholder: String(localized: "word")) }.keyboardShortcut("b")
            Button("Highlight") { editor.wrap("==", "==", placeholder: String(localized: "phrase")) }.keyboardShortcut("h", modifiers: [.command, .shift])
            Button("Note to Self") { editor.wrap("[", "]", placeholder: String(localized: "pause")) }.keyboardShortcut("k")
        }
        CommandMenu("Prompter") {
            Button(m.isRunning && !m.voice ? "Pause" as LocalizedStringKey : "Play") { m.togglePlay() }
                .keyboardShortcut(.return)
                .disabled(m.voice)
            Button("Back to Top") { m.restart() }.keyboardShortcut("r")
            Toggle("Follow My Voice", isOn: $m.voice).keyboardShortcut("l")
            Divider()
            Button("Faster") { m.settings.speed = min(120, m.settings.speed + 4) }.keyboardShortcut("]")
            Button("Slower") { m.settings.speed = max(8, m.settings.speed - 4) }.keyboardShortcut("[")
            Divider()
            Toggle("Show on Notch", isOn: $m.settings.showOnNotch)
            Toggle("Mirror Text", isOn: $m.settings.mirror)
        }
    }
}
