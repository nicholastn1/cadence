import AVFoundation
import QuartzCore
import NaturalLanguage
import Speech

/// The speech locale for a script: the one picked for it, else its detected language,
/// so a Portuguese script works on an English Mac.
func speechLocale(for text: String, picked: String? = nil) -> Locale {
    if let picked { return Locale(identifier: picked) }
    guard let lang = NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue else { return .current }
    if Locale.current.language.languageCode?.identifier == lang { return .current }
    let locales = SFSpeechRecognizer.supportedLocales().filter { $0.language.languageCode?.identifier == lang }
    return locales.first { $0.region == Locale.current.region } ?? locales.min { $0.identifier < $1.identifier } ?? .current
}

/// Every language Cadence can listen for, by display name. On-device ones work offline.
let speechLanguages: [(id: String, name: String, onDevice: Bool)] = SFSpeechRecognizer.supportedLocales()
    .map { ($0.identifier, Locale.current.localizedString(forIdentifier: $0.identifier) ?? $0.identifier,
            SFSpeechRecognizer(locale: $0)?.supportsOnDeviceRecognition ?? false) }
    .sorted { $0.1.localizedStandardCompare($1.1) == .orderedAscending }

/// Microphone + on-device speech recognition. Moves `model.voiceTarget` to the line you're reading.
final class Listener {
    let engine = AVAudioEngine()
    var task: SFSpeechRecognitionTask?
    var heardCount = 0      // words in the current task's transcript
    var unmatched = 0       // words heard since the last match; 6+ means you're off script
    var online = false      // on-device recognition failed on this Mac; use Apple's servers
    var quickFails = 0      // tasks in a row that errored right away without hearing anything

    func start() {
        online = false
        quickFails = 0
        requestAccess()
    }

    func requestAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { mic in
            SFSpeechRecognizer.requestAuthorization { speech in
                DispatchQueue.main.async {
                    if !mic {
                        self.fail(String(localized: "Cadence can't hear you. Allow microphone access in System Settings > Privacy & Security > Microphone."))
                    } else if speech != .authorized {
                        self.fail(String(localized: "Cadence can't recognize speech. Allow it in System Settings > Privacy & Security > Speech Recognition."))
                    } else {
                        self.run()
                    }
                }
            }
        }
    }

    func run() {
        guard model.voice else { return }
        guard let rec = SFSpeechRecognizer(locale: model.locale) ?? SFSpeechRecognizer(), rec.isAvailable else {
            return fail(String(localized: "Speech recognition isn't available for this script's language. Check your internet connection or try another language."))
        }
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = rec.supportsOnDeviceRecognition && !online // private, and no 1-minute cap
        req.contextualStrings = Array(Set(model.tokens.map(\.word)).prefix(100))
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buf, _ in req.append(buf) }
        engine.prepare()
        do { try engine.start() } catch { return fail(String(localized: "The microphone didn't start: \(error.localizedDescription)")) }
        model.listening = true
        model.onDevice = req.requiresOnDeviceRecognition
        heardCount = 0

        let began = CACurrentMediaTime()
        var me: SFSpeechRecognitionTask?
        me = rec.recognitionTask(with: req) { result, error in
            DispatchQueue.main.async {
                guard self.task === me else { return } // stale callback from a previous task
                if let result { self.quickFails = 0; self.heard(result.bestTranscription.formattedString) }
                // Recognition tasks end on long silences; quietly start a fresh one.
                if error != nil || result?.isFinal == true {
                    self.stop()
                    // An error within a second or two, before hearing anything, is a broken recognizer, not silence.
                    // Restarting it would loop forever and flicker the mic indicator.
                    if let error, self.heardCount == 0, CACurrentMediaTime() - began < 2 {
                        self.quickFails += 1
                        // ponytail: falls back to online instead of downloading the on-device model (AssetInventory) first
                        if req.requiresOnDeviceRecognition { self.online = true }
                        else if self.quickFails >= 3 {
                            return self.fail(String(localized: "Speech recognition isn't working on this Mac: \(error.localizedDescription)"))
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { if model.voice { self.run() } }
                }
            }
        }
        task = me
    }

    func heard(_ transcript: String) {
        let words = tokenize(transcript, locale: model.locale).map(\.word)
        let fresh = max(0, words.count - heardCount)
        heardCount = words.count
        guard let i = locate(heard: words, in: model.tokens.map(\.word), from: model.cursor, strict: model.offScript) else {
            unmatched += fresh
            if unmatched >= 6 { model.offScript = true } // talking to someone: hold still until you're back on script
            return
        }
        unmatched = 0
        model.offScript = false
        if i > model.cursor || model.take.isEmpty { model.take.append((CACurrentMediaTime(), i)) }
        model.cursor = i
        notch.markProgress()
        model.voiceTarget = notch.targetY(for: model.tokens[i].range)
    }

    func stop() {
        task?.cancel()
        task = nil
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
    }

    func fail(_ message: String) {
        model.voice = false
        model.voiceError = message
    }
}

let listener = Listener()
