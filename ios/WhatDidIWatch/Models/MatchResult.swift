import Foundation

struct MatchResult: Identifiable {
    let id = UUID()
    var title: String
    var year: Int?
    var type: String          // "movie", "tv", "cartoon", "anime"
    var confidence: String    // "high", "medium", "low"
    var explanation: String
    var posterURL: URL?
    var backdropURL: URL?
    var overview: String?
    var rating: Double?
    var tmdbTitle: String?

    var typeEmoji: String {
        switch type {
        case "movie": return "🎥"
        case "tv": return "📺"
        case "cartoon": return "🖍️"
        case "anime": return "⛩️"
        default: return "🎬"
        }
    }

    var confidenceColor: (r: Double, g: Double, b: Double) {
        switch confidence {
        case "high": return (0.133, 0.773, 0.369)
        case "medium": return (0.918, 0.702, 0.031)
        default: return (0.937, 0.267, 0.267)
        }
    }

    struct WatchLinks {
        let justwatch: URL?
        let amazon: URL?
        let appleTV: URL?
        let youtube: URL?
        let google: URL?

        static func build(title: String, year: Int?) -> WatchLinks {
            let q = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
            let qYear = year != nil ? "\(title) \(year!)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q : q
            return WatchLinks(
                justwatch: URL(string: "https://www.justwatch.com/us/search?q=\(q)"),
                amazon: URL(string: "https://www.amazon.com/s?k=\(qYear)&i=instant-video&tag=whatdidiwatch-20"),
                appleTV: URL(string: "https://tv.apple.com/search?term=\(q)"),
                youtube: URL(string: "https://www.youtube.com/results?search_query=\(qYear)+trailer"),
                google: URL(string: "https://www.google.com/search?q=watch+\(qYear)+online")
            )
        }
    }
}
