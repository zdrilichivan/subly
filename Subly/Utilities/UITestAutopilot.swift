//
//  UITestAutopilot.swift
//  Subly
//
//  Hook solo-DEBUG per pilotare l'app da riga di comando (screenshot,
//  ispezione UI). Si attiva passando variabili d'ambiente via simctl:
//
//    SIMCTL_CHILD_UITEST_SKIP_ONBOARDING=1 \
//    SIMCTL_CHILD_UITEST_SEED=1 \
//    SIMCTL_CHILD_UITEST_TAB=1 \
//    xcrun simctl launch booted com.ivanzdrilich.Subly
//
//  Variabili supportate:
//    UITEST_SKIP_ONBOARDING=1  salta l'onboarding
//    UITEST_SEED=1             nome utente + 5 abbonamenti realistici
//    UITEST_TAB=0..3           tab iniziale (home/stats/coach/settings)
//    UITEST_ONBOARDING_PAGE=n  apre l'onboarding alla pagina n
//    UITEST_SHOW_PAYWALL=1     mostra subito il paywall (da onboarding)
//    UITEST_PRO=1              forza lo stato Pro
//
//  Il blocco #if DEBUG esclude tutto dalla build di release.
//

#if DEBUG
import Foundation

enum UITestAutopilot {

    private static var env: [String: String] { ProcessInfo.processInfo.environment }

    /// True se almeno una variabile UITEST_* è presente
    static var isActive: Bool {
        env.keys.contains { $0.hasPrefix("UITEST") }
    }

    static var skipOnboarding: Bool { env["UITEST_SKIP_ONBOARDING"] == "1" }
    static var initialTab: Int? { env["UITEST_TAB"].flatMap(Int.init) }
    static var onboardingPage: Int? { env["UITEST_ONBOARDING_PAGE"].flatMap(Int.init) }
    static var showPaywall: Bool { env["UITEST_SHOW_PAYWALL"] == "1" }
    static var forcePro: Bool { env["UITEST_PRO"] == "1" }
    static var showDateSheet: Bool { env["UITEST_DATE_SHEET"] == "1" }
    static var showCelebration: Bool { env["UITEST_CELEBRATION"] == "1" }

    /// Da chiamare in SublySwiftApp.init, prima che il view model carichi i dati
    static func applyOnLaunch() {
        guard isActive else { return }

        if skipOnboarding {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
        if forcePro {
            UserDefaults.standard.set(true, forKey: "isSublyPro")
        }
        if env["UITEST_SEED"] == "1" {
            seedSampleData()
        }
    }

    private static func seedSampleData() {
        let defaults = UserDefaults.standard
        defaults.set("Ivan", forKey: "userName")

        let calendar = Calendar.current
        func days(_ n: Int) -> Date { calendar.date(byAdding: .day, value: n, to: Date()) ?? Date() }

        let subscriptions = [
            Subscription(serviceName: "Netflix Standard", cost: 13.99, billingCycle: .monthly,
                         nextBillingDate: days(2), category: .streaming),
            Subscription(serviceName: "Spotify Individual", cost: 10.99, billingCycle: .monthly,
                         nextBillingDate: days(6), category: .music),
            Subscription(serviceName: "iCloud+ 200GB", cost: 2.99, billingCycle: .monthly,
                         nextBillingDate: days(11), category: .cloud, isDateEstimated: true),
            Subscription(serviceName: "Amazon Prime Annuale", cost: 49.90, billingCycle: .yearly,
                         nextBillingDate: days(40), category: .streaming),
            Subscription(serviceName: "ChatGPT Plus", cost: 22.99, billingCycle: .monthly,
                         nextBillingDate: days(17), category: .software)
        ]

        if let data = try? JSONEncoder().encode(subscriptions) {
            defaults.set(data, forKey: Constants.UserDefaults.subscriptions)
        }
        defaults.set(subscriptions.reduce(0) { $0 + $1.monthlyCost * 12 }, forKey: "estimatedYearlySpend")

        // Risparmi da disdette per il banner in dashboard
        defaults.set(311.76, forKey: "totalCancelledYearlySavings")
        defaults.set(2, forKey: "cancelledSubscriptionsCount")
    }
}
#endif
