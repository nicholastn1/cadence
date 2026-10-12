import AppKit

final class Panel: NSPanel {
    override var canBecomeKey: Bool { true }
    // AppKit pushes windows below the menu bar; the panel belongs on top of it.
    override func constrainFrameRect(_ r: NSRect, to s: NSScreen?) -> NSRect { r }

    override func sendEvent(_ e: NSEvent) {
        switch e.type {
        case .leftMouseDown: model.togglePlay()
        case .keyDown:
            switch e.keyCode {
            case 49: model.togglePlay()                                              // space
            case 126: model.settings.speed = min(120, model.settings.speed + 4)      // up
            case 125: model.settings.speed = max(8, model.settings.speed - 4)        // down
            case 15: model.restart()                                                 // r
            default: break
            }
            return
        default: break
        }
        super.sendEvent(e)
    }
}

/// Bottom fade so the line you're reading stands out and the next ones recede.
final class FadeView: NSView {
    override init(frame: NSRect) { super.init(frame: frame); wantsLayer = true }
    required init?(coder: NSCoder) { nil }
    override func hitTest(_ p: NSPoint) -> NSView? { nil }
    override func makeBackingLayer() -> CALayer {
        let g = CAGradientLayer()
        g.colors = [NSColor.black.cgColor, NSColor.black.withAlphaComponent(0).cgColor]
        g.locations = [0, 0.6]
        return g
    }
}

extension NSScreen {
    var displayID: Int { (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.intValue ?? 0 }
}

/// The panel on the notch: geometry, the spring morph, hover, countdown and scrolling.
final class Notch: NSObject {
    let flare: CGFloat = 8          // concave top corners that melt into the menu bar
    let notchFudge: CGFloat = 2     // collapsed island hides this far inside the real notch; raise if a sliver peeks out
    let readingInset: CGFloat = 6   // gap between the notch and the line you're reading

    let panel = Panel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    let content = NSView()
    let island = CAShapeLayer()
    let stage = NSView()            // holds the text; flipped for mirror mode
    let scroll = NSTextView.scrollableTextView()
    let fade = FadeView()
    let countLabel = NSTextField(labelWithString: "")
    var tv: NSTextView { scroll.documentView as! NSTextView }

    var expanded = false
    var collapsedPath = CGMutablePath(), expandedPath = CGMutablePath()
    var hoverZone = NSRect.zero
    var textHeight: CGFloat = 0
    var lastHover: CFTimeInterval = 0, lastTick: CFTimeInterval = 0
    var shownCount: Int?

    func start() {
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.sharingType = .none // invisible to screen sharing and screenshots
        if ProcessInfo.processInfo.environment["CADENCE_CAPTURABLE"] == "1" { panel.sharingType = .readOnly } // for screenshots
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true

        content.wantsLayer = true
        content.layer!.backgroundColor = NSColor.black.cgColor
        content.layer!.mask = island
        panel.contentView = content

        scroll.drawsBackground = false
        scroll.hasVerticalScroller = false
        scroll.verticalScrollElasticity = .none
        tv.isEditable = false
        tv.isSelectable = false
        tv.drawsBackground = false
        stage.wantsLayer = true
        stage.alphaValue = 0
        stage.addSubview(scroll)
        countLabel.font = .systemFont(ofSize: 44, weight: .bold)
        countLabel.textColor = Palette.script
        countLabel.alignment = .center
        countLabel.isHidden = true
        countLabel.wantsLayer = true
        content.addSubview(stage)
        content.addSubview(fade)
        content.addSubview(countLabel)

        renderText()
        layout()
        scrollToStart()
        panel.orderFrontRegardless()
        lastHover = CACurrentMediaTime() + 1.5 // say hello at launch, even in hover mode
        scroll.displayLink(target: self, selector: #selector(tick)).add(to: .main, forMode: .common)
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.layout()
        }
    }

    func targetScreen() -> NSScreen {
        let id = model.settings.displayID
        if id != 0, let s = NSScreen.screens.first(where: { $0.displayID == id }) { return s }
        return NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    func layout() {
        let s = model.settings, screen = targetScreen()
        let notchH = screen.safeAreaInsets.top
        let notchW = screen.auxiliaryTopLeftArea.map { screen.frame.width - $0.width - (screen.auxiliaryTopRightArea?.width ?? 0) } ?? 0
        let w = CGFloat(s.width)
        textHeight = CGFloat(s.lines) * CGFloat(s.fontSize) * 1.3 + 14
        let height = notchH + textHeight, winW = w + 2 * flare
        panel.setFrame(NSRect(x: screen.frame.midX - winW / 2, y: screen.frame.maxY - height, width: winW, height: height), display: false)
        content.frame = NSRect(x: 0, y: 0, width: winW, height: height)
        island.frame = content.bounds
        stage.frame = NSRect(x: flare, y: 0, width: w, height: textHeight)
        scroll.frame = stage.bounds
        fade.frame = stage.frame
        countLabel.frame = NSRect(x: flare, y: (textHeight - 54) / 2, width: w, height: 54)
        tv.textContainerInset = NSSize(width: 16, height: textHeight) // first line enters from below, last scrolls fully out
        stage.layer!.sublayerTransform = s.mirror
            ? CATransform3DConcat(CATransform3DMakeScale(-1, 1, 1), CATransform3DMakeTranslation(w, 0, 0))
            : CATransform3DIdentity

        collapsedPath = islandPath(w: max(0, notchW - 2 * notchFudge), h: max(0, notchH - notchFudge), r: min(8, notchH / 3), t: 0, winW: winW, height: height)
        expandedPath = islandPath(w: w, h: height, r: 20, t: flare, winW: winW, height: height)
        island.removeAllAnimations()
        island.path = expanded ? expandedPath : collapsedPath

        let zoneW = max(notchW, 220), zoneH = max(notchH, 6)
        hoverZone = NSRect(x: screen.frame.midX - zoneW / 2, y: screen.frame.maxY - zoneH, width: zoneW, height: zoneH + 4)
        tv.layoutManager!.ensureLayout(for: tv.textContainer!)
        scrollTo(min(scroll.contentView.bounds.origin.y, maxY))
    }

    // Notch silhouette: concave flare at the top, rounded bottom. Same element count in every
    // state so Core Animation can morph between them.
    func islandPath(w: CGFloat, h: CGFloat, r: CGFloat, t: CGFloat, winW: CGFloat, height H: CGFloat) -> CGMutablePath {
        let x0 = (winW - w) / 2, x1 = x0 + w, y = H - h
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

    func setExpanded(_ open: Bool) {
        expanded = open
        let spring = CASpringAnimation(keyPath: "path")
        spring.fromValue = island.presentation()?.path ?? island.path // smooth even when interrupted mid-animation
        spring.toValue = open ? expandedPath : collapsedPath
        spring.mass = 1
        spring.stiffness = open ? 170 : 260
        spring.damping = open ? 16 : 26 // open: slight bounce; close: snappy, no overshoot
        spring.duration = spring.settlingDuration
        island.path = open ? expandedPath : collapsedPath
        island.add(spring, forKey: "morph")

        panel.ignoresMouseEvents = !open // collapsed: clicks fall through to the menu bar
        DispatchQueue.main.asyncAfter(deadline: .now() + (open ? 0.15 : 0)) { [self] in
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = open ? 0.3 : 0.12
                stage.animator().alphaValue = expanded ? 1 : 0
            }
        }
    }

    func renderText() {
        let r = renderScript(model.currentText, fontSize: CGFloat(model.settings.fontSize))
        let y = scroll.contentView.bounds.origin.y
        tv.textStorage!.setAttributedString(r.text)
        model.locale = speechLocale(for: r.text.string, picked: model.current?.language)
        model.tokens = tokenize(r.text.string, locale: model.locale, skipping: r.cues)
        model.cursor = min(model.cursor, max(0, model.tokens.count - 1))
        tv.layoutManager!.ensureLayout(for: tv.textContainer!)
        scrollTo(min(y, maxY))
    }

    var maxY: CGFloat { max(0, tv.frame.height - scroll.contentView.bounds.height) }

    func scrollTo(_ y: CGFloat) {
        scroll.contentView.scroll(to: NSPoint(x: 0, y: y))
        scroll.reflectScrolledClipView(scroll.contentView)
    }

    func scrollToStart() { scrollTo(textHeight - readingInset) }

    /// Scroll position that puts the line holding `range` right under the notch.
    func targetY(for range: NSRange) -> CGFloat {
        let lm = tv.layoutManager!
        let g = lm.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        return lm.lineFragmentRect(forGlyphAt: g.location, effectiveRange: nil).minY + tv.textContainerOrigin.y - readingInset
    }

    /// The word just before the line on top, so voice mode picks up where you are.
    func tokenIndexAtTop() -> Int {
        let y = scroll.contentView.bounds.origin.y + readingInset - tv.textContainerOrigin.y
        let c = tv.layoutManager!.characterIndex(for: NSPoint(x: 0, y: max(0, y)), in: tv.textContainer!, fractionOfDistanceBetweenInsertionPoints: nil)
        return max(0, (model.tokens.firstIndex { $0.range.location >= c } ?? model.tokens.count) - 1)
    }

    @objc func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = lastTick == 0 ? 0 : min(0.1, now - lastTick)
        lastTick = now

        // Open while reading, while hovered (with a short grace period), or always if hover mode is off.
        let mouse = NSEvent.mouseLocation
        if (expanded ? panel.frame.insetBy(dx: 0, dy: -4) : hoverZone).contains(mouse) { lastHover = max(lastHover, now) }
        let s = model.settings
        let want = s.showOnNotch && (!s.hoverToOpen || model.isRunning || now - lastHover < 1.2)
        if want != expanded { setExpanded(want) }

        if model.countdown != shownCount {
            shownCount = model.countdown
            countLabel.stringValue = shownCount.map(String.init) ?? ""
            countLabel.isHidden = shownCount == nil
            scroll.alphaValue = shownCount == nil ? 1 : 0.15
            let pop = CABasicAnimation(keyPath: "opacity")
            pop.fromValue = 0
            pop.duration = 0.25
            countLabel.layer?.add(pop, forKey: "pop")
        }

        let y = scroll.contentView.bounds.origin.y
        if model.voice {
            // Glide toward the line you're reading instead of jumping (~200ms ease-out).
            if let t = model.voiceTarget, abs(t - y) > 0.25 { scrollTo(y + (t - y) * (1 - exp(-dt * 8))) }
        } else if !model.paused && model.countdown == nil {
            if y < maxY { scrollTo(min(maxY, y + CGFloat(s.speed) * dt)) } else { model.paused = true }
        }
    }
}

let notch = Notch()
