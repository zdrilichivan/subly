//
//  PaywallOnboardingView.swift
//  Subly
//
//  Paywall mostrato alla fine dell'onboarding
//  Design Apple-compliant basato su template approvato
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
    @State private var freeTrialEnabled = true

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
            ScrollView {
                VStack(spacing: 0) {
                    // Header con X per chiudere (a sinistra)
                    HStack {
                        Button {
                            completeOnboarding()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.appPrimary.opacity(0.8))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, isSheet ? 12 : geometry.safeAreaInsets.top + 16)

                    // Logo/Icon
                    headerSection
                        .padding(.top, 16)

                    Spacer()
                        .frame(height: 24)

                    // Benefits card
                    benefitsCard
                        .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 20)

                    // Plan cards (affiancate)
                    planCardsSection
                        .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 16)

                    // Free Trial Toggle
                    freeTrialToggle
                        .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 20)

                    // Purchase button
                    purchaseButton
                        .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 12)

                    // Disclosure text (Apple compliance)
                    disclosureText
                        .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 16)

                    // Footer links
                    footerLinks

                    Spacer()
                        .frame(height: geometry.safeAreaInsets.bottom + 20)
                }
            }
        }
        .background(Color(.systemGray6))
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
            // Crown icon (senza cerchio, come nello screenshot)
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.yellow, Color.orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(String(localized: "Sblocca Premium"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(String(localized: "Accesso illimitato a tutte le funzioni"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Benefits Card

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            PaywallBenefitItem(icon: "infinity", iconColor: .green, text: String(localized: "Abbonamenti illimitati"))
            PaywallBenefitItem(icon: "bell.badge.fill", iconColor: .blue, text: String(localized: "Notifiche personalizzate"))
            PaywallBenefitItem(icon: "chart.pie.fill", iconColor: .purple, text: String(localized: "Statistiche avanzate"))
            PaywallBenefitItem(icon: "icloud.fill", iconColor: .cyan, text: String(localized: "Backup e sincronizzazione"))
            PaywallBenefitItem(icon: "brain.head.profile", iconColor: .pink, text: String(localized: "Money Coach AI"))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Plan Cards Section (Affiancate)

    private var planCardsSection: some View {
        HStack(spacing: 12) {
            // Annual Plan Card
            AnnualPlanCard(
                savingsPercent: storeManager.savingsPercentage,
                price: storeManager.annualPrice,
                isSelected: storeManager.selectedPlan == .annual && !freeTrialEnabled
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    storeManager.selectedPlan = .annual
                    freeTrialEnabled = false
                }
                Haptic.selection()
            }

            // Weekly Plan with Trial Card
            TrialPlanCard(
                weeklyPrice: storeManager.weeklyPrice,
                isSelected: storeManager.selectedPlan == .weekly || freeTrialEnabled
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    storeManager.selectedPlan = .weekly
                    freeTrialEnabled = true
                }
                Haptic.selection()
            }
        }
    }

    // MARK: - Free Trial Toggle

    private var freeTrialToggle: some View {
        HStack {
            Text(String(localized: "Prova gratuita attiva"))
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: $freeTrialEnabled)
                .labelsHidden()
                .tint(.appPrimary)
                .onChange(of: freeTrialEnabled) { _, newValue in
                    if newValue {
                        storeManager.selectedPlan = .weekly
                    }
                }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
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
                    Text(freeTrialEnabled ? String(localized: "Prova Gratis") : String(localized: "Abbonati Ora"))
                        .fontWeight(.semibold)
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appPrimary)
            )
            .opacity((isPurchasing || storeManager.isLoading) ? 0.7 : 1.0)
        }
        .disabled(isPurchasing || storeManager.isLoading)
    }

    // MARK: - Disclosure Text (Apple Compliance)

    private var disclosureText: some View {
        Text(disclosureString)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private var disclosureString: String {
        if freeTrialEnabled || storeManager.selectedPlan == .weekly {
            return String(localized: "Abbonamento Settimanale Premium: prova gratuita di 3 giorni, poi \(storeManager.weeklyPrice)/settimana. Rinnovo automatico settimanale. Puoi annullare in qualsiasi momento dalle Impostazioni.")
        } else {
            return String(localized: "Abbonamento Annuale Premium: \(storeManager.annualPrice)/anno. Rinnovo automatico annuale. Puoi annullare in qualsiasi momento dalle Impostazioni.")
        }
    }

    // MARK: - Footer Links

    private var termsURL: URL {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        switch languageCode {
        case "it":
            return URL(string: "https://zdrilichivan.github.io/subly/terms.html")!
        case "es":
            return URL(string: "https://zdrilichivan.github.io/subly/terms_es.html")!
        default:
            return URL(string: "https://zdrilichivan.github.io/subly/terms_en.html")!
        }
    }

    private var privacyURL: URL {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        switch languageCode {
        case "it":
            return URL(string: "https://zdrilichivan.github.io/subly/privacy-policy.html")!
        case "es":
            return URL(string: "https://zdrilichivan.github.io/subly/privacy-policy-es.html")!
        default:
            return URL(string: "https://zdrilichivan.github.io/subly/privacy-policy-en.html")!
        }
    }

    private var footerLinks: some View {
        VStack(spacing: 12) {
            // Terms & Privacy links con icone (colorati come nello screenshot)
            HStack(spacing: 20) {
                Link(destination: termsURL) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.caption)
                        Text(String(localized: "Termini di Utilizzo"))
                            .font(.subheadline)
                    }
                    .foregroundColor(.appPrimary)
                }

                Link(destination: privacyURL) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill")
                            .font(.caption)
                        Text(String(localized: "Privacy Policy"))
                            .font(.subheadline)
                    }
                    .foregroundColor(.appPrimary)
                }
            }

            // Restore Purchases
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

// MARK: - Paywall Benefit Item (Semplificato)

private struct PaywallBenefitItem: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Annual Plan Card

private struct AnnualPlanCard: View {
    let savingsPercent: Int
    let price: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Save badge
                Text("SAVE \(savingsPercent)%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.red)
                    )

                // Title
                Text(String(localized: "Annuale"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Price
                Text("\(price) " + String(localized: "all'anno"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Selection indicator
                Circle()
                    .stroke(isSelected ? Color.appPrimary : Color(.systemGray4), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.appPrimary : Color.clear)
                            .frame(width: 12, height: 12)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Trial Plan Card

private struct TrialPlanCard: View {
    let weeklyPrice: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // FREE badge
                Text(String(localized: "GRATIS"))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.appPrimary)
                    )

                // Title
                Text(String(localized: "Prova 3 Giorni"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Price after trial (IMPORTANTE per Apple)
                Text(String(localized: "poi \(weeklyPrice)/settimana"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Selection indicator (checkmark quando selezionato)
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.appPrimary : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
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
        BenefitRow(icon: icon, iconColor: iconColor, title: title, description: description)
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
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallOnboardingView(hasCompletedOnboarding: .constant(false))
}
