//
//  InsightService.swift
//  Subly
//
//  Servizio per generare insight sul minimalismo digitale
//  e aiutare gli utenti a ripensare le proprie spese
//

import Foundation
import SwiftUI
import Combine

class InsightService: ObservableObject {
    static let shared = InsightService()

    // MARK: - Spending Comparisons

    /// Genera confronti concreti su cosa si potrebbe fare con i soldi spesi
    func getSpendingComparisons(yearlyCost: Double) -> [SpendingComparison] {
        var comparisons: [SpendingComparison] = []

        // Solo se si spende abbastanza da fare confronti significativi
        if yearlyCost >= 100 {
            comparisons.append(SpendingComparison(
                icon: "cup.and.saucer.fill",
                title: "Caffè al bar",
                description: "\(Int(yearlyCost / 1.5)) caffè all'anno",
                color: .brown
            ))
        }

        if yearlyCost >= 200 {
            comparisons.append(SpendingComparison(
                icon: "fork.knife",
                title: "Cene fuori",
                description: "\(Int(yearlyCost / 50)) cene al ristorante",
                color: .pink
            ))
        }

        if yearlyCost >= 500 {
            comparisons.append(SpendingComparison(
                icon: "airplane",
                title: "Weekend fuori",
                description: "\(Int(yearlyCost / 300)) weekend in una città europea",
                color: .blue
            ))
        }

        if yearlyCost >= 1000 {
            comparisons.append(SpendingComparison(
                icon: "figure.2.and.child.holdinghands",
                title: "Vacanza in famiglia",
                description: "Una settimana al mare per tutta la famiglia",
                color: .cyan
            ))
        }

        if yearlyCost >= 1500 {
            comparisons.append(SpendingComparison(
                icon: "books.vertical.fill",
                title: "Corso di formazione",
                description: "Un corso professionale che migliora la tua carriera",
                color: .purple
            ))
        }

        if yearlyCost >= 2000 {
            comparisons.append(SpendingComparison(
                icon: "banknote.fill",
                title: "Fondo emergenza",
                description: "2 mesi di spese impreviste coperte",
                color: .green
            ))
        }

        return comparisons
    }

    // MARK: - Get Primary Comparison (for Home card)

    func getPrimaryComparison(yearlyCost: Double) -> SpendingComparison? {
        let comparisons = getSpendingComparisons(yearlyCost: yearlyCost)
        // Restituisce il confronto più impattante (l'ultimo disponibile)
        return comparisons.last
    }

    // MARK: - Minimalism Tips

    let minimalismTips: [MinimalismTip] = [
        MinimalismTip(
            title: "Uno alla volta",
            message: "Hai davvero bisogno di Netflix, Prime Video E Disney+? Prova a tenerne uno solo per un mese.",
            icon: "tv.fill"
        ),
        MinimalismTip(
            title: "La regola dei 30 giorni",
            message: "Prima di rinnovare, chiediti: l'ho usato negli ultimi 30 giorni? Se no, probabilmente non ti serve.",
            icon: "calendar"
        ),
        MinimalismTip(
            title: "Condividi, non moltiplicare",
            message: "Molti servizi permettono profili familiari. Condividi con amici o parenti invece di pagare tutti.",
            icon: "person.3.fill"
        ),
        MinimalismTip(
            title: "Le alternative gratuite esistono",
            message: "YouTube gratuito, Spotify free, librerie digitali... Spesso il gratis basta e avanza.",
            icon: "gift.fill"
        ),
        MinimalismTip(
            title: "Il costo nascosto",
            message: "€9.99/mese sembrano pochi, ma sono €120/anno. Moltiplica per 5 abbonamenti e hai €600 volati via.",
            icon: "eye.slash.fill"
        ),
        MinimalismTip(
            title: "Tempo = Denaro",
            message: "Quante ore lavori per pagare tutti questi abbonamenti? Vale davvero la pena?",
            icon: "clock.fill"
        ),
        MinimalismTip(
            title: "Il minimalismo digitale",
            message: "Meno servizi significa meno distrazioni, più tempo per ciò che conta davvero.",
            icon: "leaf.fill"
        ),
        MinimalismTip(
            title: "Prova la pausa",
            message: "Metti in pausa un abbonamento per un mese. Se non ti manca, non ti serviva.",
            icon: "pause.circle.fill"
        )
    ]

    func getRandomTip() -> MinimalismTip {
        minimalismTips.randomElement()!
    }

    func getTipOfTheDay() -> MinimalismTip {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % minimalismTips.count
        return minimalismTips[index]
    }

    // MARK: - Provocative Questions

    func getProvocativeQuestions(for subscriptions: [Subscription]) -> [ProvocativeQuestion] {
        var questions: [ProvocativeQuestion] = []

        // Conta abbonamenti streaming
        let streamingCount = subscriptions.filter { $0.category == .streaming && $0.isActive }.count
        if streamingCount >= 3 {
            questions.append(ProvocativeQuestion(
                question: "Hai \(streamingCount) servizi streaming. Quanti ne guardi davvero?",
                suggestion: "Prova a tenerne solo uno per un mese"
            ))
        }

        // Conta abbonamenti musica
        let musicCount = subscriptions.filter { $0.category == .music && $0.isActive }.count
        if musicCount >= 2 {
            questions.append(ProvocativeQuestion(
                question: "Paghi \(musicCount) servizi musicali. Le tue orecchie sono due.",
                suggestion: "Uno basta, fidati"
            ))
        }

        // Abbonamenti costosi
        let expensiveOnes = subscriptions.filter { $0.isActive && $0.monthlyCost > 15 }
        for sub in expensiveOnes.prefix(2) {
            questions.append(ProvocativeQuestion(
                question: "\(sub.displayName) ti costa \(sub.monthlyCost.currencyFormatted)/mese. Lo usi ogni giorno?",
                suggestion: "Se no, stai pagando per niente"
            ))
        }

        // Totale abbonamenti
        let activeCount = subscriptions.filter { $0.isActive }.count
        if activeCount >= 5 {
            questions.append(ProvocativeQuestion(
                question: "\(activeCount) abbonamenti attivi. Riesci a elencarli tutti a memoria?",
                suggestion: "Se devi pensarci, forse sono troppi"
            ))
        }

        if activeCount >= 8 {
            questions.append(ProvocativeQuestion(
                question: "Più abbonamenti di giorni della settimana. È davvero necessario?",
                suggestion: "Il minimalismo inizia con una scelta coraggiosa"
            ))
        }

        return questions
    }

    // MARK: - Minimalism Score

    func calculateMinimalismScore(subscriptions: [Subscription], monthlyCost: Double) -> MinimalismScore {
        let activeCount = subscriptions.filter { $0.isActive }.count

        var score: Int
        var level: String
        var message: String
        var color: Color

        // Calcolo basato su numero abbonamenti e costo
        if activeCount == 0 {
            score = 100
            level = "Minimalista Zen"
            message = "Complimenti! Zero abbonamenti, massima libertà."
            color = .green
        } else if activeCount <= 2 && monthlyCost <= 20 {
            score = 90
            level = "Minimalista"
            message = "Ottimo! Hai solo l'essenziale."
            color = .green
        } else if activeCount <= 4 && monthlyCost <= 40 {
            score = 70
            level = "Equilibrato"
            message = "Buon equilibrio, ma c'è margine di miglioramento."
            color = .yellow
        } else if activeCount <= 6 && monthlyCost <= 70 {
            score = 50
            level = "Nella media"
            message = "Come la maggior parte delle persone. Vuoi essere come tutti?"
            color = .orange
        } else if activeCount <= 10 {
            score = 30
            level = "Abbonato seriale"
            message = "Tanti servizi, poco tempo per usarli tutti."
            color = .orange
        } else {
            score = 10
            level = "Collezionista"
            message = "Stai pagando aziende per servizi che non usi. È ora di cambiare."
            color = .red
        }

        return MinimalismScore(
            score: score,
            level: level,
            message: message,
            color: color,
            subscriptionCount: activeCount,
            monthlyCost: monthlyCost
        )
    }

    // MARK: - Smart Notifications Messages

    func getRenewalNotificationMessage(for subscription: Subscription, daysUntil: Int) -> String {
        let cost = subscription.cost.currencyFormatted
        let name = subscription.displayName

        switch daysUntil {
        case 3:
            return "⏰ \(name) si rinnova tra 3 giorni (\(cost)). È il momento di chiederti: mi serve davvero?"
        case 1:
            return "⚠️ Domani si rinnova \(name) (\(cost)). Ultima chance per ripensarci!"
        case 0:
            return "📅 Oggi si rinnova \(name) (\(cost)). Hai ancora bisogno di questo servizio?"
        default:
            return "\(name) si rinnova tra \(daysUntil) giorni (\(cost))"
        }
    }

    func getMotivationalNotifications(monthlyCost: Double, subscriptionCount: Int) -> [String] {
        var notifications: [String] = []

        if monthlyCost > 50 {
            notifications.append("💸 Questo mese spendi \(monthlyCost.currencyFormatted) in abbonamenti. Con gli stessi soldi potresti...")
        }

        if subscriptionCount >= 5 {
            notifications.append("🤔 Hai \(subscriptionCount) abbonamenti attivi. Li usi davvero tutti?")
        }

        let yearlyCost = monthlyCost * 12
        if yearlyCost > 500 {
            notifications.append("✈️ \(yearlyCost.currencyFormatted)/anno in abbonamenti = un viaggio che ricorderai per sempre")
        }

        return notifications
    }
}

// MARK: - Models

struct SpendingComparison: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct MinimalismTip: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
}

struct ProvocativeQuestion: Identifiable {
    let id = UUID()
    let question: String
    let suggestion: String
}

struct MinimalismScore {
    let score: Int
    let level: String
    let message: String
    let color: Color
    let subscriptionCount: Int
    let monthlyCost: Double
}
