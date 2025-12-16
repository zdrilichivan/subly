//
//  Subscription.swift
//  SublySwift
//
//  Modello principale per gli abbonamenti
//

import Foundation

// MARK: - Subscription Model
struct Subscription: Identifiable, Codable, Equatable {
    let id: UUID
    var serviceName: String
    var customName: String?
    var cost: Double
    var currency: String
    var billingCycle: BillingCycle
    var nextBillingDate: Date
    var notes: String?
    var isActive: Bool
    var category: ServiceCategory
    var isEssential: Bool
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        serviceName: String,
        customName: String? = nil,
        cost: Double,
        currency: String = "EUR",
        billingCycle: BillingCycle = .monthly,
        nextBillingDate: Date,
        notes: String? = nil,
        isActive: Bool = true,
        category: ServiceCategory = .other,
        isEssential: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.serviceName = serviceName
        self.customName = customName
        self.cost = cost
        self.currency = currency
        self.billingCycle = billingCycle
        self.nextBillingDate = nextBillingDate
        self.notes = notes
        self.isActive = isActive
        self.category = category
        self.isEssential = isEssential
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Nome da visualizzare (customName se presente, altrimenti serviceName)
    var displayName: String {
        customName?.trimmed.isNotEmpty == true ? customName! : serviceName
    }

    /// Costo mensile normalizzato
    var monthlyCost: Double {
        switch billingCycle {
        case .weekly:
            return cost * 4.33
        case .monthly:
            return cost
        case .yearly:
            return cost / 12
        }
    }

    /// Costo annuale normalizzato
    var yearlyCost: Double {
        monthlyCost * 12
    }

    /// Descrizione del ciclo di fatturazione
    var billingCycleDescription: String {
        switch billingCycle {
        case .weekly:
            return "Settimanale"
        case .monthly:
            return "Mensile"
        case .yearly:
            return "Annuale"
        }
    }

    /// Giorni fino al prossimo rinnovo
    var daysUntilRenewal: Int {
        nextBillingDate.daysUntil
    }

    /// Testo relativo per il rinnovo
    var renewalText: String {
        nextBillingDate.relativeFormatted
    }

    /// Se il rinnovo è imminente (entro 7 giorni)
    var isRenewalSoon: Bool {
        daysUntilRenewal >= 0 && daysUntilRenewal <= 7
    }

    /// Se il rinnovo è oggi
    var isRenewalToday: Bool {
        daysUntilRenewal == 0
    }

    // MARK: - Mutating Methods

    /// Aggiorna la data di rinnovo al prossimo ciclo
    mutating func advanceToNextBillingDate() {
        let calendar = Calendar.current
        switch billingCycle {
        case .weekly:
            nextBillingDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextBillingDate) ?? nextBillingDate
        case .monthly:
            nextBillingDate = calendar.date(byAdding: .month, value: 1, to: nextBillingDate) ?? nextBillingDate
        case .yearly:
            nextBillingDate = calendar.date(byAdding: .year, value: 1, to: nextBillingDate) ?? nextBillingDate
        }
        updatedAt = Date()
    }
}

// MARK: - Billing Cycle
enum BillingCycle: String, Codable, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .weekly:
            return "Settimanale"
        case .monthly:
            return "Mensile"
        case .yearly:
            return "Annuale"
        }
    }

    var shortName: String {
        switch self {
        case .weekly:
            return "/sett"
        case .monthly:
            return "/mese"
        case .yearly:
            return "/anno"
        }
    }
}

// MARK: - Service Category
enum ServiceCategory: String, Codable, CaseIterable {
    case streaming = "streaming"
    case music = "music"
    case software = "software"
    case fitness = "fitness"
    case cloud = "cloud"
    case news = "news"
    case gaming = "gaming"
    case phone = "phone"
    case other = "other"

    var displayName: String {
        switch self {
        case .streaming:
            return "Streaming Video"
        case .music:
            return "Musica"
        case .software:
            return "Software"
        case .fitness:
            return "Fitness"
        case .cloud:
            return "Cloud Storage"
        case .news:
            return "News & Media"
        case .gaming:
            return "Gaming"
        case .phone:
            return "Telefonia"
        case .other:
            return "Altro"
        }
    }

    var iconName: String {
        switch self {
        case .streaming:
            return "play.tv.fill"
        case .music:
            return "music.note"
        case .software:
            return "app.badge.fill"
        case .fitness:
            return "figure.run"
        case .cloud:
            return "cloud.fill"
        case .news:
            return "newspaper.fill"
        case .gaming:
            return "gamecontroller.fill"
        case .phone:
            return "phone.fill"
        case .other:
            return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .streaming:
            return .categoryStreaming
        case .music:
            return .categoryMusic
        case .software:
            return .categorySoftware
        case .fitness:
            return .categoryFitness
        case .cloud:
            return .categoryCloud
        case .news:
            return .categoryNews
        case .gaming:
            return .categoryGaming
        case .phone:
            return .categoryPhone
        case .other:
            return .categoryOther
        }
    }
}

// MARK: - Color Import
import SwiftUI
