//
//  StoreManager.swift
//  Subly
//
//  Gestione abbonamenti in-app con StoreKit 2
//

import Foundation
import StoreKit
import Combine
import UIKit

enum SubscriptionPlan: String, CaseIterable {
    case weekly = "com.ivanzdrilich.Subly.pro.weekly"
    case annual = "com.ivanzdrilich.Subly.pro.annual"

    var displayName: String {
        switch self {
        case .weekly: return String(localized: "Settimanale")
        case .annual: return String(localized: "Annuale")
        }
    }
}

@MainActor
class StoreManager: ObservableObject {

    // MARK: - Singleton
    static let shared = StoreManager()

    // MARK: - Product IDs
    static let weeklyProductID = SubscriptionPlan.weekly.rawValue
    static let annualProductID = SubscriptionPlan.annual.rawValue
    static let allProductIDs = [weeklyProductID, annualProductID]

    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var selectedPlan: SubscriptionPlan = .weekly
    @Published var freeTrialEnabled: Bool = true

    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Computed Properties

    var weeklyProduct: Product? {
        products.first { $0.id == StoreManager.weeklyProductID }
    }

    var annualProduct: Product? {
        products.first { $0.id == StoreManager.annualProductID }
    }

    var selectedProduct: Product? {
        switch selectedPlan {
        case .weekly: return weeklyProduct
        case .annual: return annualProduct
        }
    }

    var weeklyPrice: String {
        weeklyProduct?.displayPrice ?? "€2,99"
    }

    var annualPrice: String {
        annualProduct?.displayPrice ?? "€39,99"
    }

    /// Prezzo annuale se pagato settimanalmente (€2.99 × 52 = €155.48)
    var annualPriceIfWeekly: String {
        if let product = weeklyProduct {
            let yearly = product.price * 52
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceFormatStyle.locale
            return formatter.string(from: yearly as NSDecimalNumber) ?? "€155,48"
        }
        return "€155,48"
    }

    /// Equivalente settimanale del piano annuale (€39.99 / 52 = €0.77)
    var annualWeeklyEquivalent: String {
        if let product = annualProduct {
            let weekly = product.price / 52
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceFormatStyle.locale
            return formatter.string(from: weekly as NSDecimalNumber) ?? "€0,77"
        }
        return "€0,77"
    }

    var savingsPercentage: Int {
        // €2,99 * 52 = €155,48 annuale se pagato settimanalmente
        // €39,99 annuale = risparmio di €115,49 = ~74%
        return 74
    }

    /// Controlla se l'utente è idoneo per la prova gratuita
    var isEligibleForTrial: Bool {
        guard let product = selectedProduct else { return false }
        return product.subscription?.introductoryOffer != nil
    }

    /// Durata della prova gratuita in giorni
    var trialDays: Int {
        guard let product = selectedProduct,
              let intro = product.subscription?.introductoryOffer else { return 0 }
        // P3D = 3 giorni, P1W = 7 giorni
        switch intro.period.unit {
        case .day:
            return intro.period.value
        case .week:
            return intro.period.value * 7
        case .month:
            return intro.period.value * 30
        case .year:
            return intro.period.value * 365
        @unknown default:
            return intro.period.value
        }
    }

    // MARK: - Init
    private init() {
        // Carica stato salvato
        isPro = UserDefaults.standard.bool(forKey: "isSublyPro")

        // Avvia listener per aggiornamenti transazioni
        updateListenerTask = listenForTransactions()

        // Carica prodotti e verifica stato
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let storeProducts = try await Product.products(for: StoreManager.allProductIDs)
            // Ordina: annuale prima, settimanale dopo
            products = storeProducts.sorted { $0.price > $1.price }
            print("✅ StoreKit: Loaded \(products.count) subscription products")
        } catch {
            print("❌ StoreKit: Failed to load products: \(error)")
            errorMessage = "Impossibile caricare i prodotti"
        }

        isLoading = false
    }

    // MARK: - Purchase

    func purchase() async -> Bool {
        guard let product = selectedProduct else {
            errorMessage = "Prodotto non disponibile"
            return false
        }

        return await purchase(product: product)
    }

    func purchase(product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Aggiorna stato Pro
                await updatePurchasedProducts()

                // Completa transazione
                await transaction.finish()

                print("✅ StoreKit: Subscription purchase successful")
                isLoading = false
                return true

            case .userCancelled:
                print("ℹ️ StoreKit: User cancelled purchase")
                isLoading = false
                return false

            case .pending:
                print("ℹ️ StoreKit: Purchase pending")
                errorMessage = "Acquisto in attesa di approvazione"
                isLoading = false
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            print("❌ StoreKit: Purchase failed: \(error)")
            errorMessage = "Acquisto non riuscito"
            isLoading = false
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()

            if isPro {
                print("✅ StoreKit: Purchases restored successfully")
            } else {
                errorMessage = "Nessun abbonamento attivo trovato"
            }
        } catch {
            print("❌ StoreKit: Restore failed: \(error)")
            errorMessage = "Ripristino non riuscito"
        }

        isLoading = false
    }

    // MARK: - Update Purchased Products

    func updatePurchasedProducts() async {
        var hasPro = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Controlla se è uno dei nostri abbonamenti Pro
                if StoreManager.allProductIDs.contains(transaction.productID) {
                    // Verifica che l'abbonamento non sia scaduto o revocato
                    if transaction.revocationDate == nil {
                        hasPro = true
                    }
                }
            } catch {
                print("❌ StoreKit: Transaction verification failed")
            }
        }

        // Aggiorna stato
        isPro = hasPro
        UserDefaults.standard.set(hasPro, forKey: "isSublyPro")

        print("📱 StoreKit: isPro = \(isPro)")
    }

    // MARK: - Manage Subscription

    func showManageSubscriptions() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("❌ StoreKit: Failed to show manage subscriptions: \(error)")
            }
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }

                do {
                    let transaction = try self.verifyTransaction(result)

                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("❌ StoreKit: Transaction update failed verification")
                }
            }
        }
    }

    // Versione nonisolated per il Task.detached
    nonisolated private func verifyTransaction(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Verification Helper

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Store Error

enum StoreError: Error {
    case failedVerification
}
