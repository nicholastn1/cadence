// Renders assets/icon.png (the source for assets/AppIcon.icns): swift icon.swift assets/icon.png
// Concept: lines of script whose lengths trace a voice wave, hanging from the notch's red on-air dot.
import AppKit

let S: CGFloat = 1024
let tally = NSColor(srgbRed: 1, green: 0.255, blue: 0.212, alpha: 1)
let paper = NSColor(srgbRed: 0.949, green: 0.949, blue: 0.933, alpha: 1)

func bar(_ cx: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: NSColor) {
    c.setFill()
    NSBezierPath(roundedRect: NSRect(x: cx - w / 2, y: y - h / 2, width: w, height: h), xRadius: h / 2, yRadius: h / 2).fill()
}

let img = NSImage(size: NSSize(width: S, height: S), flipped: false) { _ in
    // macOS icon grid: 824pt squircle, 100pt margin.
    let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    tile.addClip()
    NSGradient(starting: NSColor(srgbRed: 0.13, green: 0.13, blue: 0.15, alpha: 1),
               ending: NSColor(srgbRed: 0.04, green: 0.04, blue: 0.05, alpha: 1))!.draw(in: tile, angle: -90)

    // The notch, flush with the top edge, flared like the hardware.
    let w: CGFloat = 300, top: CGFloat = 924, bottom: CGFloat = 790, r: CGFloat = 60, t: CGFloat = 36
    let x0 = (S - w) / 2, x1 = x0 + w
    let notch = NSBezierPath()
    notch.move(to: NSPoint(x: x0 - t, y: top))
    notch.curve(to: NSPoint(x: x0, y: top - t), controlPoint1: NSPoint(x: x0 - t / 3, y: top), controlPoint2: NSPoint(x: x0, y: top - t / 3))
    notch.line(to: NSPoint(x: x0, y: bottom + r))
    notch.appendArc(withCenter: NSPoint(x: x0 + r, y: bottom + r), radius: r, startAngle: 180, endAngle: 270)
    notch.line(to: NSPoint(x: x1 - r, y: bottom))
    notch.appendArc(withCenter: NSPoint(x: x1 - r, y: bottom + r), radius: r, startAngle: 270, endAngle: 360)
    notch.line(to: NSPoint(x: x1, y: top - t))
    notch.curve(to: NSPoint(x: x1 + t, y: top), controlPoint1: NSPoint(x: x1, y: top - t / 3), controlPoint2: NSPoint(x: x1 + t / 3, y: top))
    notch.close()
    NSColor.black.setFill()
    notch.fill()
    tally.setFill()
    NSBezierPath(ovalIn: NSRect(x: 512 - 18, y: 846 - 18, width: 36, height: 36)).fill() // on-air camera

    // Script lines as a waveform: the line being read is brightest, the rest recede.
    for (i, lw) in ([260, 420, 600, 360, 520, 240] as [CGFloat]).enumerated() {
        bar(512, 690 - CGFloat(i) * 92, lw, 44, paper.withAlphaComponent(i == 0 ? 1 : max(0.25, 1 - CGFloat(i) * 0.14)))
    }
    return true
}
let rep = NSBitmapImageRep(cgImage: img.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "icon.png"))
