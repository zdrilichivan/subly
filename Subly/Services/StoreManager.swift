//
//  StoreManager.swift
//  Subly
//
//  Gestione abbonamenti in-app con StoreKit 2
//

import Foundation
import StoreKit
import Combine

enum SubscriptionPlan: String, CaseIterable {
    case monthly = "com.ivanzdrilich.Subly.pro.monthly"
    case annual = "com.ivanzdrilich.Subly.pro.annual"

    var displayName: String {
        switch self {
        case .monthly: return String(localized: "Mensile")
        case .annual: return String(localized: "Annuale")
        }
    }
}

@MainActor
class StoreManager: ObservableObject {

    // MARK: - Singleton
    static let shared = StoreManager()

    // MARK: - Product IDs
    static let monthlyProductID = SubscriptionPlan.monthly.rawValue
    static let annualProductID = SubscriptionPlan.annual.rawValue
    static let allProductIDs = [monthlyProductID, annualProductID]

    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var selectedPlan: SubscriptionPlan = .annual

    // MARK: - Debug
    #if DEBUG
    @Published var debugProEnabled: Bool = false {
        didSet {
            isPro = debugProEnabled
            UserDefaults.standard.set(debugProEnabled, forKey: "debugProEnabled")
        }
    }
    #endif

    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Computed Properties

    var monthlyProduct: Product? {
        products.first { $0.id == StoreManager.monthlyProductID }
    }

    var annualProduct: Product? {
        products.first { $0.id == StoreManager.annualProductID }
    }

    var selectedProduct: Product? {
        switch selectedPlan {
        case .monthly: return monthlyProduct
        case .annual: return annualProduct
        }
    }

    var monthlyPrice: String {
        monthlyProduct?.displayPrice ?? "€1,99"
    }

    var annualPrice: String {
        annualProduct?.displayPrice ?? "€19,99"
    }

    var annualMonthlyEquivalent: String {
        if let product = annualProduct {
            let monthly = product.price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceFormatStyle.locale
            return formatter.string(from: monthly as NSDecimalNumber) ?? "€1,67"
        }
        return "€1,67"
    }

    var savingsPercentage: Int {
        // €1,99 * 12 = €23,88 annuale se pagato mensilmente
        // €19,99 annuale = risparmio di €3,89 = ~16%
        return 16
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
        // P1W = 7 giorni
        return intro.period.value * (intro.period.unit == .week ? 7 : 1)
    }

    // MARK: - Init
    private init() {
        // Carica stato salvato
        isPro = UserDefaults.standard.bool(forKey: "isSublyPro")

        #if DEBUG
        // In debug, controlla se Pro è abilitato manualmente
        let debugPro = UserDefaults.standard.bool(forKey: "debugProEnabled")
        debugProEnabled = debugPro
        if debugPro {
            isPro = true
        }
        #endif

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
            // Ordina: annuale prima, mensile dopo
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
