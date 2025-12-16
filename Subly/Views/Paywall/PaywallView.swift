//
//  PaywallView.swift
//  Subly
//
//  Vista per l'acquisto della versione completa
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeService = StoreService.shared
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Cosa ottieni
                    featuresSection

                    // Messaggio personale
                    personalMessageSection

                    // Prezzo e pulsante acquisto
                    purchaseSection

                    // Ripristina acquisti
                    restoreButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sblocca Subly")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
            .alert("Ripristino acquisti", isPresented: $showingRestoreAlert) {
                Button("OK") {
                    if storeService.isUnlocked {
                        dismiss()
                    }
                }
            } message: {
                Text(restoreMessage)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 100, height: 100)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }

            Text("Hai raggiunto il limite")
                .font(.title2)
                .fontWeight(.bold)

            Text("La versione gratuita permette di tracciare fino a \(StoreService.freeLimit) abbonamenti. Sblocca Subly per sempre con un piccolo contributo!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cosa ottieni:")
                .font(.headline)

            FeatureRow(icon: "infinity", color: .blue, title: "Abbonamenti illimitati", description: "Traccia tutti i tuoi abbonamenti senza limiti")

            FeatureRow(icon: "bell.fill", color: .orange, title: "Notifiche intelligenti", description: "Promemoria prima di ogni rinnovo")

            FeatureRow(icon: "hand.raised.fill", color: .green, title: "Aiuto cancellazione", description: "Link diretti per disdire facilmente")

            FeatureRow(icon: "icloud.fill", color: .cyan, title: "Sync iCloud", description: "I tuoi dati su tutti i dispositivi")

            FeatureRow(icon: "heart.fill", color: .pink, title: "Supporti lo sviluppo", description: "Aiuti a migliorare l'app nel tempo")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Personal Message Section

    private var personalMessageSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundColor(.secondary.opacity(0.5))

            Text("Ho creato Subly per aiutarti a vivere con meno abbonamenti e più consapevolezza. Il prezzo di un caffè mi permette di continuare a sviluppare e migliorare l'app.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .italic()

            Text("— Ivan, sviluppatore di Subly")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.08))
        )
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        VStack(spacing: 16) {
            // Prezzo
            if let product = storeService.product {
                VStack(spacing: 4) {
                    Text(product.displayPrice)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.green)

                    Text("Una tantum, per sempre")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if let error = storeService.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ProgressView()
                    .padding()
            }

            // Pulsante acquisto
            Button {
                Task {
                    let success = await storeService.purchase()
                    if success {
                        dismiss()
                    }
                }
            } label: {
                HStack {
                    if storeService.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "lock.open.fill")
                        Text("Sblocca Subly")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryGreenButtonStyle())
            .disabled(storeService.product == nil || storeService.isPurchasing)

            // Errore
            if let error = storeService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task {
                let success = await storeService.restorePurchases()
                restoreMessage = success ? "Acquisto ripristinato con successo!" : (storeService.errorMessage ?? "Nessun acquisto trovato")
                showingRestoreAlert = true
            }
        } label: {
            Text("Hai già acquistato? Ripristina")
                .font(.subheadline)
                .foregroundColor(.appPrimary)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Primary Green Button Style

struct PrimaryGreenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.green)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    PaywallView()
}
