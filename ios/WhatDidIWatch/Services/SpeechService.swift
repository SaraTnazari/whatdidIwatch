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

    // Fallback: record audio file for server-side transcription (Whisper)
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private var isUsingWhisperFallback = false
    private var fallbackLanguage = ""

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

    /// Check if a language is supported by Apple's on-device speech recognition
    private func isAppleSpeechAvailable(for code: String) -> Bool {
        let locale = speechLocale(for: code)
        let testRecognizer = SFSpeechRecognizer(locale: locale)
        if testRecognizer?.isAvailable == true {
            return true
        }
        // Also check language family
        let supported = SFSpeechRecognizer.supportedLocales()
        let langPrefix = String(code.prefix(2))
        return supported.contains(where: {
            $0.identifier.hasPrefix(langPrefix) && SFSpeechRecognizer(locale: $0)?.isAvailable == true
        })
    }

    func startRecording(language: String = "en") async -> Bool {
        // Clear previous state
        errorMessage = nil
        transcribedText = ""
        isUsingWhisperFallback = false

        // Need microphone permission
        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else {
            errorMessage = "Microphone permission denied. Please enable it in Settings > Privacy > Microphone."
            return false
        }

        stopRecording()

        // Decide: Apple speech recognition or Whisper fallback?
        if isAppleSpeechAvailable(for: language) {
            return await startAppleSpeechRecording(language: language)
        } else {
            print("[Speech] Apple speech not available for \(language), using Whisper fallback")
            return startWhisperRecording(language: language)
        }
    }

    // MARK: - Apple Speech Recognition (for supported languages)

    private func startAppleSpeechRecording(language: String) async -> Bool {
        // Request speech authorization
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted {
                errorMessage = "Speech recognition permission denied. Please enable it in Settings > Privacy > Speech Recognition."
                return false
            }
        }

        let locale = speechLocale(for: language)
        recognizer = SFSpeechRecognizer(locale: locale)

        // Try language family fallback
        if recognizer == nil || recognizer?.isAvailable != true {
            let supported = SFSpeechRecognizer.supportedLocales()
            let langPrefix = String(language.prefix(2))
            if let altLocale = supported.first(where: { $0.identifier.hasPrefix(langPrefix) }) {
                recognizer = SFSpeechRecognizer(locale: altLocale)
            }
        }

        guard let recognizer = recognizer, recognizer.isAvailable else {
            // This shouldn't happen since we checked isAppleSpeechAvailable, but just in case
            return startWhisperRecording(language: language)
        }

        print("[Speech] Using Apple recognizer with locale: \(recognizer.locale.identifier)")

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

        if #available(iOS 15, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        recognitionRequest.taskHint = .dictation

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
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
            print("[Speech] Audio engine error: \(error)")
            errorMessage = "Could not start audio recording."
            return false
        }
    }

    // MARK: - Whisper Fallback (for unsupported languages like Farsi, Arabic)

    private func startWhisperRecording(language: String) -> Bool {
        isUsingWhisperFallback = true
        fallbackLanguage = language

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[Speech] Audio session error: \(error)")
            errorMessage = "Could not start audio recording."
            return false
        }

        // Create temp file for recording
        let tempDir = FileManager.default.temporaryDirectory
        audioFileURL = tempDir.appendingPathComponent("voice_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFileURL!, settings: settings)
            audioRecorder?.record()
            isRecording = true
            print("[Speech] Whisper fallback recording started for language: \(language)")
            return true
        } catch {
            print("[Speech] Recorder error: \(error)")
            errorMessage = "Could not start audio recording."
            return false
        }
    }

    func stopRecording() {
        if isUsingWhisperFallback {
            stopWhisperRecording()
        } else {
            stopAppleSpeechRecording()
        }
    }

    private func stopAppleSpeechRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    private func stopWhisperRecording() {
        audioRecorder?.stop()
        isRecording = false

        guard let fileURL = audioFileURL else { return }

        // Send audio to backend for transcription
        let language = fallbackLanguage
        Task {
            await transcribeWithWhisper(fileURL: fileURL, language: language)
            // Clean up temp file
            try? FileManager.default.removeItem(at: fileURL)
        }

        audioRecorder = nil
        isUsingWhisperFallback = false
    }

    /// Send recorded audio to the backend's Whisper transcription endpoint
    private func transcribeWithWhisper(fileURL: URL, language: String) async {
        let url = URL(string: "\(BackendService.baseURL)/api/transcribe")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(BackendService.apiSecret, forHTTPHeaderField: "X-API-Secret")
        request.timeoutInterval = 30

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add language field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(language)\r\n".data(using: .utf8)!)

        // Add audio file
        if let audioData = try? Data(contentsOf: fileURL) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("[Speech] Whisper transcription failed")
                errorMessage = "Could not transcribe audio. Please try again."
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["text"] as? String, !text.isEmpty {
                transcribedText = text
                print("[Speech] Whisper transcription: \(text)")
            } else {
                errorMessage = "No speech detected. Please try again."
            }
        } catch {
            print("[Speech] Whisper request error: \(error)")
            errorMessage = "Could not connect to transcription service."
        }
    }
}
