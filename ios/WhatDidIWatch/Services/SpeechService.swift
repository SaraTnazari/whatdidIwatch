import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechService: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false

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

    func startRecording(language: String = "en") async -> Bool {
        // Request authorization if not already authorized
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted {
                return false
            }
        }

        // Also need microphone permission
        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else { return false }

        stopRecording()

        let locale = speechLocale(for: language)
        recognizer = SFSpeechRecognizer(locale: locale)

        // Check if the requested locale is supported on this device.
        // Do NOT silently fall back to the default (English) recognizer —
        // that causes Farsi/Arabic voice input to produce English text.
        if recognizer == nil || recognizer?.isAvailable != true {
            print("Speech recognition not available for locale: \(locale.identifier)")
            // Try supported locales for the same language family
            // e.g. "fa" might work as "fa" on some devices
            let supportedLocales = SFSpeechRecognizer.supportedLocales()
            let langPrefix = language.prefix(2)
            if let fallbackLocale = supportedLocales.first(where: { $0.identifier.hasPrefix(String(langPrefix)) }) {
                recognizer = SFSpeechRecognizer(locale: fallbackLocale)
            }
            guard recognizer?.isAvailable == true else {
                print("No speech recognizer available for language: \(language)")
                return false
            }
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return false
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return false }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
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
            print("Audio engine error: \(error)")
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
