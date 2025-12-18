//
//  MinimalismView.swift
//  Subly
//
//  Pagina dedicata al minimalismo digitale con consigli e suggerimenti
//

import SwiftUI

struct MinimalismView: View {
    @EnvironmentObject var viewModel: SubscriptionViewModel
    private let insightService = InsightService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header motivazionale
                    headerSection

                    // Punteggio minimalismo
                    MinimalismScoreCard(
                        score: insightService.calculateMinimalismScore(
                            subscriptions: viewModel.subscriptions,
                            monthlyCost: viewModel.totalMonthlyCost
                        )
                    )

                    // Sezione "Cosa potresti fare"
                    if viewModel.totalYearlyCost >= 100 {
                        spendingAlternativesSection
                    }

                    // Tutti i consigli
                    allTipsSection

                    // Citazione finale
                    quoteSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "Minimalismo"))
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 44))
                .foregroundColor(.green)

            Text(String(localized: "Meno abbonamenti,\npiù libertà"))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(String(localized: "Il minimalismo digitale non significa rinunciare a tutto, ma scegliere consapevolmente cosa merita il tuo tempo e denaro."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Spending Alternatives Section

    private var spendingAlternativesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.green)

                Text(String(localized: "Con \(viewModel.totalYearlyCost.currencyFormatted)/anno potresti..."))
                    .font(.headline)
            }

            let comparisons = insightService.getSpendingComparisons(yearlyCost: viewModel.totalYearlyCost)

            VStack(spacing: 12) {
                ForEach(comparisons) { comparison in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(comparison.color.opacity(0.12))
                                .frame(width: 50, height: 50)

                            Image(systemName: comparison.icon)
                                .font(.system(size: 20))
                                .foregroundColor(comparison.color)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(comparison.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(comparison.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
            }
        }
    }

    // MARK: - All Tips Section

    private var allTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.green)

                Text(String(localized: "Consigli per il minimalismo digitale"))
                    .font(.headline)
            }

            ForEach(insightService.minimalismTips) { tip in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: tip.icon)
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(tip.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(tip.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
    }

    // MARK: - Quote Section

    private var quoteSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.title)
                .foregroundColor(.secondary.opacity(0.5))

            Text(String(localized: "La semplicità è la sofisticatezza suprema."))
                .font(.body)
                .italic()
                .multilineTextAlignment(.center)

            Text("— Leonardo da Vinci")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    MinimalismView()
        .environmentObject(SubscriptionViewModel())
}
