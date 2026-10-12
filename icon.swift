// Renders assets/icon.png (the source for assets/AppIcon.icns): swift icon.swift assets/icon.png
import AppKit

let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S), flipped: false) { _ in
    let ctx = NSGraphicsContext.current!.cgContext
    let white = NSColor.white

    // macOS icon grid: 824pt squircle, 100pt margin.
    let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    tile.addClip()
    NSGradient(starting: NSColor(white: 0.34, alpha: 1), ending: NSColor(white: 0.11, alpha: 1))!.draw(in: tile, angle: -90)

    // The island: notch-shaped, flush with the top, flared corners, like the app's panel.
    let w: CGFloat = 470, top: CGFloat = 924, bottom: CGFloat = 548, r: CGFloat = 96, t: CGFloat = 44
    let x0 = (S - w) / 2, x1 = x0 + w
    let island = NSBezierPath()
    island.move(to: NSPoint(x: x0 - t, y: top))
    island.curve(to: NSPoint(x: x0, y: top - t), controlPoint1: NSPoint(x: x0 - t / 3, y: top), controlPoint2: NSPoint(x: x0, y: top - t / 3))
    island.line(to: NSPoint(x: x0, y: bottom + r))
    island.appendArc(withCenter: NSPoint(x: x0 + r, y: bottom + r), radius: r, startAngle: 180, endAngle: 270)
    island.line(to: NSPoint(x: x1 - r, y: bottom))
    island.appendArc(withCenter: NSPoint(x: x1 - r, y: bottom + r), radius: r, startAngle: 270, endAngle: 360)
    island.line(to: NSPoint(x: x1, y: top - t))
    island.curve(to: NSPoint(x: x1 + t, y: top), controlPoint1: NSPoint(x: x1, y: top - t / 3), controlPoint2: NSPoint(x: x1 + t / 3, y: top))
    island.close()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 40, color: NSColor(white: 0, alpha: 0.6).cgColor)
    NSColor.black.setFill(); island.fill()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // Eye: the camera you look into.
    let cx: CGFloat = 512, cy: CGFloat = 736, ew: CGFloat = 330, eh: CGFloat = 225
    let eye = NSBezierPath()
    eye.move(to: NSPoint(x: cx - ew / 2, y: cy))
    eye.curve(to: NSPoint(x: cx + ew / 2, y: cy), controlPoint1: NSPoint(x: cx - ew / 4, y: cy + eh / 1.5), controlPoint2: NSPoint(x: cx + ew / 4, y: cy + eh / 1.5))
    eye.curve(to: NSPoint(x: cx - ew / 2, y: cy), controlPoint1: NSPoint(x: cx + ew / 4, y: cy - eh / 1.5), controlPoint2: NSPoint(x: cx - ew / 4, y: cy - eh / 1.5))
    white.setFill(); eye.fill()
    NSColor.black.setFill(); NSBezierPath(ovalIn: NSRect(x: cx - 76, y: cy - 76, width: 152, height: 152)).fill()
    white.setFill(); NSBezierPath(ovalIn: NSRect(x: cx - 46, y: cy - 46, width: 92, height: 92)).fill()

    // Voice waveform: the script follows your voice.
    let heights: [CGFloat] = [36, 70, 120, 84, 150, 190, 140, 96, 128, 70, 36]
    let barW: CGFloat = 26, gap: CGFloat = 20, wy: CGFloat = 340
    let total = CGFloat(heights.count) * barW + CGFloat(heights.count - 1) * gap
    for (i, h) in heights.enumerated() {
        let x = cx - total / 2 + CGFloat(i) * (barW + gap)
        NSBezierPath(roundedRect: NSRect(x: x, y: wy - h / 2, width: barW, height: h), xRadius: barW / 2, yRadius: barW / 2).fill()
    }
    return true
}
let rep = NSBitmapImageRep(cgImage: img.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "icon.png"))
