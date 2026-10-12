import Foundation

// Voice matching: pure functions, covered by `Cadence --selftest`.

struct Token: Equatable {
    var word: String
    var range: NSRange // where the word sits in the rendered script
}

/// Lowercased, accent-free words with their ranges. Whole numbers are spelled out
/// ("42" -> "forty two") so they match whichever form speech recognition returns.
func tokenize(_ s: String, locale: Locale = Locale(identifier: "en_US"), skipping skip: [NSRange] = []) -> [Token] {
    var out: [Token] = []
    s.enumerateSubstrings(in: s.startIndex..., options: .byWords) { w, r, _, _ in
        let range = NSRange(r, in: s)
        if skip.contains(where: { NSIntersectionRange($0, range).length > 0 }) { return }
        for part in spellNumber(w!, locale: locale) {
            out.append(Token(word: part.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil), range: range))
        }
    }
    return out
}

// ponytail: whole numbers only; decimals and ordinals stay as typed.
func spellNumber(_ w: String, locale: Locale) -> [String] {
    guard let n = Int(w) else { return [w] }
    let f = NumberFormatter()
    f.numberStyle = .spellOut
    f.locale = locale
    return (f.string(from: NSNumber(value: n)) ?? w).components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
}

/// Same word, or one typo apart for longer words ("recognition" / "recognitions").
func similar(_ a: String, _ b: String) -> Bool {
    if a == b { return true }
    guard min(a.count, b.count) >= 5, abs(a.count - b.count) <= 1 else { return false }
    let a = Array(a), b = Array(b)
    var prev = Array(0...b.count)
    for i in 1...a.count {
        var cur = [i] + Array(repeating: 0, count: b.count)
        for j in 1...b.count {
            cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
        }
        prev = cur
    }
    return prev[b.count] <= 1
}

/// How many of the heard words line up, in order, with the script ending at `i`.
/// Ad-libbed words are skipped; up to two skipped script words are tolerated between matches.
func alignScore(_ tail: [String], _ words: [String], endingAt i: Int) -> Int {
    var k = i, score = 0
    for h in tail.reversed() where k >= 0 {
        if let m = stride(from: k, through: max(0, k - 2), by: -1).first(where: { similar(h, words[$0]) }) {
            score += 1
            k = m - 1
        }
    }
    return score
}

/// A word that can move the script on its own: not a short function word like "the", "and", "de".
/// Non-Latin words carry more meaning per letter, so they need fewer.
func isSubstantial(_ w: String) -> Bool { w.count >= (w.unicodeScalars.allSatisfy(\.isASCII) ? 4 : 2) }

/// Where in the script is the speaker? Returns the index of the last word they said, or nil
/// when the evidence is too weak to move. Small steps forward need little evidence; jumps need more.
/// `strict` (after an off-script stretch) needs three words in a row before moving at all.
func locate(heard: [String], in words: [String], from cursor: Int, strict: Bool = false) -> Int? {
    let tail = Array(heard.suffix(6))
    guard !tail.isEmpty, !words.isEmpty else { return nil }
    let lo = max(0, cursor - 4), hi = min(words.count - 1, cursor + 60)
    guard lo <= hi else { return nil }
    var best: (score: Int, i: Int)?
    for i in lo...hi where tail.suffix(2).contains(where: { similar($0, words[i]) }) {
        let score = alignScore(tail, words, endingAt: i)
        let step = i - cursor
        let needed = strict ? 3 : (0...2).contains(step) ? 1 : (0...8).contains(step) ? 2 : 3
        guard score >= needed, score > 1 || isSubstantial(words[i]) else { continue }
        if score > best?.score ?? 0 || (score == best?.score && abs(step) < abs(best!.i - cursor)) { best = (score, i) }
    }
    return best?.i
}

func runSelfTest() {
    let w = tokenize("Hello there, this is a test. This is only a TÉST!").map(\.word)
    precondition(w.last == "test")                                            // case + accents folded
    precondition(locate(heard: ["hello", "there"], in: w, from: 0) == 1)
    precondition(locate(heard: ["this", "is", "only"], in: w, from: 3) == 8)
    precondition(locate(heard: ["a", "test"], in: w, from: 2) == 5)           // repeated phrase: nearest wins
    precondition(locate(heard: ["a", "test"], in: w, from: 9) == 10)
    precondition(locate(heard: ["test"], in: w, from: 0) == nil)              // lone word far ahead: ignored
    precondition(locate(heard: ["banana"], in: w, from: 0) == nil)

    let n = tokenize("We grew 42 percent").map(\.word)                        // numbers: digits match spoken words
    precondition(n == ["we", "grew", "forty", "two", "percent"])
    precondition(locate(heard: ["grew", "forty", "two", "percent"], in: n, from: 1) == 4)

    let s = tokenize("one two three four five six seven").map(\.word)
    precondition(locate(heard: ["this", "is", "um", "two", "three"], in: s, from: 0) == 2) // ad-libs ignored
    precondition(locate(heard: ["two", "five", "six"], in: s, from: 1) == 5)              // skipped words tolerated
    precondition(similar("recognition", "recognitions") && !similar("cat", "car"))

    let cue = "Say hi [smile] now" as NSString
    let c = tokenize(cue as String, skipping: [cue.range(of: "[smile]")]).map(\.word)
    precondition(c == ["say", "hi", "now"])                                    // cues are never matched
    let d = tokenize("and then the plan was simple").map(\.word)
    precondition(locate(heard: ["and"], in: d, from: 0) == nil)                    // a lone common word can't move it
    precondition(locate(heard: ["plan"], in: d, from: 1) == 3)
    precondition(locate(heard: ["two", "three"], in: s, from: 0, strict: true) == nil) // off script: needs three in a row
    precondition(locate(heard: ["one", "two", "three"], in: s, from: 0, strict: true) == 2)
    precondition(isNewer("0.10.0", than: "0.9.2") && isNewer("1.0", than: "0.9.9") && !isNewer("0.2.0", than: "0.2.0"))
    precondition(isNewer("0.2.0", than: "0.0.0-dev") && !isNewer("0.1.9", than: "0.2"))
    print("selftest ok")
}
