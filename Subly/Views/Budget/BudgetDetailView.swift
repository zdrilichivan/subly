//
//  BudgetDetailView.swift
//  SublySwift
//
//  Vista dettagliata del budget
//

import SwiftUI

struct BudgetDetailView: View {
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @StateObject private var budgetService = BudgetService.shared

    @State private var showingEditSheet = false
    @State private var budgetLimitText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main Status Card
                if let status = viewModel.budgetStatus {
                    mainStatusCard(status: status)
                } else {
                    noBudgetCard
                }

                // Category Breakdown
                if viewModel.budgetStatus != nil {
                    categoryBreakdownSection
                }

                // Expensive Subscriptions
                let expensive = viewModel.getExpensiveSubscriptions()
                if expensive.isNotEmpty {
                    expensiveSubscriptionsSection(subscriptions: expensive)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Budget")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    budgetLimitText = budgetService.settings.monthlyLimit.map { String(format: "%.2f", $0) } ?? ""
                    showingEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            budgetEditSheet
        }
    }

    // MARK: - Main Status Card

    private func mainStatusCard(status: BudgetStatus) -> some View {
        VStack(spacing: 24) {
            // Circular Progress
            CircularBudgetProgress(
                percentage: status.percentage,
                color: status.statusColor,
                lineWidth: 14,
                size: 160
            )

            // Amounts
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Speso")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(status.current.currencyFormatted)
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(status.limit.currencyFormatted)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }

                // Progress Bar
                BudgetProgressView(percentage: status.percentage, color: status.statusColor, height: 12)

                // Status Text
                HStack {
                    Image(systemName: statusIcon(for: status.status))
                        .foregroundColor(status.statusColor)
                    Text(status.statusText)
                        .font(.subheadline)
                        .foregroundColor(status.statusColor)
                }
            }
        }
        .cardStyle()
    }

    private func statusIcon(for status: BudgetStatusLevel) -> String {
        switch status {
        case .safe:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .exceeded:
            return "xmark.circle.fill"
        }
    }

    // MARK: - No Budget Card

    private var noBudgetCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Nessun budget impostato")
                .font(.headline)

            Text("Imposta un budget mensile per tenere sotto controllo le tue spese")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingEditSheet = true
            } label: {
                Text("Imposta budget")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Category Breakdown Section

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ripartizione per categoria")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(sortedCategories, id: \.category) { item in
                    VStack(spacing: 0) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(item.category.color.opacity(0.1))
                                    .frame(width: 36, height: 36)

                                Image(systemName: item.category.iconName)
                                    .font(.system(size: 14))
                                    .foregroundColor(item.category.color)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.category.displayName)
                                    .font(.subheadline)

                                Text("\(item.count) abbonamenti")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(item.amount.currencyFormatted)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(item.percentage.percentageFormatted)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 12)

                        if item.category != sortedCategories.last?.category {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
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

    // MARK: - Expensive Subscriptions Section

    private func expensiveSubscriptionsSection(subscriptions: [Subscription]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Abbonamenti più costosi", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                ForEach(subscriptions.prefix(5)) { subscription in
                    NavigationLink(destination: SubscriptionDetailView(subscription: subscription)) {
                        HStack {
                            ServiceLogoView(
                                serviceName: subscription.serviceName,
                                category: subscription.category,
                                size: 40
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(subscription.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                Text(subscription.category.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(subscription.monthlyCost.currencyFormatted)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Text("/mese")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Budget Edit Sheet

    private var budgetEditSheet: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("€")
                            .foregroundColor(.secondary)

                        TextField("0,00", text: $budgetLimitText)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Limite mensile")
                } footer: {
                    Text("Spesa attuale: \(viewModel.totalMonthlyCost.currencyFormatted)/mese")
                }

                Section {
                    Picker("Soglia alert", selection: Binding(
                        get: { budgetService.settings.notifyAtPercentage },
                        set: { budgetService.updateNotifyPercentage($0) }
                    )) {
                        Text("50%").tag(50.0)
                        Text("60%").tag(60.0)
                        Text("70%").tag(70.0)
                        Text("80%").tag(80.0)
                        Text("90%").tag(90.0)
                    }
                } header: {
                    Text("Alert")
                }

                if budgetService.settings.hasLimit {
                    Section {
                        Button(role: .destructive) {
                            budgetService.updateBudgetLimit(nil)
                            showingEditSheet = false
                        } label: {
                            Text("Rimuovi budget")
                        }
                    }
                }
            }
            .navigationTitle("Imposta budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        showingEditSheet = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveBudget()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func saveBudget() {
        let value = Double(budgetLimitText.replacingOccurrences(of: ",", with: "."))
        budgetService.updateBudgetLimit(value)
        showingEditSheet = false
        Haptic.notification(.success)
    }
}

#Preview {
    NavigationStack {
        BudgetDetailView()
    }
    .environmentObject(SubscriptionViewModel())
}
