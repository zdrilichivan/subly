//
//  Constants.swift
//  SublySwift
//
//  Costanti, colori e configurazioni dell'app
//

import SwiftUI

struct Constants {

    // MARK: - CloudKit
    struct CloudKit {
        static let containerIdentifier = "iCloud.com.ivanzdrilich.SublySwift"
        static let subscriptionRecordType = "Subscription"
    }

    // MARK: - UserDefaults Keys
    struct UserDefaults {
        static let subscriptions = "subscriptions"
        static let budgetSettings = "budgetSettings"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let notificationsEnabled = "notificationsEnabled"
        static let pendingSyncSubscriptions = "pendingSyncSubscriptions"
    }

    // MARK: - Notifications
    struct Notifications {
        static let defaultHour = 17
        static let defaultMinute = 30
        static let daysBefore: [Int] = [3, 1, 0] // 3 giorni, 1 giorno, giorno stesso
    }

    // MARK: - Budget
    struct Budget {
        static let defaultNotifyPercentage: Double = 80
    }
}

// MARK: - App Colors
extension Color {
    // Colori principali
    static let appPrimary = Color.blue
    static let appSecondary = Color.purple
    static let appAccent = Color.mint

    // Colori per categorie (tutti ben distinti)
    static let categoryStreaming = Color.red
    static let categoryMusic = Color.green
    static let categorySoftware = Color.blue
    static let categoryFitness = Color.orange
    static let categoryCloud = Color.cyan
    static let categoryNews = Color.yellow
    static let categoryGaming = Color.purple
    static let categoryPhone = Color.indigo
    static let categoryOther = Color.gray

    // Colori stato budget
    static let budgetSafe = Color.green
    static let budgetWarning = Color.orange
    static let budgetDanger = Color.red

    // Glassmorphism
    static let glassBackground = Color(.systemBackground).opacity(0.8)
    static let glassBorder = Color.white.opacity(0.2)
}

// MARK: - Animations
extension Animation {
    static let springDefault = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let springQuick = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let easeDefault = Animation.easeInOut(duration: 0.25)
}

// MARK: - Haptic Feedback
enum Haptic {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Number Formatting
extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: self)) ?? "€\(self)"
    }

    var percentageFormatted: String {
        return String(format: "%.0f%%", self)
    }
}

// MARK: - Date Formatting
extension Date {
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }

    var relativeFormatted: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: self))

        guard let days = components.day else { return shortFormatted }

        switch days {
        case 0:
            return String(localized: "Oggi")
        case 1:
            return String(localized: "Domani")
        case 2...7:
            return String(localized: "Tra \(days) giorni")
        default:
            // Gli abbonamenti si rinnovano automaticamente, mostra sempre la data
            return shortFormatted
        }
    }

    var daysUntil: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: self))
        return components.day ?? 0
    }
}
