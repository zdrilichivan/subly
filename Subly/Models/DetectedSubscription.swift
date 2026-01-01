//
//  DetectedSubscription.swift
//  Subly
//
//  Modello per abbonamenti rilevati dalla scansione email
//

import Foundation

struct DetectedSubscription: Identifiable {
    let id: UUID
    let serviceName: String
    let detectedCost: Double?
    let detectedCycle: BillingCycle?
    let sourceEmail: String
    let emailDate: Date?
    let confidence: Double
    let matchedService: Service?
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        serviceName: String,
        detectedCost: Double? = nil,
        detectedCycle: BillingCycle? = nil,
        sourceEmail: String,
        emailDate: Date? = nil,
        confidence: Double,
        matchedService: Service? = nil,
        isSelected: Bool = true
    ) {
        self.id = id
        self.serviceName = serviceName
        self.detectedCost = detectedCost
        self.detectedCycle = detectedCycle
        self.sourceEmail = sourceEmail
        self.emailDate = emailDate
        self.confidence = confidence
        self.matchedService = matchedService
        self.isSelected = isSelected
    }

    /// Converte in Subscription per l'aggiunta
    func toSubscription() -> Subscription {
        Subscription(
            serviceName: matchedService?.name ?? serviceName,
            customName: matchedService == nil ? serviceName : nil,
            cost: detectedCost ?? 0,
            billingCycle: detectedCycle ?? .monthly,
            nextBillingDate: calculateNextBillingDate(),
            notes: String(localized: "Importato da email"),
            category: matchedService?.category ?? .other,
            isEssential: false,
            sharedWith: nil
        )
    }

    private func calculateNextBillingDate() -> Date {
        guard let lastDate = emailDate else {
            return Date()
        }

        let cycle = detectedCycle ?? .monthly
        let calendar = Calendar.current

        var nextDate = lastDate
        while nextDate < Date() {
            switch cycle {
            case .weekly:
                nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate) ?? nextDate
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            case .yearly:
                nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate
            }
        }

        return nextDate
    }

    /// Livello di confidenza come testo
    var confidenceLevel: String {
        switch confidence {
        case 0.8...1.0:
            return String(localized: "Alta")
        case 0.5..<0.8:
            return String(localized: "Media")
        default:
            return String(localized: "Bassa")
        }
    }

    /// Colore per il livello di confidenza
    var confidenceColor: String {
        switch confidence {
        case 0.8...1.0:
            return "green"
        case 0.5..<0.8:
            return "orange"
        default:
            return "red"
        }
    }
}
