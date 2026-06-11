//
//  AnalyticsService.swift
//  Subly
//
//  Tracking leggero del funnel di conversione.
//  Backend pluggabile: di default logga su OSLog e mantiene contatori locali,
//  pronto per collegare TelemetryDeck o simili senza toccare i call site.
//

import Foundation
import os

// MARK: - Eventi del funnel

enum AnalyticsEvent: String {
    // Onboarding
    case onboardingStarted = "onboarding_started"
    case onboardingStepViewed = "onboarding_step_viewed"
    case onboardingServicesSelected = "onboarding_services_selected"
    case onboardingSpendingRevealed = "onboarding_spending_revealed"
    case onboardingCompleted = "onboarding_completed"

    // Paywall
    case paywallShown = "paywall_shown"
    case paywallPlanSelected = "paywall_plan_selected"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case purchaseCancelled = "purchase_cancelled"
    case paywallDismissed = "paywall_dismissed"
    case purchasesRestored = "purchases_restored"

    // Agganci secondari
    case milestoneShown = "milestone_shown"
    case trialReminderScheduled = "trial_reminder_scheduled"
    case freeLimitReached = "free_limit_reached"
    case subscriptionCancelled = "subscription_cancelled"
}

// MARK: - Backend pluggabile

protocol AnalyticsBackend {
    func send(event: String, properties: [String: String])
}

/// Backend di default: log strutturato + contatori locali per diagnosi.
/// Per attivare un backend remoto (es. TelemetryDeck):
/// 1. aggiungere il package SPM
/// 2. creare un backend che inoltra `send` all'SDK
/// 3. assegnarlo in `AnalyticsService.shared.backend`
struct LocalLogBackend: AnalyticsBackend {
    private let logger = Logger(subsystem: "com.ivanzdrilich.SublySwift", category: "Analytics")

    func send(event: String, properties: [String: String]) {
        let props = properties.isEmpty ? "" : " \(properties)"
        logger.info("📊 \(event, privacy: .public)\(props, privacy: .public)")

        // Contatori cumulativi locali, utili per debug senza backend remoto
        let key = "analytics_count_\(event)"
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }
}

// MARK: - Servizio

final class AnalyticsService {

    static let shared = AnalyticsService()

    var backend: AnalyticsBackend = LocalLogBackend()

    private init() {
        // Con un App ID configurato i segnali vanno a TelemetryDeck
        // (che logga comunque anche in locale); altrimenti solo OSLog.
        if !Secrets.telemetryDeckAppID.isEmpty {
            backend = TelemetryDeckBackend()
        }
    }

    func track(_ event: AnalyticsEvent, properties: [String: String] = [:]) {
        backend.send(event: event.rawValue, properties: properties)
    }
}
