//
//  BudgetSettings.swift
//  SublySwift
//
//  Modello per le impostazioni del budget
//

import Foundation

struct BudgetSettings: Codable, Equatable {
    var monthlyLimit: Double?
    var notifyAtPercentage: Double
    var isEnabled: Bool

    init(
        monthlyLimit: Double? = nil,
        notifyAtPercentage: Double = Constants.Budget.defaultNotifyPercentage,
        isEnabled: Bool = false
    ) {
        self.monthlyLimit = monthlyLimit
        self.notifyAtPercentage = notifyAtPercentage
        self.isEnabled = isEnabled
    }

    // MARK: - Computed Properties

    var hasLimit: Bool {
        monthlyLimit != nil && monthlyLimit! > 0
    }
}

// MARK: - Budget Status
struct BudgetStatus {
    let limit: Double
    let current: Double
    let percentage: Double
    let remaining: Double
    let isOverBudget: Bool
    let status: BudgetStatusLevel

    init(limit: Double, current: Double) {
        self.limit = limit
        self.current = current
        self.percentage = limit > 0 ? (current / limit) * 100 : 0
        self.remaining = limit - current
        self.isOverBudget = current > limit

        if percentage >= 100 {
            self.status = .exceeded
        } else if percentage >= 80 {
            self.status = .warning
        } else {
            self.status = .safe
        }
    }

    var statusText: String {
        switch status {
        case .safe:
            return "Rimangono \(remaining.currencyFormatted)"
        case .warning:
            return "Attenzione: \(percentage.percentageFormatted) del budget"
        case .exceeded:
            return "Superato di \(abs(remaining).currencyFormatted)"
        }
    }

    var statusColor: Color {
        switch status {
        case .safe:
            return .budgetSafe
        case .warning:
            return .budgetWarning
        case .exceeded:
            return .budgetDanger
        }
    }
}

enum BudgetStatusLevel {
    case safe
    case warning
    case exceeded
}

import SwiftUI
