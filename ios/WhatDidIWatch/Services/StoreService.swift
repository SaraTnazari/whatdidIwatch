import Foundation
import StoreKit

@MainActor
class StoreService: ObservableObject {
    // MARK: - Product IDs (configure these in App Store Connect)
    static let proLifetimeID = "com.saranazari.WhatDidIWatch.proLifetime"

    // MARK: - Published state
    @Published var products: [Product] = []
    @Published var isPro = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Track daily free usage
    @Published var freeSearchesUsedToday: Int = 0
    static let freeDailyLimit = 3

    var remainingFreeSearches: Int {
        max(0, StoreService.freeDailyLimit - freeSearchesUsedToday)
    }

    var canSearch: Bool {
        isPro || remainingFreeSearches > 0
    }

    /// Alias for compatibility with SettingsView
    var isPremiumUser: Bool { isPro }

    private var transactionListener: Task<Void, Never>?

    init() {
        loadLocalState()
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [StoreService.proLifetimeID])
            products = storeProducts
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchasePro() async {
        guard let product = products.first(where: { $0.id == StoreService.proLifetimeID }) else {
            errorMessage = "Product not available. Please try again later."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                isPro = true
                savePurchaseState()
                await transaction.finish()

            case .userCancelled:
                break

            case .pending:
                errorMessage = "Purchase is pending approval."

            @unknown default:
                errorMessage = "Unknown purchase result."
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        var found = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == StoreService.proLifetimeID {
                    isPro = true
                    savePurchaseState()
                    found = true
                }
            }
        }

        if !found {
            errorMessage = "No previous purchases found."
        }

        isLoading = false
    }

    // MARK: - Track Free Usage

    func recordSearch() {
        if !isPro {
            freeSearchesUsedToday += 1
            saveFreeUsage()
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    if transaction.productID == StoreService.proLifetimeID {
                        await MainActor.run {
                            self?.isPro = true
                            self?.savePurchaseState()
                        }
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }

    // MARK: - Local Persistence

    private func savePurchaseState() {
        UserDefaults.standard.set(isPro, forKey: "isPro")
    }

    private func saveFreeUsage() {
        let today = dateString()
        UserDefaults.standard.set(freeSearchesUsedToday, forKey: "freeSearches_\(today)")
        UserDefaults.standard.set(today, forKey: "freeSearchesDate")
    }

    private func loadLocalState() {
        isPro = UserDefaults.standard.bool(forKey: "isPro")

        let today = dateString()
        let savedDate = UserDefaults.standard.string(forKey: "freeSearchesDate") ?? ""
        if savedDate == today {
            freeSearchesUsedToday = UserDefaults.standard.integer(forKey: "freeSearches_\(today)")
        } else {
            freeSearchesUsedToday = 0
        }
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
