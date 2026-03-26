import SwiftUI
import Speech
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [MatchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    @Published var selectedLanguage: AppLanguage = .english
    @Published var showSettings = false
    @Published var showPaywall = false
    @Published var isSpeechAvailable = false
    @Published var isRecording = false

    let storeService = StoreService()
    let speechService = SpeechService()
    private var speechCancellable: AnyCancellable?

    init() {
        loadSettings()
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isSpeechAvailable = (status == .authorized)
            }
        }
    }

    func toggleRecording() {
        if isRecording {
            speechService.stopRecording()
            isRecording = false
            speechCancellable?.cancel()
            speechCancellable = nil
        } else {
            Task {
                // Start recording (handles auth automatically)
                let started = await speechService.startRecording(language: selectedLanguage.code)
                if started {
                    isRecording = true
                    // Live update query with transcription
                    speechCancellable = speechService.$transcribedText
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] text in
                            if !text.isEmpty {
                                self?.query = text
                            }
                        }
                } else if let speechError = speechService.errorMessage {
                    // Show error (e.g. language not supported for voice)
                    errorMessage = speechError
                }
            }
        }
    }

    func search() async {
        let description = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard description.count >= 10 else {
            errorMessage = "Please write a bit more!"
            return
        }
        if !storeService.canSearch {
            showPaywall = true
            return
        }

        // Stop recording if active
        if isRecording {
            speechService.stopRecording()
            isRecording = false
            speechCancellable?.cancel()
            speechCancellable = nil
        }

        isLoading = true
        errorMessage = nil
        results = []
        hasSearched = false

        do {
            let response = try await BackendService.search(
                description: description,
                language: selectedLanguage.code,
                isPaid: storeService.isPro
            )
            results = response.matches.map { m in
                MatchResult(
                    title: m.title,
                    year: m.year,
                    type: m.type,
                    confidence: m.confidence,
                    explanation: m.explanation,
                    posterURL: m.posterUrl.flatMap { URL(string: $0) },
                    backdropURL: m.backdropUrl.flatMap { URL(string: $0) },
                    overview: m.overview,
                    rating: m.rating,
                    tmdbTitle: m.tmdbTitle
                )
            }
            hasSearched = true
            storeService.recordSearch()
        } catch let error as BackendError {
            if case .dailyLimitReached = error {
                showPaywall = true
            }
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectExample(_ pill: String) { query = pill }

    func loadSettings() {
        if let code = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let lang = AppLanguage.all.first(where: { $0.code == code }) {
            selectedLanguage = lang
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(selectedLanguage.code, forKey: "selectedLanguage")
    }
}
