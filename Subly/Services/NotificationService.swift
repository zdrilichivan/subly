//
//  NotificationService.swift
//  SublySwift
//
//  Servizio per la gestione delle notifiche push locali
//

import Foundation
import UserNotifications
import Combine
import OSLog
import SwiftUI

class NotificationService: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = NotificationService()

    // MARK: - Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.ivanzdrilich.SublySwift", category: "NotificationService")

    @Published var isAuthorized = false
    @Published var pendingNotificationsCount = 0

    // Subscription per cui mostrare la domanda "Stai utilizzando?"
    @Published var subscriptionToCheck: SubscriptionCheckInfo?

    // Callback per aprire la pagina di cancellazione
    var onOpenCancellationPage: ((String) -> Void)?

    // MARK: - Subscription Check Info
    struct SubscriptionCheckInfo: Identifiable, Equatable {
        let id: String
        let name: String
        let serviceName: String
        let cost: String
    }

    // MARK: - Notification Categories
    private let usageCheckCategory = "USAGE_CHECK"
    private let actionUsedYes = "USED_YES"
    private let actionUsedNo = "USED_NO"
    private let actionCancel = "CANCEL_SUB"

    // MARK: - Init
    private override init() {
        super.init()
        setupNotificationCategories()
        checkAuthorizationStatus()
        notificationCenter.delegate = self
    }

    // MARK: - Setup Categories

    private func setupNotificationCategories() {
        // Azione: Sì, l'ho usato
        let usedYesAction = UNNotificationAction(
            identifier: actionUsedYes,
            title: "✅ Sì, l'ho usato",
            options: []
        )

        // Azione: No, non l'ho usato
        let usedNoAction = UNNotificationAction(
            identifier: actionUsedNo,
            title: "❌ No",
            options: [.foreground]
        )

        // Azione: Cancella abbonamento
        let cancelAction = UNNotificationAction(
            identifier: actionCancel,
            title: "🗑️ Cancella abbonamento",
            options: [.foreground, .destructive]
        )

        // Categoria per il check di utilizzo
        let usageCategory = UNNotificationCategory(
            identifier: usageCheckCategory,
            actions: [usedYesAction, usedNoAction, cancelAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([usageCategory])
        logger.info("✅ Notification categories registered")
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            if granted {
                logger.info("✅ Notification authorization granted")
            } else {
                logger.warning("⚠️ Notification authorization denied")
            }
            return granted
        } catch {
            logger.error("❌ Error requesting notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule Notifications for Subscription

    func scheduleNotifications(for subscription: Subscription) async {
        guard isAuthorized else {
            logger.warning("⚠️ Notifications not authorized, skipping schedule")
            return
        }

        // Cancel existing notifications for this subscription
        await cancelNotifications(for: subscription)

        // Schedule new notifications
        for daysBefore in Constants.Notifications.daysBefore {
            await scheduleNotification(for: subscription, daysBefore: daysBefore)
        }

        await updatePendingCount()
        logger.info("✅ Scheduled notifications for: \(subscription.displayName)")
    }

    private func scheduleNotification(for subscription: Subscription, daysBefore: Int) async {
        let calendar = Calendar.current
        guard let notificationDate = calendar.date(
            byAdding: .day,
            value: -daysBefore,
            to: subscription.nextBillingDate
        ) else { return }

        // Set time to 17:30
        var components = calendar.dateComponents([.year, .month, .day], from: notificationDate)
        components.hour = Constants.Notifications.defaultHour
        components.minute = Constants.Notifications.defaultMinute

        guard let triggerDate = calendar.date(from: components) else { return }

        // Don't schedule if date is in the past
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        // Messaggi motivazionali per far riflettere l'utente
        switch daysBefore {
        case 0:
            content.title = "📅 \(subscription.displayName) si rinnova oggi"
            content.body = "\(subscription.cost.currencyFormatted) verrà addebitato. Hai ancora bisogno di questo servizio?"
        case 1:
            content.title = "⚠️ Rinnovo domani"
            content.body = "\(subscription.displayName) (\(subscription.cost.currencyFormatted)) - Ultima chance per ripensarci!"
        case 3:
            // Notifica interattiva: porta nell'app per chiedere se usa il servizio
            content.title = "🤔 Stai utilizzando \(subscription.displayName)?"
            content.body = "Si rinnova tra 3 giorni (\(subscription.cost.currencyFormatted)). Tocca per rispondere."
            content.userInfo = [
                "subscriptionId": subscription.id.uuidString,
                "subscriptionName": subscription.displayName,
                "serviceName": subscription.serviceName,
                "cost": subscription.cost.currencyFormatted,
                "type": "usage_check_3days"
            ]
        default:
            content.title = "🔔 Rinnovo tra \(daysBefore) giorni"
            content.body = "\(subscription.displayName) - \(subscription.cost.currencyFormatted)"
        }

        // Usa TimeInterval invece di Calendar per evitare l'icona calendario
        let timeInterval = triggerDate.timeIntervalSinceNow
        guard timeInterval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        let identifier = notificationIdentifier(for: subscription, daysBefore: daysBefore)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            logger.info("📅 Scheduled notification for \(subscription.displayName) at \(triggerDate.shortFormatted)")
        } catch {
            logger.error("❌ Error scheduling notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Cancel Notifications

    func cancelNotifications(for subscription: Subscription) async {
        let identifiers = Constants.Notifications.daysBefore.map { daysBefore in
            notificationIdentifier(for: subscription, daysBefore: daysBefore)
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        await updatePendingCount()
        logger.info("🗑️ Cancelled notifications for: \(subscription.displayName)")
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        Task {
            await updatePendingCount()
        }
        logger.info("🗑️ Cancelled all notifications")
    }

    // MARK: - Reschedule All

    func rescheduleAllNotifications(for subscriptions: [Subscription]) async {
        // Cancel all existing
        notificationCenter.removeAllPendingNotificationRequests()

        // Schedule for each active subscription
        for subscription in subscriptions where subscription.isActive {
            await scheduleNotifications(for: subscription)
        }

        await updatePendingCount()
        logger.info("🔄 Rescheduled all notifications for \(subscriptions.filter { $0.isActive }.count) subscriptions")
    }

    // MARK: - Budget Alert

    func scheduleBudgetAlert(currentSpending: Double, budgetLimit: Double) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Attenzione Budget"
        content.body = "Hai raggiunto il \(Int((currentSpending / budgetLimit) * 100))% del tuo budget mensile (\(currentSpending.currencyFormatted) di \(budgetLimit.currencyFormatted))"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "budget-alert", content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            logger.info("⚠️ Budget alert scheduled")
        } catch {
            logger.error("❌ Error scheduling budget alert: \(error.localizedDescription)")
        }
    }

    // MARK: - Pending Notifications

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    private func updatePendingCount() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        await MainActor.run {
            self.pendingNotificationsCount = pending.count
        }
    }

    // MARK: - Usage Check Notifications (Domande provocatorie)

    /// Schedula notifiche settimanali per chiedere all'utente se ha usato i servizi
    func scheduleUsageCheckNotifications(for subscriptions: [Subscription]) async {
        guard isAuthorized else { return }

        // Rimuovi notifiche di usage check esistenti
        let pending = await notificationCenter.pendingNotificationRequests()
        let usageCheckIds = pending.filter { $0.identifier.hasPrefix("usage-check-") }.map { $0.identifier }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: usageCheckIds)

        // Filtra solo abbonamenti attivi e non essenziali
        let eligibleSubscriptions = subscriptions.filter { $0.isActive && !$0.isEssential }

        guard !eligibleSubscriptions.isEmpty else { return }

        // Schedula una notifica per ogni abbonamento, distribuite durante la settimana
        for (index, subscription) in eligibleSubscriptions.enumerated() {
            await scheduleUsageCheckNotification(for: subscription, dayOffset: index % 7)
        }

        logger.info("📊 Scheduled \(eligibleSubscriptions.count) usage check notifications")
    }

    private func scheduleUsageCheckNotification(for subscription: Subscription, dayOffset: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "🤔 Hai usato \(subscription.displayName)?"
        content.body = "Questa settimana hai utilizzato questo servizio da \(subscription.cost.currencyFormatted)/\(subscription.billingCycle.shortName)?"
        content.sound = .default
        content.categoryIdentifier = usageCheckCategory
        content.userInfo = [
            "subscriptionId": subscription.id.uuidString,
            "subscriptionName": subscription.displayName,
            "serviceName": subscription.serviceName
        ]

        // Schedula per un giorno specifico della settimana, alle 20:00
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        dateComponents.weekday = (dayOffset % 7) + 1 // 1 = Domenica, 2 = Lunedì, etc.

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let identifier = "usage-check-\(subscription.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            logger.info("📊 Scheduled usage check for \(subscription.displayName)")
        } catch {
            logger.error("❌ Error scheduling usage check: \(error.localizedDescription)")
        }
    }

    /// Notifica immediata per testare
    func sendTestUsageCheckNotification(for subscription: Subscription) async {
        let content = UNMutableNotificationContent()
        content.title = "🤔 Hai usato \(subscription.displayName)?"
        content.body = "Questa settimana hai utilizzato questo servizio da \(subscription.cost.currencyFormatted)\(subscription.billingCycle.shortName)?"
        content.sound = .default
        content.categoryIdentifier = usageCheckCategory
        content.userInfo = [
            "subscriptionId": subscription.id.uuidString,
            "subscriptionName": subscription.displayName,
            "serviceName": subscription.serviceName
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "test-usage-\(subscription.id.uuidString)", content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            logger.info("🧪 Test usage check notification sent for \(subscription.displayName)")
        } catch {
            logger.error("❌ Error sending test notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Track Usage Responses

    /// Salva che l'utente ha detto di non usare un servizio
    func markAsNotUsed(subscriptionId: String) {
        var notUsedList = getNotUsedSubscriptions()
        if !notUsedList.contains(subscriptionId) {
            notUsedList.append(subscriptionId)
            UserDefaults.standard.set(notUsedList, forKey: "notUsedSubscriptions")
            logger.info("📝 Marked subscription as not used: \(subscriptionId)")
        }
    }

    /// Salva che l'utente ha detto di usare un servizio
    func markAsUsed(subscriptionId: String) {
        var notUsedList = getNotUsedSubscriptions()
        notUsedList.removeAll { $0 == subscriptionId }
        UserDefaults.standard.set(notUsedList, forKey: "notUsedSubscriptions")
        logger.info("✅ Marked subscription as used: \(subscriptionId)")
    }

    /// Ottiene la lista degli abbonamenti che l'utente ha detto di non usare
    func getNotUsedSubscriptions() -> [String] {
        UserDefaults.standard.stringArray(forKey: "notUsedSubscriptions") ?? []
    }

    /// Conta quante volte l'utente ha detto di non usare un servizio
    func getNotUsedCount(for subscriptionId: String) -> Int {
        let key = "notUsedCount-\(subscriptionId)"
        return UserDefaults.standard.integer(forKey: key)
    }

    func incrementNotUsedCount(for subscriptionId: String) {
        let key = "notUsedCount-\(subscriptionId)"
        let currentCount = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(currentCount + 1, forKey: key)
    }

    // MARK: - Helpers

    private func notificationIdentifier(for subscription: Subscription, daysBefore: Int) -> String {
        "\(subscription.id.uuidString)-\(daysBefore)"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let subscriptionId = userInfo["subscriptionId"] as? String ?? ""
        let subscriptionName = userInfo["subscriptionName"] as? String ?? ""
        let serviceName = userInfo["serviceName"] as? String ?? ""

        // Controlla se è una notifica "usage check 3 giorni"
        let notificationType = userInfo["type"] as? String
        let cost = userInfo["cost"] as? String ?? ""

        switch response.actionIdentifier {
        case actionUsedYes:
            // L'utente ha detto che usa il servizio
            markAsUsed(subscriptionId: subscriptionId)
            logger.info("👍 User confirmed using: \(subscriptionName)")

        case actionUsedNo:
            // L'utente ha detto che NON usa il servizio
            markAsNotUsed(subscriptionId: subscriptionId)
            incrementNotUsedCount(for: subscriptionId)

            let notUsedCount = getNotUsedCount(for: subscriptionId)
            logger.info("👎 User said NOT using: \(subscriptionName) (count: \(notUsedCount))")

            // Se l'utente dice "no" più volte, suggerisci la cancellazione
            if notUsedCount >= 2 {
                Task {
                    await sendCancellationSuggestion(subscriptionName: subscriptionName, serviceName: serviceName)
                }
            }

        case actionCancel:
            // L'utente vuole cancellare - apri la pagina di cancellazione
            logger.info("🗑️ User wants to cancel: \(subscriptionName)")
            DispatchQueue.main.async {
                self.onOpenCancellationPage?(serviceName)
            }

        case UNNotificationDefaultActionIdentifier:
            // Tap sulla notifica (senza azione specifica)
            // Se è la notifica a 3 giorni, mostra lo sheet nell'app
            if notificationType == "usage_check_3days" {
                logger.info("📱 Opening usage check for: \(subscriptionName)")
                DispatchQueue.main.async {
                    self.subscriptionToCheck = SubscriptionCheckInfo(
                        id: subscriptionId,
                        name: subscriptionName,
                        serviceName: serviceName,
                        cost: cost
                    )
                }
            }

        default:
            break
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mostra la notifica anche se l'app è in foreground
        completionHandler([.banner, .sound, .badge])
    }

    private func sendCancellationSuggestion(subscriptionName: String, serviceName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "💡 Forse è il momento di cancellare?"
        content.body = "Hai detto più volte di non usare \(subscriptionName). Vuoi che ti aiutiamo a cancellarlo?"
        content.sound = .default
        content.categoryIdentifier = usageCheckCategory
        content.userInfo = [
            "subscriptionId": "",
            "subscriptionName": subscriptionName,
            "serviceName": serviceName
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "cancel-suggestion-\(serviceName)", content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            logger.error("❌ Error sending cancellation suggestion: \(error.localizedDescription)")
        }
    }
}
