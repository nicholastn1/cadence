import SwiftUI

@main
struct CadenceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject var m = model

    init() {
        if CommandLine.arguments.contains("--selftest") { runSelfTest(); exit(0) }
    }

    var body: some Scene {
        Window("Cadence", id: "main") {
            ContentView(m: model).frame(minWidth: 720, minHeight: 440)
        }
        .defaultSize(width: 960, height: 620)
        .commands { PrompterCommands(m: model) }

        Window("What's New in Cadence", id: "whats-new") { WhatsNewView(u: updater) }
            .defaultSize(width: 560, height: 600)
            .windowResizability(.contentMinSize)

        // Only write real changes: AppKit echoes the value back, and every write re-renders the app body.
        MenuBarExtra(isInserted: Binding(get: { m.settings.showInMenuBar },
                                         set: { if $0 != m.settings.showInMenuBar { m.settings.showInMenuBar = $0 } })) {
            MenuBarMenu(m: model)
        } label: {
            Image(nsImage: menuBarIcon)
        }

        SwiftUI.Settings { SettingsView(m: model) }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var quitting = false // static: under SwiftUI, NSApp.delegate is not this object

    func applicationDidFinishLaunching(_ n: Notification) {
        notch.start()
        updater.startChecking()
    }

    // With the menu bar icon showing, quitting from the Dock or with Command-Q only hides
    // the window and Dock icon. Quit in the menu bar menu really quits.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard model.settings.showInMenuBar, !AppDelegate.quitting else { return .terminateNow }
        // Logout, restart and shutdown carry a quit reason; never block those.
        if NSAppleEventManager.shared().currentAppleEvent?.attributeDescriptor(forKeyword: AEKeyword(kAEQuitReason)) != nil { return .terminateNow }
        NSApp.windows.filter { $0.isVisible && !($0 is Panel) && $0.className != "NSStatusBarWindow" }.forEach { $0.close() }
        NSApp.setActivationPolicy(.accessory)
        return .terminateCancel
    }
}

/// Template image for the menu bar: the app icon's idea at 18pt. A small notch, then script lines shaped like a wave.
let menuBarIcon: NSImage = {
    let img = NSImage(size: NSSize(width: 18, height: 16), flipped: false) { _ in
        NSColor.black.setFill()
        NSBezierPath(roundedRect: NSRect(x: 6, y: 13, width: 6, height: 4), xRadius: 1.5, yRadius: 1.5).fill() // notch
        for (i, w) in ([8, 14, 10, 12] as [CGFloat]).enumerated() {
            NSBezierPath(roundedRect: NSRect(x: 9 - w / 2, y: 9.5 - CGFloat(i) * 3, width: w, height: 1.8), xRadius: 0.9, yRadius: 0.9).fill()
        }
        return true
    }
    img.isTemplate = true
    return img
}()

struct MenuBarMenu: View {
    @ObservedObject var m: Prompter
    @ObservedObject var u = updater
    @Environment(\.openWindow) var openWindow

    func show(_ id: String) {
        NSApp.setActivationPolicy(.regular)
        openWindow(id: id)
        NSApp.activate(ignoringOtherApps: true)
    }

    var body: some View {
        if let r = u.available {
            Button("Update to Cadence \(r.version)…") { show("whats-new") }
            Divider()
        }
        Button(m.isRunning && !m.voice ? "Pause" : "Play") { m.togglePlay() }.disabled(m.voice)
        Toggle("Follow My Voice", isOn: $m.voice)
        Button("Back to Top") { m.restart() }
        Divider()
        Picker("Script", selection: $m.selectedID) {
            ForEach(m.scripts) { Text($0.title).tag(Optional($0.id)) }
        }
        Toggle("Show on Notch", isOn: $m.settings.showOnNotch)
        Divider()
        Button("Open Cadence") { show("main") }
        Button("Check for Updates…") { show("whats-new"); Task { await u.check(manual: true) } }
        SettingsLink { Text("Settings…") }
        Button("Hide Menu Bar Icon") { m.settings.showInMenuBar = false }
        Divider()
        Button("Quit Cadence") {
            AppDelegate.quitting = true
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
