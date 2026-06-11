//
//  LiveActivityService.swift
//  Subly
//
//  Live Activity per i rinnovi imminenti (oggi/domani): banner sulla
//  lock screen e Dynamic Island. La UI vive nel target SublyWidget
//  (RenewalLiveActivity); gli attributi sono duplicati lì in forma
//  identica — se cambi i campi qui, aggiorna anche quella copia.
//

import Foundation
import ActivityKit

struct RenewalActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var daysLeft: Int   // 0 = oggi, 1 = domani
    }

    var subscriptionID: UUID
    var serviceName: String
    var cost: Double
    var currencyCode: String
    var categoryIcon: String
}

@MainActor
final class LiveActivityService {

    static let shared = LiveActivityService()
    private init() {}

    /// Allinea le Live Activity allo stato attuale: una per ogni rinnovo
    /// esatto entro domani (max 2), chiude quelle non più pertinenti.
    /// Le date stimate (≈) non attivano nulla: niente allarmi su date incerte.
    func sync(subscriptions: [Subscription]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let imminent = subscriptions
            .filter { $0.isActive && !$0.isDateEstimated && (0...1).contains($0.daysUntilRenewal) }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }

        let wanted = Dictionary(uniqueKeysWithValues: imminent.map { ($0.id, $0) })

        var alreadyRunning: Set<UUID> = []
        for activity in Activity<RenewalActivityAttributes>.activities {
            let id = activity.attributes.subscriptionID
            if let sub = wanted[id] {
                alreadyRunning.insert(id)
                let content = ActivityContent(
                    state: RenewalActivityAttributes.ContentState(daysLeft: sub.daysUntilRenewal),
                    staleDate: endOfToday
                )
                Task { await activity.update(content) }
            } else {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
        }

        for sub in imminent.prefix(2) where !alreadyRunning.contains(sub.id) {
            let attributes = RenewalActivityAttributes(
                subscriptionID: sub.id,
                serviceName: sub.displayName,
                cost: sub.cost,
                currencyCode: sub.currency,
                categoryIcon: sub.category.iconName
            )
            let content = ActivityContent(
                state: RenewalActivityAttributes.ContentState(daysLeft: sub.daysUntilRenewal),
                staleDate: endOfToday
            )
            _ = try? Activity.request(attributes: attributes, content: content)
        }
    }

    private var endOfToday: Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.startOfDay(for: tomorrow)
    }
}
