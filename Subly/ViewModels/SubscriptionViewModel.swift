//
//  SubscriptionViewModel.swift
//  SublySwift
//
//  ViewModel principale per la gestione degli abbonamenti
//

import Foundation
import Combine
import UIKit
import OSLog

@MainActor
class SubscriptionViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var subscriptions: [Subscription] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var searchText = ""
    @Published var selectedCategory: ServiceCategory?
    @Published var showOnlyActive = true

    // MARK: - Services
    private let cloudKitService = CloudKitService.shared
    private let notificationService = NotificationService.shared
    private let budgetService = BudgetService.shared

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let logger = Logger(subsystem: "com.ivanzdrilich.SublySwift", category: "SubscriptionViewModel")
    private var cancellables = Set<AnyCancellable>()
    private var pendingSyncIDs: Set<UUID> = []

    // MARK: - Computed Properties

    /// Abbonamenti filtrati in base a ricerca e categoria
    var filteredSubscriptions: [Subscription] {
        var result = subscriptions

        // Filtra per stato attivo
        if showOnlyActive {
            result = result.filter { $0.isActive }
        }

        // Filtra per categoria
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Filtra per ricerca
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.displayName.lowercased().contains(query) ||
                $0.category.displayName.lowercased().contains(query)
            }
        }

        return result
    }

    /// Abbonamenti ordinati per data di rinnovo
    var subscriptionsByRenewalDate: [Subscription] {
        filteredSubscriptions.sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    /// Abbonamenti attivi
    var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive }
    }

    /// Totale mensile
    var totalMonthlyCost: Double {
        budgetService.calculateMonthlySpending(from: subscriptions)
    }

    /// Totale annuale
    var totalYearlyCost: Double {
        totalMonthlyCost * 12
    }

    /// Stato del budget
    var budgetStatus: BudgetStatus? {
        budgetService.getBudgetStatus(from: subscriptions)
    }

    /// Abbonamenti con rinnovo imminente (7 giorni)
    var upcomingRenewals: [Subscription] {
        activeSubscriptions
            .filter { $0.isRenewalSoon }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    /// Numero di abbonamenti per categoria
    var subscriptionCountByCategory: [ServiceCategory: Int] {
        Dictionary(grouping: activeSubscriptions, by: { $0.category })
            .mapValues { $0.count }
    }

    /// Spesa per categoria
    var spendingByCategory: [ServiceCategory: Double] {
        budgetService.spendingByCategory(from: subscriptions)
    }

    // MARK: - Init

    init() {
        loadSubscriptions()
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe CloudKit sync status
        cloudKitService.$isSyncing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSyncing)
    }

    // MARK: - Load & Save

    func loadSubscriptions() {
        isLoading = true

        // Load from local cache first
        if let data = userDefaults.data(forKey: Constants.UserDefaults.subscriptions),
           let decoded = try? JSONDecoder().decode([Subscription].self, from: data) {
            self.subscriptions = decoded.sorted { $0.nextBillingDate < $1.nextBillingDate }
            logger.info("✅ Loaded \(decoded.count) subscriptions from cache")
        }

        // Then sync with CloudKit and schedule notifications
        Task {
            await syncWithCloudKit()
            await notificationService.scheduleUsageCheckNotifications(for: subscriptions)
            isLoading = false
        }
    }

    private func saveSubscriptions() {
        if let encoded = try? JSONEncoder().encode(self.subscriptions) {
            userDefaults.set(encoded, forKey: Constants.UserDefaults.subscriptions)
            logger.info("✅ Saved \(self.subscriptions.count) subscriptions to cache")
        }
    }

    // MARK: - CloudKit Sync

    func syncWithCloudKit() async {
        let synced = await cloudKitService.sync(localSubscriptions: subscriptions)

        // Smart merge: preserve pending items
        var merged: [Subscription] = []
        let syncedMap = Dictionary(uniqueKeysWithValues: synced.map { ($0.id, $0) })

        for sub in subscriptions {
            if pendingSyncIDs.contains(sub.id) {
                // Keep local version for pending items
                merged.append(sub)
            } else if let cloudSub = syncedMap[sub.id] {
                merged.append(cloudSub)
            }
        }

        // Add new items from cloud
        for sub in synced where !merged.contains(where: { $0.id == sub.id }) {
            merged.append(sub)
        }

        subscriptions = merged.sorted { $0.nextBillingDate < $1.nextBillingDate }
        saveSubscriptions()

        // Clear pending sync IDs after successful sync
        pendingSyncIDs.removeAll()
    }

    // MARK: - CRUD Operations

    /// Aggiunge un nuovo abbonamento
    func addSubscription(_ subscription: Subscription) async {
        subscriptions.append(subscription)
        subscriptions.sort { $0.nextBillingDate < $1.nextBillingDate }
        saveSubscriptions()

        // Schedule notifications
        await notificationService.scheduleNotifications(for: subscription)

        // Sync with CloudKit
        pendingSyncIDs.insert(subscription.id)
        do {
            try await cloudKitService.saveSubscription(subscription)
            pendingSyncIDs.remove(subscription.id)
        } catch {
            logger.error("❌ Error saving to CloudKit: \(error.localizedDescription)")
        }

        // Check budget alert
        await checkBudgetAlert()

        Haptic.notification(.success)
        logger.info("✅ Added subscription: \(subscription.displayName)")
    }

    /// Aggiorna un abbonamento esistente
    func updateSubscription(_ subscription: Subscription) async {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else {
            return
        }

        var updated = subscription
        updated.updatedAt = Date()

        subscriptions[index] = updated
        subscriptions.sort { $0.nextBillingDate < $1.nextBillingDate }
        saveSubscriptions()

        // Reschedule notifications
        await notificationService.scheduleNotifications(for: updated)

        // Sync with CloudKit
        pendingSyncIDs.insert(updated.id)
        do {
            try await cloudKitService.updateSubscription(updated)
            pendingSyncIDs.remove(updated.id)
        } catch {
            logger.error("❌ Error updating in CloudKit: \(error.localizedDescription)")
        }

        Haptic.notification(.success)
        logger.info("✅ Updated subscription: \(updated.displayName)")
    }

    /// Elimina un abbonamento (soft delete)
    func deleteSubscription(_ subscription: Subscription) async {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else {
            return
        }

        // Cancel notifications
        await notificationService.cancelNotifications(for: subscription)

        // Soft delete: set isActive to false
        subscriptions[index].isActive = false
        subscriptions[index].updatedAt = Date()
        saveSubscriptions()

        // Sync with CloudKit
        do {
            try await cloudKitService.updateSubscription(subscriptions[index])
        } catch {
            logger.error("❌ Error updating in CloudKit: \(error.localizedDescription)")
        }

        Haptic.notification(.success)
        logger.info("✅ Deleted subscription: \(subscription.displayName)")
    }

    /// Elimina permanentemente un abbonamento
    func permanentlyDeleteSubscription(_ subscription: Subscription) async {
        // Cancel notifications
        await notificationService.cancelNotifications(for: subscription)

        // Remove from array
        subscriptions.removeAll { $0.id == subscription.id }
        saveSubscriptions()

        // Delete from CloudKit
        do {
            try await cloudKitService.deleteSubscription(subscription)
        } catch {
            logger.error("❌ Error deleting from CloudKit: \(error.localizedDescription)")
        }

        Haptic.notification(.success)
        logger.info("✅ Permanently deleted subscription: \(subscription.displayName)")
    }

    /// Riattiva un abbonamento cancellato
    func reactivateSubscription(_ subscription: Subscription) async {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else {
            return
        }

        subscriptions[index].isActive = true
        subscriptions[index].updatedAt = Date()
        saveSubscriptions()

        // Reschedule notifications
        await notificationService.scheduleNotifications(for: subscriptions[index])

        // Sync with CloudKit
        do {
            try await cloudKitService.updateSubscription(subscriptions[index])
        } catch {
            logger.error("❌ Error updating in CloudKit: \(error.localizedDescription)")
        }

        Haptic.notification(.success)
        logger.info("✅ Reactivated subscription: \(subscription.displayName)")
    }

    // MARK: - Budget

    func calculateBudgetImpact(newCost: Double, billingCycle: BillingCycle) -> BudgetImpact? {
        budgetService.calculateBudgetImpact(
            currentSubscriptions: subscriptions,
            newCost: newCost,
            newBillingCycle: billingCycle
        )
    }

    private func checkBudgetAlert() async {
        if budgetService.shouldSendBudgetAlert(from: subscriptions) {
            if let status = budgetStatus {
                await notificationService.scheduleBudgetAlert(
                    currentSpending: status.current,
                    budgetLimit: status.limit
                )
            }
        }
    }

    // MARK: - Statistics

    func getSavingSuggestions() -> [SavingSuggestion] {
        budgetService.savingSuggestions(from: subscriptions)
    }

    func getExpensiveSubscriptions(threshold: Double = 20) -> [Subscription] {
        budgetService.expensiveSubscriptions(from: subscriptions, threshold: threshold)
    }

    // MARK: - Utility

    func refreshData() async {
        isLoading = true
        await syncWithCloudKit()
        await notificationService.rescheduleAllNotifications(for: activeSubscriptions)
        await notificationService.scheduleUsageCheckNotifications(for: subscriptions)
        isLoading = false
    }

    func resetAllData() async {
        // Cancel all notifications
        notificationService.cancelAllNotifications()

        // Clear subscriptions
        subscriptions.removeAll()
        saveSubscriptions()

        // Note: CloudKit data will remain but won't be loaded
        // User can delete from iCloud settings if needed

        logger.info("🗑️ All local data reset")
    }
}
