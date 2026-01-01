//
//  ProUpgradeView.swift
//  Subly
//
//  Vista per l'upgrade a Subly Pro
//

import SwiftUI

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager.shared

    @State private var isPurchasing = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Benefits
                    benefitsSection

                    // Price
                    priceSection

                    // Purchase Button
                    purchaseButton

                    // Restore
                    restoreButton

                    // Footer
                    footerText
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "Subly Pro"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
            .alert(String(localized: "Acquisto completato!"), isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(String(localized: "Grazie per aver acquistato Subly Pro! Tutte le funzionalità sono ora sbloccate."))
            }
            .alert(String(localized: "Errore"), isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(storeManager.errorMessage ?? String(localized: "Si è verificato un errore"))
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Pro Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            .shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 10)

            Text(String(localized: "Subly Pro"))
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(String(localized: "Sblocca tutte le funzionalità"))
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: 16) {
            BenefitRow(
                icon: "mail.and.text.magnifyingglass",
                iconColor: .blue,
                title: String(localized: "Scansione Email Completa"),
                description: String(localized: "Trova tutti gli abbonamenti dalle tue email")
            )

            BenefitRow(
                icon: "nosign",
                iconColor: .red,
                title: String(localized: "Nessuna pubblicità"),
                description: String(localized: "Mai più interruzioni mentre usi l'app")
            )

            BenefitRow(
                icon: "square.grid.2x2",
                iconColor: .purple,
                title: String(localized: "Widget Home Screen"),
                description: String(localized: "Monitora le spese dalla schermata Home")
            )

            BenefitRow(
                icon: "infinity",
                iconColor: .orange,
                title: String(localized: "Per sempre"),
                description: String(localized: "Paghi una volta sola, nessun abbonamento")
            )

            BenefitRow(
                icon: "heart.fill",
                iconColor: .pink,
                title: String(localized: "Supporta lo sviluppatore"),
                description: String(localized: "Aiutami a migliorare Subly")
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(spacing: 8) {
            Text(storeManager.formattedPrice)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.appPrimary)

            Text(String(localized: "pagamento unico"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                isPurchasing = true
                let success = await storeManager.purchase()
                isPurchasing = false

                if success {
                    showSuccessAlert = true
                } else if storeManager.errorMessage != nil {
                    showErrorAlert = true
                }
            }
        } label: {
            HStack {
                if isPurchasing || storeManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "crown.fill")
                    Text(String(localized: "Acquista Subly Pro"))
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.appPrimary, .appSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(isPurchasing || storeManager.isLoading)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task {
                await storeManager.restorePurchases()

                if storeManager.isPro {
                    showSuccessAlert = true
                } else if storeManager.errorMessage != nil {
                    showErrorAlert = true
                }
            }
        } label: {
            Text(String(localized: "Ripristina acquisti"))
                .font(.subheadline)
                .foregroundColor(.appPrimary)
        }
    }

    // MARK: - Footer Text

    private var footerText: some View {
        Text(String(localized: "L'acquisto viene addebitato sul tuo account Apple. Subly Pro è un acquisto una tantum, non un abbonamento."))
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    ProUpgradeView()
}
