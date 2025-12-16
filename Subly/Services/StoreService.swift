//
//  StoreService.swift
//  Subly
//
//  Gestione acquisti in-app con StoreKit 2
//

import Foundation
import StoreKit
import Combine
import OSLog

@MainActor
class StoreService: ObservableObject {

    // MARK: - Singleton
    static let shared = StoreService()

    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ivanzdrilich.SublySwift", category: "StoreService")

    // Product ID per l'acquisto
    static let unlimitedProductID = "com.ivanzdrilich.subly.unlimited"

    // Limite abbonamenti gratuiti
    static let freeLimit = 4

    @Published var isUnlocked: Bool = false
    @Published var product: Product?
    @Published var isPurchasing: Bool = false
    @Published var errorMessage: String?

    // MARK: - Init

    private init() {
        // Controlla se già sbloccato (cache locale)
        isUnlocked = UserDefaults.standard.bool(forKey: "isAppUnlocked")

        Task {
            await loadProduct()
            await checkPurchaseStatus()
        }
    }

    // MARK: - Load Product

    func loadProduct() async {
        do {
            logger.info("🔄 Loading product: \(StoreService.unlimitedProductID)")
            let products = try await Product.products(for: [StoreService.unlimitedProductID])
            if let product = products.first {
                self.product = product
                logger.info("✅ Product loaded: \(product.displayName) - \(product.displayPrice)")
            } else {
                logger.warning("⚠️ No products found for ID: \(StoreService.unlimitedProductID)")
                errorMessage = "Prodotto non ancora disponibile. Riprova tra qualche ora."
            }
        } catch {
            logger.error("❌ Error loading products: \(error.localizedDescription)")
            errorMessage = "Errore caricamento: \(error.localizedDescription)"
        }
    }

    // MARK: - Check Purchase Status

    func checkPurchaseStatus() async {
        // Verifica gli acquisti esistenti
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == StoreService.unlimitedProductID {
                    isUnlocked = true
                    UserDefaults.standard.set(true, forKey: "isAppUnlocked")
                    logger.info("✅ App already unlocked")
                    return
                }
            }
        }
    }

    // MARK: - Purchase

    func purchase() async -> Bool {
        guard let product = product else {
            errorMessage = "Prodotto non disponibile"
            return false
        }

        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Acquisto verificato!
                    isUnlocked = true
                    UserDefaults.standard.set(true, forKey: "isAppUnlocked")
                    await transaction.finish()
                    logger.info("✅ Purchase successful!")
                    isPurchasing = false
                    return true

                case .unverified(_, let error):
                    errorMessage = "Acquisto non verificato: \(error.localizedDescription)"
                    logger.error("❌ Unverified purchase: \(error.localizedDescription)")
                }

            case .userCancelled:
                logger.info("ℹ️ User cancelled purchase")

            case .pending:
                errorMessage = "Acquisto in attesa di approvazione"
                logger.info("⏳ Purchase pending")

            @unknown default:
                errorMessage = "Errore sconosciuto"
            }
        } catch {
            errorMessage = "Errore: \(error.localizedDescription)"
            logger.error("❌ Purchase error: \(error.localizedDescription)")
        }

        isPurchasing = false
        return false
    }

    // MARK: - Restore Purchases

    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await checkPurchaseStatus()

            if isUnlocked {
                logger.info("✅ Purchases restored successfully")
                return true
            } else {
                errorMessage = "Nessun acquisto da ripristinare"
                return false
            }
        } catch {
            errorMessage = "Errore nel ripristino: \(error.localizedDescription)"
            logger.error("❌ Restore error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Check if can add subscription

    func canAddSubscription(currentCount: Int) -> Bool {
        return isUnlocked || currentCount < StoreService.freeLimit
    }
}
