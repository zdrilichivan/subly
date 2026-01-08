//
//  PaywallOnboardingView.swift
//  Subly
//
//  Paywall mostrato alla fine dell'onboarding
//

import SwiftUI

struct PaywallOnboardingView: View {
    // Per uso in onboarding
    @Binding var hasCompletedOnboarding: Bool

    // Per uso come sheet
    @Environment(\.dismiss) private var dismiss
    var isSheet: Bool = false

    @StateObject private var storeManager = StoreManager.shared

    @State private var isPurchasing = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false

    // Inizializzatore per onboarding
    init(hasCompletedOnboarding: Binding<Bool>) {
        self._hasCompletedOnboarding = hasCompletedOnboarding
        self.isSheet = false
    }

    // Inizializzatore per sheet (impostazioni)
    init() {
        self._hasCompletedOnboarding = .constant(false)
        self.isSheet = true
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header con X per chiudere
                HStack {
                    Spacer()
                    Button {
                        completeOnboarding()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, geometry.safeAreaInsets.top + 8)

                // Logo/Icon
                headerSection
                    .padding(.top, 8)

                Spacer()
                    .frame(height: 20)

                // Benefits list
                benefitsSection
                    .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 20)

                // Plan cards
                planCardsSection
                    .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 12)

                // Free trial toggle
                freeTrialToggle
                    .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 10)

                // Disclosure text (Apple compliance)
                disclosureText
                    .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 12)

                // Bottom section
                VStack(spacing: 10) {
                    purchaseButton

                    footerLinks
                }
                .padding(.horizontal, 24)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea()
        .alert(String(localized: "Abbonamento attivato!"), isPresented: $showSuccessAlert) {
            Button("OK") {
                completeOnboarding()
            }
        } message: {
            Text(String(localized: "Grazie per aver scelto Subly Pro! Tutte le funzionalita sono ora sbloccate."))
        }
        .alert(String(localized: "Errore"), isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(storeManager.errorMessage ?? String(localized: "Si e verificato un errore"))
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            // App Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.appPrimary.opacity(0.2), .appSecondary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.appPrimary, .appSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 10, x: 0, y: 4)

                Image(systemName: "crown.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(String(localized: "Sblocca tutto il potenziale"))
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(String(localized: "Prendi il controllo dei tuoi abbonamenti"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: 12) {
            PaywallBenefitRow(
                icon: "sparkles",
                iconColor: .blue,
                title: String(localized: "Scansione Email con AI"),
                description: String(localized: "Trova tutti gli abbonamenti nascosti")
            )

            PaywallBenefitRow(
                icon: "brain.head.profile",
                iconColor: .purple,
                title: String(localized: "Money Coach AI"),
                description: String(localized: "Consigli smart per risparmiare")
            )

            PaywallBenefitRow(
                icon: "infinity",
                iconColor: .green,
                title: String(localized: "Abbonamenti Illimitati"),
                description: String(localized: "Traccia tutti i tuoi servizi")
            )
        }
    }

    // MARK: - Plan Cards Section

    private var planCardsSection: some View {
        VStack(spacing: 12) {
            // Annual Plan Card
            PaywallPlanCardInternal(
                title: String(localized: "Piano Annuale"),
                price: storeManager.annualPrice,
                period: String(localized: "all'anno"),
                savingsPercent: storeManager.savingsPercentage,
                isSelected: storeManager.selectedPlan == .annual
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    storeManager.selectedPlan = .annual
                }
                Haptic.selection()
            }

            // Weekly Plan Card
            PaywallPlanCardInternal(
                title: String(localized: "Piano Settimanale"),
                price: storeManager.weeklyPrice,
                period: String(localized: "a settimana"),
                savingsPercent: nil,
                isSelected: storeManager.selectedPlan == .weekly
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    storeManager.selectedPlan = .weekly
                }
                Haptic.selection()
            }
        }
    }

    // MARK: - Free Trial Toggle

    private var freeTrialToggle: some View {
        HStack {
            Text(String(localized: "Prova gratuita di 3 giorni"))
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: $storeManager.freeTrialEnabled)
                .tint(.green)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Disclosure Text (Apple Compliance)

    private var disclosureText: some View {
        Text(disclosureString)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }

    private var disclosureString: String {
        let price = storeManager.selectedPlan == .annual ? storeManager.annualPrice : storeManager.weeklyPrice
        let period = storeManager.selectedPlan == .annual ? String(localized: "anno") : String(localized: "settimana")
        return String(localized: "Dopo la prova gratuita di 3 giorni, l'abbonamento si rinnova automaticamente a \(price)/\(period). Puoi annullare in qualsiasi momento dalle impostazioni del tuo account Apple almeno 24 ore prima della fine del periodo corrente.")
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                isPurchasing = true
                Haptic.impact(.medium)
                let success = await storeManager.purchase()
                isPurchasing = false

                if success {
                    Haptic.notification(.success)
                    showSuccessAlert = true
                } else if storeManager.errorMessage != nil {
                    Haptic.notification(.error)
                    showErrorAlert = true
                }
            }
        } label: {
            HStack(spacing: 8) {
                if isPurchasing || storeManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(buttonText)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [.appPrimary, .appSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            .opacity((isPurchasing || storeManager.isLoading) ? 0.7 : 1.0)
        }
        .disabled(isPurchasing || storeManager.isLoading)
    }

    private var buttonText: String {
        if storeManager.freeTrialEnabled {
            return String(localized: "Inizia 3 giorni gratis")
        } else {
            return String(localized: "Continua")
        }
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        HStack(spacing: 12) {
            Button(String(localized: "Ripristina")) {
                Task {
                    await storeManager.restorePurchases()
                    if storeManager.isPro {
                        showSuccessAlert = true
                    } else if storeManager.errorMessage != nil {
                        showErrorAlert = true
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Text("•")
                .font(.caption)
                .foregroundColor(.secondary)

            Link(destination: URL(string: "https://zdrilichivan.github.io/subly/terms.html")!) {
                Text(String(localized: "Termini"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("•")
                .font(.caption)
                .foregroundColor(.secondary)

            Link(destination: URL(string: "https://zdrilichivan.github.io/subly/privacy.html")!) {
                Text(String(localized: "Privacy"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        Haptic.notification(.success)
        if isSheet {
            dismiss()
        } else {
            withAnimation {
                hasCompletedOnboarding = true
            }
        }
    }
}

// MARK: - Paywall Benefit Row

private struct PaywallBenefitRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Paywall Plan Card Internal

private struct PaywallPlanCardInternal: View {
    let title: String
    let price: String
    let period: String
    let savingsPercent: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.appPrimary : Color(.systemGray4),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 16, height: 16)
                    }
                }

                // Plan info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        if let savings = savingsPercent {
                            Text("-\(savings)%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.green)
                                )
                        }
                    }
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .appPrimary : .primary)

                    Text(period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.appPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legacy Components (kept for compatibility)

struct PaywallBenefitCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        PaywallBenefitRow(icon: icon, iconColor: iconColor, title: title, description: description)
    }
}

struct PaywallPlanCard: View {
    let title: String
    let originalPrice: String?
    let price: String
    let period: String
    let savingsPercent: Int?
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void

    var body: some View {
        PaywallPlanCardInternal(
            title: title,
            price: price,
            period: period,
            savingsPercent: savingsPercent,
            isSelected: isSelected,
            action: action
        )
    }
}

#Preview {
    PaywallOnboardingView(hasCompletedOnboarding: .constant(false))
}
