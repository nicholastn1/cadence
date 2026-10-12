import AppKit

enum Palette {
    static let script = NSColor(srgbRed: 0.949, green: 0.949, blue: 0.933, alpha: 1) // paper white, easier on the eyes than #FFF
    static let tally = NSColor(srgbRed: 1, green: 0.255, blue: 0.212, alpha: 1)      // on-air light: live mic, cue marks
    static let marker = NSColor(srgbRed: 1, green: 0.788, blue: 0.290, alpha: 1)     // highlighter
}

/// Script markup: **stress**, ==highlight==, [cue]. Cues are notes to yourself: shown, never matched against speech.
let markupPattern = try! NSRegularExpression(pattern: #"\*\*([^*\n]+)\*\*|==([^=\n]+)==|\[([^\]\n]+)\]"#)

/// The script as it appears on the notch, with the ranges of cue marks.
func renderScript(_ source: String, fontSize: CGFloat) -> (text: NSAttributedString, cues: [NSRange]) {
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineHeightMultiple = 1.06
    let base: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold), .foregroundColor: Palette.script, .paragraphStyle: para,
    ]
    let ns = source as NSString
    let out = NSMutableAttributedString()
    var cues: [NSRange] = []
    var last = 0
    for m in markupPattern.matches(in: source, range: NSRange(location: 0, length: ns.length)) {
        out.append(NSAttributedString(string: ns.substring(with: NSRange(location: last, length: m.range.location - last)), attributes: base))
        var a = base
        if m.range(at: 1).location != NSNotFound {
            a[.font] = NSFont.systemFont(ofSize: fontSize, weight: .black)
            out.append(NSAttributedString(string: ns.substring(with: m.range(at: 1)), attributes: a))
        } else if m.range(at: 2).location != NSNotFound {
            a[.foregroundColor] = Palette.marker
            out.append(NSAttributedString(string: ns.substring(with: m.range(at: 2)), attributes: a))
        } else {
            a[.foregroundColor] = Palette.tally
            a[.font] = NSFont.systemFont(ofSize: fontSize * 0.72, weight: .bold)
            let start = out.length
            out.append(NSAttributedString(string: "[" + ns.substring(with: m.range(at: 3)) + "]", attributes: a))
            cues.append(NSRange(location: start, length: out.length - start))
        }
        last = NSMaxRange(m.range)
    }
    out.append(NSAttributedString(string: ns.substring(from: last), attributes: base))
    return (out, cues)
}

let editorFont = NSFont(descriptor: NSFont.systemFont(ofSize: 17).fontDescriptor.withDesign(.serif)!, size: 17)!

/// Live styling in the editor: markup characters stay visible but recede.
func styleEditor(_ ts: NSTextStorage) {
    let full = NSRange(location: 0, length: ts.length)
    let para = NSMutableParagraphStyle()
    para.lineHeightMultiple = 1.3
    para.paragraphSpacing = 2
    ts.beginEditing()
    ts.setAttributes([.font: editorFont, .foregroundColor: NSColor.labelColor, .paragraphStyle: para], range: full)
    for m in markupPattern.matches(in: ts.string, range: full) {
        let edge: Int
        if m.range(at: 1).location != NSNotFound {
            ts.addAttribute(.font, value: NSFontManager.shared.convert(editorFont, toHaveTrait: .boldFontMask), range: m.range(at: 1))
            edge = 2
        } else if m.range(at: 2).location != NSNotFound {
            ts.addAttribute(.backgroundColor, value: Palette.marker.withAlphaComponent(0.38), range: m.range(at: 2))
            edge = 2
        } else {
            ts.addAttribute(.foregroundColor, value: Palette.tally, range: m.range)
            edge = 1
        }
        for r in [NSRange(location: m.range.location, length: edge), NSRange(location: NSMaxRange(m.range) - edge, length: edge)] {
            ts.addAttribute(.foregroundColor, value: NSColor.tertiaryLabelColor, range: r)
        }
    }
    ts.endEditing()
}
