//
//  BudgetService.swift
//  SublySwift
//
//  Servizio per la gestione del budget
//

import Foundation
import Combine
import OSLog

class BudgetService: ObservableObject {

    // MARK: - Singleton
    static let shared = BudgetService()

    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let logger = Logger(subsystem: "com.ivanzdrilich.SublySwift", category: "BudgetService")

    @Published var settings: BudgetSettings {
        didSet {
            saveSettings()
        }
    }

    // MARK: - Init
    private init() {
        if let data = userDefaults.data(forKey: Constants.UserDefaults.budgetSettings),
           let decoded = try? JSONDecoder().decode(BudgetSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = BudgetSettings()
        }
    }

    // MARK: - Save Settings

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: Constants.UserDefaults.budgetSettings)
            logger.info("✅ Budget settings saved")
        }
    }

    // MARK: - Budget Calculations

    /// Calcola la spesa mensile totale dagli abbonamenti attivi
    func calculateMonthlySpending(from subscriptions: [Subscription]) -> Double {
        subscriptions
            .filter { $0.isActive }
            .reduce(0) { $0 + $1.monthlyCost }
    }

    /// Calcola lo stato del budget
    func getBudgetStatus(from subscriptions: [Subscription]) -> BudgetStatus? {
        guard settings.isEnabled, let limit = settings.monthlyLimit, limit > 0 else {
            return nil
        }

        let current = calculateMonthlySpending(from: subscriptions)
        return BudgetStatus(limit: limit, current: current)
    }

    /// Verifica se è necessario inviare un alert del budget
    func shouldSendBudgetAlert(from subscriptions: [Subscription]) -> Bool {
        guard let status = getBudgetStatus(from: subscriptions) else {
            return false
        }

        return status.percentage >= settings.notifyAtPercentage
    }

    /// Calcola l'impatto di un nuovo abbonamento sul budget
    func calculateBudgetImpact(
        currentSubscriptions: [Subscription],
        newCost: Double,
        newBillingCycle: BillingCycle
    ) -> BudgetImpact? {
        guard settings.isEnabled, let limit = settings.monthlyLimit, limit > 0 else {
            return nil
        }

        let currentSpending = calculateMonthlySpending(from: currentSubscriptions)

        // Convert new cost to monthly
        let newMonthlyCost: Double
        switch newBillingCycle {
        case .weekly:
            newMonthlyCost = newCost * 4.33
        case .monthly:
            newMonthlyCost = newCost
        case .yearly:
            newMonthlyCost = newCost / 12
        }

        let newTotal = currentSpending + newMonthlyCost
        let newPercentage = (newTotal / limit) * 100
        let willExceedBudget = newTotal > limit

        return BudgetImpact(
            currentSpending: currentSpending,
            newMonthlyCost: newMonthlyCost,
            newTotal: newTotal,
            budgetLimit: limit,
            newPercentage: newPercentage,
            willExceedBudget: willExceedBudget
        )
    }

    // MARK: - Update Settings

    func updateBudgetLimit(_ limit: Double?) {
        settings.monthlyLimit = limit
        settings.isEnabled = limit != nil && limit! > 0
    }

    func updateNotifyPercentage(_ percentage: Double) {
        settings.notifyAtPercentage = min(max(percentage, 50), 100)
    }

    func enableBudget(_ enabled: Bool) {
        settings.isEnabled = enabled
    }

    // MARK: - Category Analysis

    /// Calcola la spesa per categoria
    func spendingByCategory(from subscriptions: [Subscription]) -> [ServiceCategory: Double] {
        var result: [ServiceCategory: Double] = [:]

        for subscription in subscriptions where subscription.isActive {
            result[subscription.category, default: 0] += subscription.monthlyCost
        }

        return result
    }

    /// Trova abbonamenti costosi (sopra una soglia)
    func expensiveSubscriptions(from subscriptions: [Subscription], threshold: Double = 20) -> [Subscription] {
        subscriptions
            .filter { $0.isActive && $0.monthlyCost >= threshold }
            .sorted { $0.monthlyCost > $1.monthlyCost }
    }

    /// Suggerimenti di risparmio
    func savingSuggestions(from subscriptions: [Subscription]) -> [SavingSuggestion] {
        var suggestions: [SavingSuggestion] = []

        // Abbonamenti costosi
        let expensive = expensiveSubscriptions(from: subscriptions, threshold: 30)
        for sub in expensive.prefix(3) {
            suggestions.append(SavingSuggestion(
                type: .expensive,
                subscription: sub,
                message: "\(sub.displayName) costa \(sub.monthlyCost.currencyFormatted)/mese - considera se è necessario"
            ))
        }

        // Categorie con spesa elevata
        let byCategory = spendingByCategory(from: subscriptions)
        for (category, spending) in byCategory where spending > 50 {
            suggestions.append(SavingSuggestion(
                type: .categoryHigh,
                category: category,
                message: "Spendi \(spending.currencyFormatted)/mese in \(category.displayName)"
            ))
        }

        return suggestions
    }
}

// MARK: - Budget Impact Model

struct BudgetImpact {
    let currentSpending: Double
    let newMonthlyCost: Double
    let newTotal: Double
    let budgetLimit: Double
    let newPercentage: Double
    let willExceedBudget: Bool

    var impactText: String {
        if willExceedBudget {
            let exceeds = newTotal - budgetLimit
            return "Supererai il budget di \(exceeds.currencyFormatted)"
        } else {
            let remaining = budgetLimit - newTotal
            return "Rimarranno \(remaining.currencyFormatted)"
        }
    }
}

// MARK: - Saving Suggestion Model

struct SavingSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    var subscription: Subscription?
    var category: ServiceCategory?
    let message: String

    enum SuggestionType {
        case expensive
        case categoryHigh
        case unused
    }
}
