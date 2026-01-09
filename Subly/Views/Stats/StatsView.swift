//
//  StatsView.swift
//  SublySwift
//
//  Vista statistiche con analisi spese per categoria
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @ObservedObject private var storeManager = StoreManager.shared
    @State private var showingProUpgrade = false

    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack(alignment: .top) {
                    // Gradient che scrolla con i contenuti
                    LinearGradient(
                        colors: [
                            Color(red: 0.35, green: 0.40, blue: 0.65),
                            Color(red: 0.12, green: 0.14, blue: 0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 380)
                    .frame(maxWidth: .infinity)
                    .offset(y: -220)

                    VStack(spacing: 20) {
                        // Custom Header
                        headerSection

                        // Overview Stats (disponibile a tutti)
                        overviewSection

                        if storeManager.isPro {
                            // PRO: Statistiche avanzate

                            // Grafico spese per categoria
                            if viewModel.activeSubscriptions.isNotEmpty {
                                categoryChartSection
                            }

                            // Proiezioni future (Pro only)
                            projectionsSection

                            // Budget Status Card
                            if let budgetStatus = viewModel.budgetStatus {
                                budgetStatusCard(status: budgetStatus)
                            }

                            // Category Breakdown
                            categoryBreakdownSection

                            // Saving Suggestions
                            let suggestions = viewModel.getSavingSuggestions()
                            if suggestions.isNotEmpty {
                                suggestionsSection(suggestions: suggestions)
                            }
                        } else {
                            // FREE: Promo per sbloccare statistiche avanzate
                            statsPromoCard
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
            .sheet(isPresented: $showingProUpgrade) {
                PaywallOnboardingView()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formattedDate)
                .font(Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)

            Text(String(localized: "Statistiche"))
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Spacing.sm)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: Date()).uppercased()
    }

    // MARK: - Category Chart Section

    private var categoryChartSection: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Text(String(localized: "Spese per categoria"))
                    .font(.headline)
                Spacer()
            }

            // Donut chart
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 24)
                    .frame(width: 160, height: 160)

                // Category segments
                ForEach(Array(chartSegments.enumerated()), id: \.element.category) { _, segment in
                    Circle()
                        .trim(from: segment.startAngle, to: segment.endAngle)
                        .stroke(segment.category.color, style: StrokeStyle(lineWidth: 24, lineCap: .butt))
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                }

                // Center text
                VStack(spacing: 4) {
                    Text(viewModel.totalMonthlyCost.currencyFormatted)
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Text(String(localized: "al mese"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 180)

            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(sortedCategories.prefix(6), id: \.category) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.category.color)
                            .frame(width: 10, height: 10)

                        Text(item.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Spacer()

                        Text("\(Int(item.percentage))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var chartSegments: [(category: ServiceCategory, startAngle: CGFloat, endAngle: CGFloat)] {
        var segments: [(category: ServiceCategory, startAngle: CGFloat, endAngle: CGFloat)] = []
        var currentAngle: CGFloat = 0

        for item in sortedCategories {
            let segmentSize = CGFloat(item.percentage / 100)
            segments.append((
                category: item.category,
                startAngle: currentAngle,
                endAngle: currentAngle + segmentSize
            ))
            currentAngle += segmentSize
        }

        return segments
    }

    // MARK: - Budget Status Card

    private func budgetStatusCard(status: BudgetStatus) -> some View {
        NavigationLink(destination: BudgetDetailView()) {
            VStack(spacing: 16) {
                HStack {
                    CircularBudgetProgress(
                        percentage: status.percentage,
                        color: status.statusColor,
                        size: 80
                    )

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(localized: "Spesa attuale"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(status.current.currencyFormatted)
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(localized: "Budget"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(status.limit.currencyFormatted)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                HStack {
                    Text(status.statusText)
                        .font(.subheadline)
                        .foregroundColor(status.statusColor)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .cardStyle()
        }
        .buttonStyle(StatCardButtonStyle())
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Panoramica"))
                .font(.headline)

            HStack(spacing: 12) {
                // Card combinata: Abbonamenti + Categorie
                HStack(spacing: 16) {
                    // Abbonamenti
                    VStack(spacing: 4) {
                        Text("\(viewModel.activeSubscriptions.count)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.appPrimary)
                        Text(String(localized: "Abbonamenti"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()
                        .frame(height: 40)

                    // Categorie
                    VStack(spacing: 4) {
                        Text("\(viewModel.spendingByCategory.count)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Text(String(localized: "Categorie"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

                // Spesa annuale
                VStack(spacing: 4) {
                    Text(viewModel.totalYearlyCost.currencyFormatted)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)
                    Text(String(localized: "Spesa annuale"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
    }

    // MARK: - Category Breakdown Section

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Dettaglio categorie"))
                .font(.headline)

            VStack(spacing: 4) {
                ForEach(sortedCategories, id: \.category) { item in
                    NavigationLink(destination: CategoryDetailView(
                        category: item.category,
                        subscriptions: subscriptionsForCategory(item.category),
                        totalAmount: item.amount,
                        percentage: item.percentage
                    )) {
                        CategoryRow(
                            category: item.category,
                            amount: item.amount,
                            count: item.count,
                            percentage: item.percentage
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Divider between rows (except last)
                    if item.category != sortedCategories.last?.category {
                        Divider()
                            .padding(.leading, 58)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private var sortedCategories: [(category: ServiceCategory, amount: Double, count: Int, percentage: Double)] {
        let spending = viewModel.spendingByCategory
        let counts = viewModel.subscriptionCountByCategory
        let total = viewModel.totalMonthlyCost

        return spending
            .map { (category: $0.key, amount: $0.value, count: counts[$0.key] ?? 0, percentage: total > 0 ? ($0.value / total) * 100 : 0) }
            .sorted { $0.amount > $1.amount }
    }

    private func subscriptionsForCategory(_ category: ServiceCategory) -> [Subscription] {
        viewModel.subscriptions.filter { $0.category == category && $0.isActive }
    }

    // MARK: - Suggestions Section

    private func suggestionsSection(suggestions: [SavingSuggestion]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Suggerimenti"), systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                ForEach(suggestions.prefix(3)) { suggestion in
                    HStack(spacing: 12) {
                        Image(systemName: suggestionIcon(for: suggestion.type))
                            .font(.title3)
                            .foregroundColor(.orange)
                            .frame(width: 30)

                        Text(suggestion.message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
        }
    }

    private func suggestionIcon(for type: SavingSuggestion.SuggestionType) -> String {
        switch type {
        case .expensive:
            return "exclamationmark.triangle.fill"
        case .categoryHigh:
            return "chart.bar.fill"
        case .unused:
            return "questionmark.circle.fill"
        }
    }

    // MARK: - Projections Section (Pro Only)

    private var projectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Proiezioni future"), systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundColor(.purple)

            VStack(spacing: 8) {
                ForEach(projectedCosts, id: \.years) { projection in
                    HStack {
                        Text(String(localized: "Tra \(projection.years) anni"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(projection.amount.currencyFormatted)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                }
            }

            Text(String(localized: "Basato sulla tua spesa mensile attuale di \(viewModel.totalMonthlyCost.currencyFormatted)"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var projectedCosts: [(years: Int, amount: Double)] {
        let monthly = viewModel.totalMonthlyCost
        return [
            (2, monthly * 12 * 2),
            (3, monthly * 12 * 3),
            (5, monthly * 12 * 5)
        ]
    }

    // MARK: - Stats Promo Card (Free Users)

    private var statsPromoCard: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Text
            VStack(spacing: 8) {
                Text(String(localized: "Statistiche Avanzate"))
                    .font(.title3)
                    .fontWeight(.bold)

                Text(String(localized: "Sblocca grafici dettagliati, proiezioni future e suggerimenti di risparmio personalizzati."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // Features
            VStack(alignment: .leading, spacing: 10) {
                ProFeatureRow(icon: "chart.pie.fill", text: String(localized: "Grafico spese per categoria"))
                ProFeatureRow(icon: "chart.line.uptrend.xyaxis", text: String(localized: "Proiezioni 2-5 anni"))
                ProFeatureRow(icon: "lightbulb.fill", text: String(localized: "Suggerimenti di risparmio"))
                ProFeatureRow(icon: "target", text: String(localized: "Monitoraggio budget"))
            }

            // CTA Button
            Button {
                showingProUpgrade = true
                Haptic.impact(.medium)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.subheadline)
                    Text(String(localized: "Sblocca con Pro"))
                        .fontWeight(.semibold)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.appPrimary, .appSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Pro Feature Row

private struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.purple)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: ServiceCategory
    let amount: Double
    let count: Int
    let percentage: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: category.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(category.color)
                }

                // Name and count
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(count == 1 ? String(localized: "1 abbonamento") : String(localized: "\(count) abbonamenti"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text(amount.currencyFormatted)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(String(localized: "/mese"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(Color(.tertiaryLabel))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(category.color)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    StatsView()
        .environmentObject(SubscriptionViewModel())
}
