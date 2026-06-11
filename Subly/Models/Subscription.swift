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
    var sharedWith: Int?  // Numero di persone con cui è condiviso (incluso l'utente)
    var isDateEstimated: Bool  // True se l'utente non ricordava la data di addebito
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
        sharedWith: Int? = nil,
        isDateEstimated: Bool = false,
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
        self.sharedWith = sharedWith
        self.isDateEstimated = isDateEstimated
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Codable retro-compatibile
    // isDateEstimated è stato aggiunto dopo il rilascio: decodeIfPresent
    // evita di invalidare la cache locale degli utenti esistenti.
    enum CodingKeys: String, CodingKey {
        case id, serviceName, customName, cost, currency, billingCycle
        case nextBillingDate, notes, isActive, category, isEssential
        case sharedWith, isDateEstimated, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        serviceName = try container.decode(String.self, forKey: .serviceName)
        customName = try container.decodeIfPresent(String.self, forKey: .customName)
        cost = try container.decode(Double.self, forKey: .cost)
        currency = try container.decode(String.self, forKey: .currency)
        billingCycle = try container.decode(BillingCycle.self, forKey: .billingCycle)
        nextBillingDate = try container.decode(Date.self, forKey: .nextBillingDate)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        category = try container.decode(ServiceCategory.self, forKey: .category)
        isEssential = try container.decode(Bool.self, forKey: .isEssential)
        sharedWith = try container.decodeIfPresent(Int.self, forKey: .sharedWith)
        isDateEstimated = try container.decodeIfPresent(Bool.self, forKey: .isDateEstimated) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    // MARK: - Computed Properties

    /// Nome da visualizzare (customName se presente, altrimenti serviceName)
    var displayName: String {
        customName?.trimmed.isNotEmpty == true ? customName! : serviceName
    }

    /// Costo mensile normalizzato (considera la condivisione)
    var monthlyCost: Double {
        let baseCost: Double
        switch billingCycle {
        case .weekly:
            baseCost = cost * 4.33
        case .monthly:
            baseCost = cost
        case .yearly:
            baseCost = cost / 12
        }
        // Se condiviso, restituisce la quota pro-capite
        let people = max(sharedWith ?? 1, 1)
        return baseCost / Double(people)
    }

    /// Costo annuale normalizzato (considera la condivisione)
    var yearlyCost: Double {
        monthlyCost * 12
    }

    /// Costo mensile TOTALE (senza considerare la condivisione)
    var totalMonthlyCost: Double {
        switch billingCycle {
        case .weekly:
            return cost * 4.33
        case .monthly:
            return cost
        case .yearly:
            return cost / 12
        }
    }

    /// Costo annuale TOTALE (senza considerare la condivisione)
    var totalYearlyCost: Double {
        totalMonthlyCost * 12
    }

    /// Descrizione del ciclo di fatturazione
    var billingCycleDescription: String {
        billingCycle.displayName
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

    /// Se l'abbonamento è condiviso
    var isShared: Bool {
        (sharedWith ?? 1) > 1
    }

    /// Costo pro-capite per il ciclo di fatturazione (se condiviso)
    var perPersonCost: Double {
        let people = max(sharedWith ?? 1, 1)
        return cost / Double(people)
    }

    // MARK: - Mutating Methods

    /// Ri-ancora la data di rinnovo a un addebito reale appena avvenuto:
    /// il prossimo rinnovo diventa esatto (oggi + un ciclo) e la data
    /// smette di essere una stima.
    mutating func anchorToCharge(on chargeDate: Date = Date()) {
        nextBillingDate = Self.nextDate(after: chargeDate, cycle: billingCycle)
        isDateEstimated = false
        updatedAt = Date()
    }

    /// Data del rinnovo successivo a partire da un addebito avvenuto in `date`
    static func nextDate(after date: Date, cycle: BillingCycle) -> Date {
        let calendar = Calendar.current
        switch cycle {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }

    /// Stima della prossima data di addebito quando l'utente non la ricorda:
    /// metà ciclo da oggi (valore atteso per una data uniformemente distribuita)
    static func estimatedNextDate(cycle: BillingCycle) -> Date {
        let calendar = Calendar.current
        let now = Date()
        switch cycle {
        case .weekly:
            return calendar.date(byAdding: .day, value: 3, to: now) ?? now
        case .monthly:
            return calendar.date(byAdding: .day, value: 15, to: now) ?? now
        case .yearly:
            return calendar.date(byAdding: .month, value: 6, to: now) ?? now
        }
    }

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
            return String(localized: "Settimanale")
        case .monthly:
            return String(localized: "Mensile")
        case .yearly:
            return String(localized: "Annuale")
        }
    }

    var shortName: String {
        switch self {
        case .weekly:
            return "/" + String(localized: "sett")
        case .monthly:
            return "/" + String(localized: "mese")
        case .yearly:
            return "/" + String(localized: "anno")
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
            return String(localized: "Streaming Video")
        case .music:
            return String(localized: "Musica")
        case .software:
            return String(localized: "Software")
        case .fitness:
            return String(localized: "Fitness")
        case .cloud:
            return String(localized: "Cloud Storage")
        case .news:
            return String(localized: "News & Media")
        case .gaming:
            return String(localized: "Gaming")
        case .phone:
            return String(localized: "Telefonia")
        case .other:
            return String(localized: "Altro")
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
