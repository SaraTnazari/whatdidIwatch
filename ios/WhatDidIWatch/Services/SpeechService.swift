import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechService: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false
    @Published var errorMessage: String?

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in
                    let authorized = (status == .authorized)
                    self?.isAuthorized = authorized
                    continuation.resume(returning: authorized)
                }
            }
        }
    }

    /// Map short language codes to full locale identifiers for SFSpeechRecognizer
    private func speechLocale(for code: String) -> Locale {
        let mapping: [String: String] = [
            "en": "en-US",
            "es": "es-ES",
            "fr": "fr-FR",
            "de": "de-DE",
            "pt": "pt-BR",
            "it": "it-IT",
            "ru": "ru-RU",
            "ar": "ar-SA",
            "fa": "fa-IR",
            "hi": "hi-IN",
            "zh": "zh-CN",
            "ja": "ja-JP",
            "ko": "ko-KR",
            "tr": "tr-TR",
            "id": "id-ID",
            "th": "th-TH",
            "vi": "vi-VN",
            "pl": "pl-PL",
            "nl": "nl-NL",
            "sv": "sv-SE",
        ]
        let localeId = mapping[code] ?? "\(code)-\(code.uppercased())"
        return Locale(identifier: localeId)
    }

    /// Check if a language is supported by SFSpeechRecognizer on this device
    func isLanguageSupported(_ code: String) -> Bool {
        let locale = speechLocale(for: code)
        let supported = SFSpeechRecognizer.supportedLocales()

        // Check exact match first
        if supported.contains(where: { $0.identifier == locale.identifier }) {
            return true
        }

        // Check language family match (e.g., "fa" matches "fa-IR" or "fa_IR")
        let langPrefix = String(code.prefix(2))
        return supported.contains(where: { $0.identifier.hasPrefix(langPrefix) })
    }

    func startRecording(language: String = "en") async -> Bool {
        // Clear any previous error
        errorMessage = nil

        // Request authorization if not already authorized
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted {
                errorMessage = "Speech recognition permission denied. Please enable it in Settings > Privacy > Speech Recognition."
                return false
            }
        }

        // Also need microphone permission
        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else {
            errorMessage = "Microphone permission denied. Please enable it in Settings > Privacy > Microphone."
            return false
        }

        stopRecording()

        // Reset transcribed text for the new session
        transcribedText = ""

        // Find the best recognizer for the requested language
        let locale = speechLocale(for: language)
        let supported = SFSpeechRecognizer.supportedLocales()
        let langPrefix = String(language.prefix(2))

        // Try exact locale first
        recognizer = SFSpeechRecognizer(locale: locale)

        // If exact locale isn't available, try any locale in the same language family
        if recognizer == nil || recognizer?.isAvailable != true {
            print("[Speech] Exact locale \(locale.identifier) not available, searching alternatives...")
            if let altLocale = supported.first(where: { $0.identifier.hasPrefix(langPrefix) }) {
                print("[Speech] Trying alternative locale: \(altLocale.identifier)")
                recognizer = SFSpeechRecognizer(locale: altLocale)
            }
        }

        // Final check — do NOT fall back to English
        guard let recognizer = recognizer, recognizer.isAvailable else {
            let langName = Locale.current.localizedString(forLanguageCode: language) ?? language
            print("[Speech] No recognizer available for \(language)")
            errorMessage = "Voice input for \(langName) is not available on this device. Try using the keyboard's dictation (🎙️ on keyboard) instead."
            return false
        }

        print("[Speech] Using recognizer with locale: \(recognizer.locale.identifier) for requested language: \(language)")

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[Speech] Audio session error: \(error)")
            errorMessage = "Could not start audio recording."
            return false
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return false }
        recognitionRequest.shouldReportPartialResults = true

        // Allow server-side recognition — on-device models may not be
        // downloaded for all languages (especially Farsi, Arabic).
        // Server-side recognition supports more languages reliably.
        if #available(iOS 15, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }

        // Add task hint for better recognition
        recognitionRequest.taskHint = .dictation

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
                if let error = error {
                    print("[Speech] Recognition error: \(error.localizedDescription)")
                }
                if error != nil || (result?.isFinal ?? false) {
                    self?.stopRecording()
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            return true
        } catch {
            print("[Speech] Audio engine error: \(error)")
            errorMessage = "Could not start audio recording."
            return false
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}
