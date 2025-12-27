//
//  SubscriptionDetailView.swift
//  SublySwift
//
//  Vista dettaglio di un abbonamento
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
            VStack(spacing: 24) {
                // Header
                headerSection

                // Info Cards
                infoSection

                // Split Cost Section
                splitCostSection

                // Notes
                if let notes = subscription.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                }

                // Actions
                actionsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(subscription.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Modifica")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditSubscriptionView(subscription: subscription)
        }
        .alert("Elimina abbonamento", isPresented: $showingDeleteAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Elimina", role: .destructive) {
                deleteSubscription()
            }
        } message: {
            Text("Sei sicuro di voler eliminare \(subscription.displayName)? Questa azione non può essere annullata.")
        }
        .alert("Riattiva abbonamento", isPresented: $showingReactivateAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Riattiva") {
                reactivateSubscription()
            }
        } message: {
            Text("Vuoi riattivare \(subscription.displayName)?")
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
        HStack(spacing: 16) {
            // Logo
            ServiceLogoView(
                serviceName: subscription.serviceName,
                category: subscription.category,
                size: 56
            )

            // Name & Service
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.displayName)
                    .font(.headline)
                    .fontWeight(.bold)

                if subscription.customName != nil {
                    Text(subscription.serviceName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Status badge
                if !subscription.isActive {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancellato")
                    }
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.red))
                }
            }

            Spacer()

            // Price
            VStack(alignment: .trailing, spacing: 2) {
                Text(subscription.cost.currencyFormatted)
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Text(subscription.billingCycle.shortName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 12) {
            // Prossimo rinnovo
            InfoRow(
                icon: "calendar",
                iconColor: subscription.isRenewalSoon ? .orange : .blue,
                title: "Prossimo rinnovo",
                value: subscription.nextBillingDate.shortFormatted
            )

            Divider()

            // Costo mensile (normalizzato)
            InfoRow(
                icon: "creditcard.fill",
                iconColor: .green,
                title: "Costo mensile",
                value: subscription.monthlyCost.currencyFormatted
            )

            Divider()

            // Costo annuale
            InfoRow(
                icon: "calendar.badge.clock",
                iconColor: .purple,
                title: "Costo annuale",
                value: subscription.yearlyCost.currencyFormatted
            )

            Divider()

            // Categoria
            InfoRow(
                icon: subscription.category.iconName,
                iconColor: subscription.category.color,
                title: "Categoria",
                value: subscription.category.displayName
            )

            if subscription.isEssential {
                Divider()

                InfoRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Tipo",
                    value: "Abbonamento essenziale"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Notes Section

    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Note", systemImage: "note.text")
                .font(.headline)

            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Split Cost Section

    private var splitCostSection: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Label("Dividi il costo", systemImage: "person.2.fill")
                    .font(.headline)

                Spacer()

                if subscription.isShared {
                    Text("\(subscription.sharedWith ?? 1) persone")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.green))
                }
            }

            // Split info card
            VStack(spacing: 16) {
                if subscription.isShared {
                    // Already shared - show split details
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Costo totale")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(subscription.cost.currencyFormatted)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("La tua quota")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(subscription.perPersonCost.currencyFormatted)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }

                    Divider()

                    // Request payment button
                    Button {
                        showingShareSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Invia richiesta pagamento")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SplitPaymentButtonStyle())
                } else {
                    // Not shared - show option to split
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 50, height: 50)

                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Condividi questo abbonamento?")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("Dividi il costo con amici o familiari")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    Button {
                        splitPeopleCount = 2
                        showingSplitSheet = true
                    } label: {
                        Text("Imposta divisione")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - Split Cost Sheet

    private var splitCostSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Visual
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 80, height: 80)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                }
                .padding(.top, 32)

                // Title
                Text("Con quante persone dividi \(subscription.displayName)?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Stepper
                VStack(spacing: 8) {
                    HStack {
                        Button {
                            if splitPeopleCount > 2 {
                                splitPeopleCount -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(splitPeopleCount > 2 ? .appPrimary : .gray)
                        }
                        .disabled(splitPeopleCount <= 2)

                        Text("\(splitPeopleCount)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .frame(width: 100)

                        Button {
                            if splitPeopleCount < 10 {
                                splitPeopleCount += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(splitPeopleCount < 10 ? .appPrimary : .gray)
                        }
                        .disabled(splitPeopleCount >= 10)
                    }

                    Text("persone (incluso te)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Cost preview
                VStack(spacing: 8) {
                    Text("Ognuno paga")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text((subscription.cost / Double(splitPeopleCount)).currencyFormatted)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.green)

                    Text("invece di \(subscription.cost.currencyFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.1))
                )
                .padding(.horizontal)

                Spacer()

                // Save button
                Button {
                    saveSplitSetting()
                } label: {
                    Text("Salva")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Dividi costo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        showingSplitSheet = false
                    }
                }

                if subscription.isShared {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Rimuovi") {
                            removeSplitSetting()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .presentationDetents([.height(560)])
        .presentationBackground(Color(.systemBackground))
        .presentationDragIndicator(.visible)
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

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Cancellation URL - prominent blue button
            if let urlString = ServiceCatalog.findCancellationURL(forService: subscription.serviceName),
               let url = URL(string: urlString) {

                // Helpful message
                HStack(spacing: 10) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.blue)

                    Text("Ti aiutiamo noi a cancellare questo servizio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

                Link(destination: url) {
                    HStack {
                        Image(systemName: "arrow.up.right.square.fill")
                        Text("Vai alla pagina di cancellazione")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(CancellationButtonStyle())
            }

            // Reactivate or Delete
            if subscription.isActive {
                Button {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Rimuovi da Subly")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            } else {
                Button {
                    showingReactivateAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Riattiva abbonamento")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
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

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var badge: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }

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
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
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
