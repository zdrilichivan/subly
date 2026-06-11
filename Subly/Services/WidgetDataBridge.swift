//
//  WidgetDataBridge.swift
//  Subly
//
//  Pubblica nello UserDefaults dell'App Group lo snapshot compatto che il
//  widget legge (vedi WidgetStore in SublyWidget). I due lati condividono
//  solo il formato JSON, non il codice: se cambi i campi qui, aggiorna
//  anche WidgetSubscription/WidgetSnapshot nel target widget.
//

import Foundation
import WidgetKit

enum WidgetDataBridge {

    static let appGroupID = "group.com.ivanzdrilich.Subly"

    private struct WidgetSubscriptionDTO: Codable {
        let id: UUID
        let name: String
        let cost: Double
        let currencyCode: String
        let nextBillingDate: Date
        let categoryIcon: String
        let isDateEstimated: Bool
    }

    private struct WidgetSnapshotDTO: Codable {
        let subscriptions: [WidgetSubscriptionDTO]
        let monthlyTotal: Double
    }

    /// Da chiamare a ogni salvataggio degli abbonamenti
    static func publish(subscriptions: [Subscription]) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        let active = subscriptions
            .filter { $0.isActive }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }

        let snapshot = WidgetSnapshotDTO(
            subscriptions: active.prefix(6).map { sub in
                WidgetSubscriptionDTO(
                    id: sub.id,
                    name: sub.displayName,
                    cost: sub.cost,
                    currencyCode: sub.currency,
                    nextBillingDate: sub.nextBillingDate,
                    categoryIcon: sub.category.iconName,
                    isDateEstimated: sub.isDateEstimated
                )
            },
            monthlyTotal: active.reduce(0) { $0 + $1.monthlyCost }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshot) {
            defaults.set(data, forKey: "widgetSnapshot")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Da chiamare quando cambia lo stato Pro
    static func publishProStatus(_ isPro: Bool) {
        UserDefaults(suiteName: appGroupID)?.set(isPro, forKey: "widgetIsPro")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
