//
//  ScanResultsView.swift
//  Subly
//
//  Vista per mostrare i risultati della scansione email
//

import SwiftUI

struct ScanResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @ObservedObject private var scanner = GmailScannerService.shared
    @ObservedObject private var storeManager = StoreManager.shared

    @State private var selectedSubscriptions: Set<UUID> = []
    @State private var isAdding = false
    @State private var showingSuccessAlert = false
    @State private var showingProUpgrade = false
    @State private var addedCount = 0

    // Limite per utenti free
    private let freeUserLimit = 3

    private var visibleSubscriptions: [DetectedSubscription] {
        let sorted = scanner.foundSubscriptions.sorted(by: { $0.confidence > $1.confidence })
        if storeManager.isPro {
            return sorted
        } else {
            return Array(sorted.prefix(freeUserLimit))
        }
    }

    private var hiddenCount: Int {
        if storeManager.isPro { return 0 }
        return max(0, scanner.foundSubscriptions.count - freeUserLimit)
    }

    var body: some View {
        NavigationStack {
            Group {
                if scanner.foundSubscriptions.isEmpty {
                    emptyState
                } else {
                    resultsList
                }
            }
            .navigationTitle(String(localized: "Abbonamenti trovati"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Chiudi")) {
                        dismiss()
                    }
                }

                if !scanner.foundSubscriptions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task {
                                await addSelectedSubscriptions()
                            }
                        } label: {
                            if isAdding {
                                ProgressView()
                            } else {
                                Text(String(localized: "Aggiungi (\(selectedSubscriptions.count))"))
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(selectedSubscriptions.isEmpty || isAdding)
                    }
                }
            }
            .alert(String(localized: "Abbonamenti aggiunti"), isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(String(localized: "\(addedCount) abbonamenti sono stati aggiunti con successo."))
            }
            .sheet(isPresented: $showingProUpgrade) {
                PaywallOnboardingView()
            }
            .onAppear {
                // Seleziona automaticamente quelli con alta confidenza (solo visibili)
                selectedSubscriptions = Set(
                    visibleSubscriptions
                        .filter { $0.isSelected }
                        .map { $0.id }
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(String(localized: "Nessun abbonamento trovato"))
                .font(.title2)
                .fontWeight(.semibold)

            Text(String(localized: "Non abbiamo trovato email di abbonamenti nelle tue ultime email. Prova a cercare più indietro o aggiungi manualmente."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                dismiss()
            } label: {
                Text(String(localized: "Chiudi"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.appPrimary)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            // Summary section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Trovati \(scanner.foundSubscriptions.count) abbonamenti"))
                            .font(.headline)

                        Text(String(localized: "Seleziona quelli da aggiungere"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        toggleSelectAll()
                    } label: {
                        Text(selectedSubscriptions.count == visibleSubscriptions.count ?
                             String(localized: "Deseleziona") :
                             String(localized: "Seleziona tutti"))
                            .font(.subheadline)
                    }
                }
            }

            // Subscriptions (limitati per utenti free)
            Section {
                ForEach(visibleSubscriptions) { subscription in
                    SubscriptionResultRow(
                        subscription: subscription,
                        isSelected: selectedSubscriptions.contains(subscription.id),
                        onToggle: {
                            toggleSelection(subscription.id)
                        }
                    )
                }
            } header: {
                Text(String(localized: "Abbonamenti"))
            } footer: {
                Text(String(localized: "Il livello di confidenza indica quanto siamo sicuri del rilevamento. Puoi modificare i dettagli dopo l'aggiunta."))
            }

            // Banner upgrade se ci sono risultati nascosti
            if hiddenCount > 0 {
                Section {
                    upgradePromoSection
                }
            }
        }
    }

    // MARK: - Upgrade Promo Section

    private var upgradePromoSection: some View {
        Button {
            showingProUpgrade = true
        } label: {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "+\(hiddenCount) abbonamenti nascosti"))
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(String(localized: "Passa a Pro per vedere tutti i risultati"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                }

                // Preview dei servizi nascosti (blurred)
                HStack(spacing: -8) {
                    ForEach(Array(scanner.foundSubscriptions
                        .sorted(by: { $0.confidence > $1.confidence })
                        .dropFirst(freeUserLimit)
                        .prefix(4)
                        .enumerated()), id: \.offset) { _, sub in
                        ServiceLogoView(
                            serviceName: sub.matchedService?.name ?? sub.serviceName,
                            category: sub.matchedService?.category ?? .other,
                            size: 32
                        )
                        .blur(radius: 3)
                        .opacity(0.7)
                    }

                    if hiddenCount > 4 {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray4))
                                .frame(width: 32, height: 32)

                            Text("+\(hiddenCount - 4)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func toggleSelection(_ id: UUID) {
        if selectedSubscriptions.contains(id) {
            selectedSubscriptions.remove(id)
        } else {
            selectedSubscriptions.insert(id)
        }
    }

    private func toggleSelectAll() {
        if selectedSubscriptions.count == visibleSubscriptions.count {
            selectedSubscriptions.removeAll()
        } else {
            selectedSubscriptions = Set(visibleSubscriptions.map { $0.id })
        }
    }

    private func addSelectedSubscriptions() async {
        isAdding = true

        let subscriptionsToAdd = scanner.foundSubscriptions.filter {
            selectedSubscriptions.contains($0.id)
        }

        for detected in subscriptionsToAdd {
            let subscription = detected.toSubscription()
            await viewModel.addSubscription(subscription)
        }

        addedCount = subscriptionsToAdd.count
        isAdding = false
        showingSuccessAlert = true
    }
}

// MARK: - Subscription Result Row

private struct SubscriptionResultRow: View {
    let subscription: DetectedSubscription
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .appPrimary : .secondary)

                // Service logo
                ServiceLogoView(
                    serviceName: subscription.matchedService?.name ?? subscription.serviceName,
                    category: subscription.matchedService?.category ?? .other,
                    size: 44
                )

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.serviceName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        if let cost = subscription.detectedCost {
                            Text(cost.currencyFormatted)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        if let cycle = subscription.detectedCycle {
                            Text("• \(cycle.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Source email
                    Text(extractEmailAddress(subscription.sourceEmail))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Confidence badge
                confidenceBadge
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var confidenceBadge: some View {
        Text(subscription.confidenceLevel)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(confidenceColor.opacity(0.15))
            .foregroundColor(confidenceColor)
            .cornerRadius(6)
    }

    private var confidenceColor: Color {
        switch subscription.confidence {
        case 0.8...1.0:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }

    private func extractEmailAddress(_ from: String) -> String {
        // Extract email from "Name <email@domain.com>"
        if let start = from.firstIndex(of: "<"),
           let end = from.firstIndex(of: ">") {
            return String(from[from.index(after: start)..<end])
        }
        return from
    }
}

#Preview {
    ScanResultsView()
        .environmentObject(SubscriptionViewModel())
}
