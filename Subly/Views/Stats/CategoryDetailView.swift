//
//  CategoryDetailView.swift
//  Subly
//
//  Vista dettaglio per una categoria di abbonamenti
//

import SwiftUI

struct CategoryDetailView: View {
    let category: ServiceCategory
    let subscriptions: [Subscription]
    let totalAmount: Double
    let percentage: Double

    private let insightService = InsightService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                headerCard

                // Insight per categoria (se applicabile)
                if let insight = getCategoryInsight() {
                    categoryInsightCard(insight: insight)
                }

                // Lista abbonamenti
                subscriptionsListSection

                // Suggerimento finale
                if subscriptions.count >= 2 {
                    suggestionCard
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 70, height: 70)

                Image(systemName: category.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(category.color)
            }

            // Category name
            Text(category.displayName)
                .font(.title2)
                .fontWeight(.bold)

            // Stats
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text(totalAmount.currencyFormatted)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(category.color)
                    Text("al mese")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text((totalAmount * 12).currencyFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("all'anno")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text(percentage.percentageFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("del totale")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(category.color)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Category Insight

    private func getCategoryInsight() -> String? {
        switch category {
        case .streaming:
            if subscriptions.count >= 3 {
                return "Hai \(subscriptions.count) servizi streaming. La maggior parte delle persone ne usa attivamente solo uno alla volta. Considera di alternare invece di pagare tutti insieme."
            } else if subscriptions.count == 2 {
                return "Due servizi streaming possono avere senso, ma li guardi entrambi regolarmente?"
            }
        case .music:
            if subscriptions.count >= 2 {
                return "Più di un servizio musicale? La tua musica preferita probabilmente è su entrambi. Uno solo basterebbe."
            }
        case .software:
            if totalAmount > 50 {
                return "Spendi \(totalAmount.currencyFormatted)/mese in software. Esistono alternative gratuite per molti di questi servizi?"
            }
        case .gaming:
            if subscriptions.count >= 2 {
                return "Hai abbastanza tempo per giocare su \(subscriptions.count) piattaforme diverse?"
            }
        case .cloud:
            if subscriptions.count >= 2 {
                return "Stai pagando per spazio cloud su più servizi. Potresti consolidare tutto in uno?"
            }
        case .fitness:
            if subscriptions.count >= 2 {
                return "Più app fitness di quante ne usi probabilmente. Una sola app ben usata vale più di tre ignorate."
            }
        default:
            break
        }
        return nil
    }

    private func categoryInsightCard(insight: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)
                .font(.title3)

            Text(insight)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Subscriptions List

    private var subscriptionsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Abbonamenti")
                    .font(.headline)

                Spacer()

                Text("\(subscriptions.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray5))
                    )
            }

            ForEach(subscriptions) { subscription in
                NavigationLink(destination: SubscriptionDetailView(subscription: subscription)) {
                    subscriptionRow(subscription)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func subscriptionRow(_ subscription: Subscription) -> some View {
        HStack(spacing: 14) {
            ServiceLogoView(
                serviceName: subscription.serviceName,
                category: subscription.category,
                size: 44
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(subscription.billingCycle.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(subscription.cost.currencyFormatted)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(subscription.monthlyCost.currencyFormatted + "/mese")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Suggestion Card

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hand.point.right.fill")
                    .foregroundColor(.purple)

                Text("Il nostro consiglio")
                    .font(.headline)
            }

            Text(getSuggestion())
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Yearly cost highlight
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text("Costo annuale categoria")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text((totalAmount * 12).currencyFormatted)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(category.color)
                }
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.08))
        )
    }

    private func getSuggestion() -> String {
        let yearlyTotal = totalAmount * 12

        if subscriptions.count >= 3 {
            return "Con \(subscriptions.count) abbonamenti in questa categoria, prova a eliminarne almeno uno per un mese. Probabilmente non ti mancherà."
        } else if yearlyTotal > 200 {
            return "Spendi \(yearlyTotal.currencyFormatted) all'anno solo per \(category.displayName.lowercased()). Valuta se ogni servizio ti dà un valore proporzionato."
        } else {
            return "Rivedi periodicamente se questi servizi ti sono ancora utili. Le abitudini cambiano, gli abbonamenti dovrebbero seguire."
        }
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(
            category: .streaming,
            subscriptions: [
                Subscription(
                    serviceName: "Netflix",
                    cost: 12.99,
                    billingCycle: .monthly,
                    nextBillingDate: Date(),
                    category: .streaming
                ),
                Subscription(
                    serviceName: "Disney+",
                    cost: 8.99,
                    billingCycle: .monthly,
                    nextBillingDate: Date(),
                    category: .streaming
                )
            ],
            totalAmount: 21.98,
            percentage: 45.5
        )
    }
}
