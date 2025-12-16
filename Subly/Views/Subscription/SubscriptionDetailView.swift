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

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Info Cards
                infoSection

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
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo
            ServiceLogoView(
                serviceName: subscription.serviceName,
                category: subscription.category,
                size: 80
            )

            // Name
            VStack(spacing: 4) {
                Text(subscription.displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                if subscription.customName != nil {
                    Text(subscription.serviceName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Status badge
            if !subscription.isActive {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Cancellato")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.red))
            }

            // Price
            VStack(spacing: 4) {
                Text(subscription.cost.currencyFormatted)
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                Text(subscription.billingCycle.shortName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10)
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
                value: subscription.nextBillingDate.shortFormatted,
                badge: subscription.renewalText
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
                .fill(Color(.systemBackground))
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
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Cancellation URL - prominent blue button
            if let service = ServiceCatalog.find(byName: subscription.serviceName),
               let urlString = service.cancellationURL,
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

#Preview {
    NavigationStack {
        SubscriptionDetailView(
            subscription: Subscription(
                serviceName: "Netflix",
                cost: 12.99,
                billingCycle: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
                notes: "Account familiare condiviso con fratello",
                category: .streaming
            )
        )
    }
    .environmentObject(SubscriptionViewModel())
}
