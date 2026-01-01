//
//  StoreManager.swift
//  Subly
//
//  Gestione acquisti in-app con StoreKit 2
//

import Foundation
import StoreKit
import Combine

@MainActor
class StoreManager: ObservableObject {

    // MARK: - Singleton
    static let shared = StoreManager()

    // MARK: - Product IDs
    static let proProductID = "com.ivanzdrilich.Subly.pro"

    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?

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
            let storeProducts = try await Product.products(for: [StoreManager.proProductID])
            products = storeProducts
            print("✅ StoreKit: Loaded \(products.count) products")
        } catch {
            print("❌ StoreKit: Failed to load products: \(error)")
            errorMessage = "Impossibile caricare i prodotti"
        }

        isLoading = false
    }

    // MARK: - Purchase

    func purchase() async -> Bool {
        guard let product = products.first else {
            errorMessage = "Prodotto non disponibile"
            return false
        }

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

                print("✅ StoreKit: Purchase successful")
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
                errorMessage = "Nessun acquisto da ripristinare"
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

                if transaction.productID == StoreManager.proProductID {
                    hasPro = true
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

    // MARK: - Formatted Price

    var formattedPrice: String {
        if let product = products.first {
            return product.displayPrice
        }
        // Fallback localizzato
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: 4.99) ?? "€4,99"
    }
}

// MARK: - Store Error

enum StoreError: Error {
    case failedVerification
}
