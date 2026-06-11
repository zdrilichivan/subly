//
//  PersonalCoachService.swift
//  Subly
//
//  Il cuore "vivo" del Money Coach: streak di visite giornaliere,
//  sfida della settimana con progresso, e consiglio AI personalizzato
//  generato da Gemini sui dati reali degli abbonamenti (cache giornaliera,
//  fallback silenzioso se l'API non risponde).
//

import Foundation
import Combine

@MainActor
final class PersonalCoachService: ObservableObject {

    static let shared = PersonalCoachService()

    // MARK: - Published

    @Published private(set) var streak = 0
    @Published private(set) var personalizedTip: String?
    @Published private(set) var isLoadingTip = false
    @Published private(set) var challengeTip: DailyTip?
    @Published private(set) var challengeCompletedDays: Set<Int> = []

    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current

    private init() {}

    // MARK: - Streak

    /// Da chiamare quando l'utente apre il coach: aggiorna la striscia
    /// di giorni consecutivi (ieri → +1, oggi → invariata, altrimenti riparte)
    func registerVisit() {
        let today = calendar.startOfDay(for: Date())
        var current = defaults.integer(forKey: "coachStreak")

        if let last = defaults.object(forKey: "coachLastVisit") as? Date {
            let lastDay = calendar.startOfDay(for: last)
            if lastDay == today {
                streak = max(current, 1)
                return
            }
            if calendar.date(byAdding: .day, value: 1, to: lastDay) == today {
                current += 1
            } else {
                current = 1
            }
        } else {
            current = 1
        }

        defaults.set(Date(), forKey: "coachLastVisit")
        defaults.set(current, forKey: "coachStreak")
        streak = current
    }

    // MARK: - Sfida della settimana

    /// Identificatore della settimana corrente (es. "2026-W24")
    private var currentWeekKey: String {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return "\(comps.yearForWeekOfYear ?? 0)-W\(comps.weekOfYear ?? 0)"
    }

    /// Giorno della settimana 1...7 con lunedì = 1 (indipendente dal locale)
    var todayWeekdayIndex: Int {
        let weekday = calendar.component(.weekday, from: Date()) // 1 = domenica
        return weekday == 1 ? 7 : weekday - 1
    }

    func loadChallenge() {
        let challenges = DailyTipsService.shared.challengeTips
        guard !challenges.isEmpty else { return }

        let week = calendar.component(.weekOfYear, from: Date())
        challengeTip = challenges[week % challenges.count]

        // Reset automatico a inizio settimana
        if defaults.string(forKey: "challengeWeek") != currentWeekKey {
            defaults.set(currentWeekKey, forKey: "challengeWeek")
            defaults.set(Data(), forKey: "challengeDoneDays")
        }

        if let data = defaults.data(forKey: "challengeDoneDays"),
           let days = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            challengeCompletedDays = days
        } else {
            challengeCompletedDays = []
        }
    }

    var isTodayChallengeDone: Bool {
        challengeCompletedDays.contains(todayWeekdayIndex)
    }

    var isChallengeCompleted: Bool {
        challengeCompletedDays.count >= 7
    }

    func toggleTodayChallenge() {
        if isTodayChallengeDone {
            challengeCompletedDays.remove(todayWeekdayIndex)
        } else {
            challengeCompletedDays.insert(todayWeekdayIndex)
        }
        if let data = try? JSONEncoder().encode(challengeCompletedDays) {
            defaults.set(data, forKey: "challengeDoneDays")
        }
    }

    // MARK: - Consiglio AI personalizzato

    private var todayTipCacheKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "personalCoachTip-" + formatter.string(from: Date())
    }

    /// Genera (o recupera dalla cache giornaliera) un consiglio basato
    /// sugli abbonamenti reali dell'utente. Fallisce in silenzio:
    /// se l'API non risponde la card semplicemente non appare.
    func loadPersonalizedTip(subscriptions: [Subscription]) async {
        if let cached = defaults.string(forKey: todayTipCacheKey), !cached.isEmpty {
            personalizedTip = cached
            return
        }

        guard GeminiService.shared.isConfigured, !subscriptions.isEmpty else {
            personalizedTip = nil
            return
        }

        isLoadingTip = true
        defer { isLoadingTip = false }

        let summary = subscriptions
            .filter { $0.isActive }
            .sorted { $0.monthlyCost > $1.monthlyCost }
            .prefix(10)
            .map { sub in
                "- \(sub.displayName): \(sub.cost.currencyFormatted)\(sub.billingCycle.shortName), " +
                String(localized: "rinnovo") + " \(sub.renewalText)"
            }
            .joined(separator: "\n")

        let languageName: String
        switch Locale.current.language.languageCode?.identifier {
        case "it": languageName = "italiano"
        case "es": languageName = "spagnolo"
        default: languageName = "inglese"
        }

        let prompt = """
        Sei un money coach amichevole e diretto. Questi sono gli abbonamenti attivi dell'utente:
        \(summary)

        Spesa mensile totale: \(subscriptions.filter { $0.isActive }.reduce(0) { $0 + $1.monthlyCost }.currencyFormatted)

        Dai UN solo consiglio pratico e specifico riferito a questi abbonamenti (confronti, doppioni, piani più convenienti, rinnovi imminenti da valutare). Massimo 50 parole, niente markdown, niente saluti, tono diretto e concreto. Rispondi in \(languageName).
        """

        do {
            let text = try await GeminiService.shared.callAPI(prompt: prompt, temperature: 0.8, maxTokens: 200)
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else {
                personalizedTip = nil
                return
            }
            defaults.set(cleaned, forKey: todayTipCacheKey)
            personalizedTip = cleaned
        } catch {
            personalizedTip = nil
        }
    }
}
