//
//  SubscriptionDetailView.swift
//  SublySwift
//
//  Vista dettaglio di un abbonamento - Design compatto
//

import SwiftUI

struct SubscriptionDetailView: View {
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss

    let subscription: Subscription

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingReactivateAlert = false
    @State private var showingSplitSheet = false
    @State private var showingShareSheet = false
    @State private var splitPeopleCount: Int = 2

    var body: some View {
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

                VStack(spacing: Spacing.md) {
                    // Custom Header
                    headerSection

                    // Header con logo, nome e prezzo
                    compactHeader

                    // Info Grid - costo mensile e annuale
                    infoGrid

                    // Categoria
                    categoryRow

                    // Split Cost - divisione costi
                    splitCostRow

                    // Notes (conditional)
                    if let notes = subscription.notes, !notes.isEmpty {
                        compactNotesSection(notes: notes)
                    }

                    // Spacer per separare azioni
                    Spacer()
                        .frame(height: Spacing.lg)

                    // Actions
                    compactActionsSection
                }
                .padding(Spacing.md)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text(String(localized: "Modifica"))
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditSubscriptionView(subscription: subscription)
        }
        .alert(String(localized: "Elimina abbonamento"), isPresented: $showingDeleteAlert) {
            Button(String(localized: "Annulla"), role: .cancel) { }
            Button(String(localized: "Elimina"), role: .destructive) {
                deleteSubscription()
            }
        } message: {
            Text(String(localized: "Sei sicuro di voler eliminare \(subscription.displayName)? Questa azione non può essere annullata."))
        }
        .alert(String(localized: "Riattiva abbonamento"), isPresented: $showingReactivateAlert) {
            Button(String(localized: "Annulla"), role: .cancel) { }
            Button(String(localized: "Riattiva")) {
                reactivateSubscription()
            }
        } message: {
            Text(String(localized: "Vuoi riattivare \(subscription.displayName)?"))
        }
        .sheet(isPresented: $showingSplitSheet) {
            splitCostSheet
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareMessage])
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "Dettagli"))
                .font(Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)

            Text(subscription.displayName)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        HStack(spacing: Spacing.sm) {
            // Logo - smaller
            ServiceLogoView(
                serviceName: subscription.serviceName,
                category: subscription.category,
                size: 48
            )

            // Name & Service
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(subscription.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)

                    // Status badge inline
                    if !subscription.isActive {
                        Text(String(localized: "Cancellato"))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red))
                    }
                }

                if subscription.customName != nil {
                    Text(subscription.serviceName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Price - compact
            VStack(alignment: .trailing, spacing: 0) {
                Text(subscription.cost.currencyFormatted)
                    .font(Typography.numericMedium(20))

                Text(subscription.billingCycle.shortName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Info Grid

    private var infoGrid: some View {
        HStack(spacing: Spacing.sm) {
            // Costo mensile
            LargeInfoCell(
                icon: "creditcard.fill",
                iconColor: .green,
                label: String(localized: "Spesa mensile"),
                value: subscription.monthlyCost.currencyFormatted
            )

            // Costo annuale
            LargeInfoCell(
                icon: "calendar.badge.clock",
                iconColor: .purple,
                label: String(localized: "Spesa annuale"),
                value: subscription.yearlyCost.currencyFormatted
            )
        }
    }

    // MARK: - Category Row

    private var categoryRow: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            IconContainer(
                systemName: subscription.category.iconName,
                size: IconContainerSize.sm,
                color: subscription.category.color,
                backgroundOpacity: IconBackgroundOpacity.medium
            )

            // Label
            Text(String(localized: "Categoria"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            // Value
            Text(subscription.category.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Split Cost Row (Compact)

    private var splitCostRow: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            IconContainer(
                systemName: "person.2.fill",
                size: IconContainerSize.sm,
                color: .green,
                backgroundOpacity: IconBackgroundOpacity.medium
            )

            // Label
            VStack(alignment: .leading, spacing: 0) {
                Text(String(localized: "Dividi il costo"))
                    .font(.subheadline)
                    .fontWeight(.medium)

                if subscription.isShared {
                    Text(String(localized: "Quota: \(subscription.perPersonCost.currencyFormatted)"))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            if subscription.isShared {
                // Show split details and share button
                HStack(spacing: Spacing.xs) {
                    Text(String(localized: "\(subscription.sharedWith ?? 1) pers."))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.green))

                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }

                    Button {
                        splitPeopleCount = subscription.sharedWith ?? 2
                        showingSplitSheet = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Toggle or button to enable split
                Button {
                    splitPeopleCount = 2
                    showingSplitSheet = true
                } label: {
                    Text(String(localized: "Imposta"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(Color.green, lineWidth: 1.5)
                        )
                }
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Split Cost Sheet

    private var splitCostSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // Visual
                IconContainer(
                    systemName: "person.2.fill",
                    size: IconContainerSize.xl,
                    color: .green,
                    backgroundOpacity: IconBackgroundOpacity.medium
                )
                .padding(.top, Spacing.lg)

                // Title
                Text(String(localized: "Con quante persone dividi \(subscription.displayName)?"))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Stepper
                VStack(spacing: Spacing.xs) {
                    HStack {
                        Button {
                            if splitPeopleCount > 2 {
                                splitPeopleCount -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(splitPeopleCount > 2 ? .appPrimary : .gray)
                        }
                        .disabled(splitPeopleCount <= 2)

                        Text("\(splitPeopleCount)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .frame(width: 80)

                        Button {
                            if splitPeopleCount < 10 {
                                splitPeopleCount += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(splitPeopleCount < 10 ? .appPrimary : .gray)
                        }
                        .disabled(splitPeopleCount >= 10)
                    }

                    Text(String(localized: "persone (incluso te)"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Cost preview
                VStack(spacing: Spacing.xs) {
                    Text(String(localized: "Ognuno paga"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text((subscription.cost / Double(splitPeopleCount)).currencyFormatted)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.green)

                    Text(String(localized: "invece di \(subscription.cost.currencyFormatted)"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.green.opacity(0.1))
                )
                .padding(.horizontal)

                Spacer()

                // Save button
                Button {
                    saveSplitSetting()
                } label: {
                    Text(String(localized: "Salva"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, Spacing.md)
            }
            .navigationTitle(String(localized: "Dividi costo"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Annulla")) {
                        showingSplitSheet = false
                    }
                }

                if subscription.isShared {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(String(localized: "Rimuovi")) {
                            removeSplitSetting()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .presentationDetents([.height(480)])
        .presentationBackground(Color(.systemBackground))
        .presentationDragIndicator(.visible)
    }

    // MARK: - Compact Notes Section

    private func compactNotesSection(notes: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "note.text")
                .font(.system(size: 14))
                .foregroundColor(.orange)

            Text(notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            Spacer()
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Share Message

    private var shareMessage: String {
        let perPerson = subscription.perPersonCost
        return """
        Ciao! Mi devi \(perPerson.currencyFormatted) per \(subscription.displayName) di questo mese.

        Costo totale: \(subscription.cost.currencyFormatted)
        Diviso tra: \(subscription.sharedWith ?? 1) persone
        Quota a testa: \(perPerson.currencyFormatted)

        Calcolato con Subly - L'app per gestire gli abbonamenti
        """
    }

    // MARK: - Split Actions

    private func saveSplitSetting() {
        Task {
            var updatedSubscription = subscription
            updatedSubscription.sharedWith = splitPeopleCount
            await viewModel.updateSubscription(updatedSubscription)
            showingSplitSheet = false
        }
    }

    private func removeSplitSetting() {
        Task {
            var updatedSubscription = subscription
            updatedSubscription.sharedWith = nil
            await viewModel.updateSubscription(updatedSubscription)
            showingSplitSheet = false
        }
    }

    // MARK: - Compact Actions Section

    private var compactActionsSection: some View {
        VStack(spacing: Spacing.sm) {
            // Cancellation URL - compact link style
            if let urlString = ServiceCatalog.findCancellationURL(forService: subscription.serviceName),
               let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 16, weight: .medium))

                        Text(String(localized: "Vai alla pagina di cancellazione"))
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.blue)
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }

            // Reactivate or Delete - compact text button
            if subscription.isActive {
                Button {
                    showingDeleteAlert = true
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text(String(localized: "Rimuovi da Subly"))
                            .font(.subheadline)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                }
            } else {
                Button {
                    showingReactivateAlert = true
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text(String(localized: "Riattiva abbonamento"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.appPrimary)
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func deleteSubscription() {
        Task {
            await viewModel.deleteSubscription(subscription)
            dismiss()
        }
    }

    private func reactivateSubscription() {
        Task {
            await viewModel.reactivateSubscription(subscription)
            dismiss()
        }
    }
}

// MARK: - Large Info Cell

struct LargeInfoCell: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(IconBackgroundOpacity.medium))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Value
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Label
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Compact Info Cell

struct CompactInfoCell: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Icon - small
            ZStack {
                Circle()
                    .fill(iconColor.opacity(IconBackgroundOpacity.medium))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Value
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Label
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Info Row (kept for backwards compatibility)

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var badge: String?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            IconContainer(
                systemName: icon,
                size: IconContainerSize.sm,
                color: iconColor,
                backgroundOpacity: IconBackgroundOpacity.medium
            )

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            if let badge = badge {
                Text(badge)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(iconColor))
            }

            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Split Payment Button Style

struct SplitPaymentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.green)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

#Preview {
    NavigationStack {
        SubscriptionDetailView(
            subscription: Subscription(
                serviceName: "Netflix",
                cost: 12.99,
                billingCycle: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
                notes: "Account familiare condiviso con fratello",
                category: .streaming,
                sharedWith: 4
            )
        )
    }
    .environmentObject(SubscriptionViewModel())
}
