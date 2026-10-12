import AVFoundation
import NaturalLanguage
import Speech

/// The speech locale for a script's language, so a Portuguese script works on an English Mac.
func speechLocale(for text: String) -> Locale {
    guard let lang = NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue else { return .current }
    if Locale.current.language.languageCode?.identifier == lang { return .current }
    let locales = SFSpeechRecognizer.supportedLocales().filter { $0.language.languageCode?.identifier == lang }
    return locales.first { $0.region == Locale.current.region } ?? locales.min { $0.identifier < $1.identifier } ?? .current
}

/// Microphone + on-device speech recognition. Moves `model.voiceTarget` to the line you're reading.
final class Listener {
    let engine = AVAudioEngine()
    var task: SFSpeechRecognitionTask?

    func start() {
        AVCaptureDevice.requestAccess(for: .audio) { mic in
            SFSpeechRecognizer.requestAuthorization { speech in
                DispatchQueue.main.async {
                    if !mic {
                        self.fail("Cadence can't hear you. Allow microphone access in System Settings > Privacy & Security > Microphone.")
                    } else if speech != .authorized {
                        self.fail("Cadence can't recognize speech. Allow it in System Settings > Privacy & Security > Speech Recognition.")
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
            return fail("Speech recognition isn't available for this script's language. Check your internet connection or try another language.")
        }
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = rec.supportsOnDeviceRecognition // private, and no 1-minute cap
        req.contextualStrings = Array(Set(model.tokens.map(\.word)).prefix(100))
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buf, _ in req.append(buf) }
        engine.prepare()
        do { try engine.start() } catch { return fail("The microphone didn't start: \(error.localizedDescription)") }
        model.listening = true

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
        let words = tokenize(transcript, locale: model.locale).map(\.word)
        guard let i = locate(heard: words, in: model.tokens.map(\.word), from: model.cursor) else { return }
        model.cursor = i
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
