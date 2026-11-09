import Foundation
import Observation
import StoreKit

/// Dear Muse membership tiers — aligned with Dear Home StoreKit 2 matrix.
enum DearMuseTier: String, CaseIterable, Identifiable, Sendable {
    case max = "Max"
    case pro = "Pro"
    case free = "Free"

    var id: String { rawValue }

    var rank: Int {
        switch self {
        case .free: return 0
        case .pro: return 1
        case .max: return 2
        }
    }
}

@MainActor
@Observable
final class StoreKitManager {
    static let maxMonthlyID = "com.s2.dearmuse.max.monthly"
    static let maxYearlyID = "com.s2.dearmuse.max.yearly"
    static let proMonthlyID = "com.s2.dearmuse.pro.monthly"
    static let proYearlyID = "com.s2.dearmuse.pro.yearly"

    static let coreProductIDs = [maxMonthlyID, proMonthlyID]
    static let allProductIDs = [maxMonthlyID, proMonthlyID, maxYearlyID, proYearlyID]

    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    var products: [Product] = []
    var activeTier: DearMuseTier = .free
    var loadState: LoadState = .idle
    var isPurchasing = false
    var purchaseError: Bilingual?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        startListening()
    }

    deinit {
        updatesTask?.cancel()
    }

    var maxMonthly: Product? { product(id: Self.maxMonthlyID) }
    var proMonthly: Product? { product(id: Self.proMonthlyID) }

    func product(id: String) -> Product? {
        products.first { $0.id == id }
    }

    func product(for tier: DearMuseTier) -> Product? {
        switch tier {
        case .max: return maxMonthly ?? product(id: Self.maxYearlyID)
        case .pro: return proMonthly ?? product(id: Self.proYearlyID)
        case .free: return nil
        }
    }

    func loadProducts() async {
        if case .ready = loadState { return }
        loadState = .loading
        purchaseError = nil
        do {
            let loaded = try await Product.products(for: Self.allProductIDs)
            products = loaded.sorted { tier(for: $0.id).rank > tier(for: $1.id).rank }
            loadState = .ready
            await refreshEntitlements()
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func purchase(_ product: Product) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = Bilingual(
                en: error.localizedDescription,
                zh: "购买失败：\(error.localizedDescription)"
            )
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseError = Bilingual(
                en: error.localizedDescription,
                zh: "恢复购买失败：\(error.localizedDescription)"
            )
        }
    }

    func refreshEntitlements() async {
        var highest = DearMuseTier.free
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            let t = tier(for: transaction.productID)
            if t.rank > highest.rank { highest = t }
        }
        activeTier = highest
    }

    private func startListening() {
        updatesTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func tier(for productID: String) -> DearMuseTier {
        if productID.contains(".max.") { return .max }
        if productID.contains(".pro.") { return .pro }
        return .free
    }

    enum StoreError: Error {
        case failedVerification
    }
}
