import Foundation
import UIKit

/// Handles all communication with your backend server.
/// This replaces direct Claude/TMDB API calls so users don't need their own keys.
class BackendService {
    // MARK: - Configuration
    // Change this to your deployed backend URL
    static var baseURL = "https://whatdidiwatch.onrender.com"
    static var apiSecret = "C8BgiXWm-cTWCXsj1WBwL6GQ4YEpf8zSCvgjPiSzR_s"

    /// Unique device identifier (persists across app launches)
    static var deviceID: String {
        if let existing = UserDefaults.standard.string(forKey: "deviceID") {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: "deviceID")
        return new
    }

    // MARK: - Search

    static func search(description: String, language: String, isPaid: Bool) async throws -> SearchResponse {
        let body: [String: Any] = [
            "description": description,
            "language": language,
            "device_id": deviceID,
            "is_paid": isPaid,
        ]

        var request = URLRequest(url: URL(string: "\(baseURL)/api/search")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiSecret, forHTTPHeaderField: "X-API-Secret")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            // Check if it's a rate limit
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let limitReached = json["limit_reached"] as? Bool, limitReached {
                throw BackendError.dailyLimitReached
            }
            throw BackendError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? String {
                throw BackendError.serverMessage(error)
            }
            throw BackendError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(SearchResponse.self, from: data)
    }
}

// MARK: - Response Models

struct SearchResponse: Codable {
    let matches: [BackendMatch]
    let remainingSearches: Int?
}

struct BackendMatch: Codable {
    let title: String
    let year: Int?
    let type: String
    let confidence: String
    let explanation: String
    let searchQuery: String?
    let posterUrl: String?
    let backdropUrl: String?
    let overview: String?
    let rating: Double?
    let tmdbTitle: String?
    let watchLinks: WatchLinksResponse?
}

struct WatchLinksResponse: Codable {
    let justwatch: String?
    let amazon: String?
    let appleTV: String?
    let youtube: String?
    let google: String?

    enum CodingKeys: String, CodingKey {
        case justwatch, amazon, youtube, google
        case appleTV = "apple_tv"
    }
}

enum BackendError: LocalizedError {
    case invalidResponse
    case rateLimited
    case dailyLimitReached
    case serverError(Int)
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server."
        case .rateLimited: return "Service is busy. Please try again in a moment."
        case .dailyLimitReached: return "You've used all your free searches today. Upgrade to Pro for unlimited searches!"
        case .serverError(let code): return "Server error (\(code)). Please try again."
        case .serverMessage(let msg): return msg
        }
    }
}
