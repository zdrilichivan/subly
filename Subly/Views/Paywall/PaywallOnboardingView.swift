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

    /// Origine del paywall per il funnel analytics
    var source: String = "onboarding"

    @StateObject private var storeManager = StoreManager.shared

    /// Spesa annua stimata, salvata da onboarding/viewModel per personalizzare l'header
    @AppStorage("estimatedYearlySpend") private var estimatedYearlySpend: Double = 0

    /// Servizi scelti nell'onboarding ma oltre il limite free: se presenti,
    /// l'header li usa come leva ("sblocca gli altri N"). Solo dal funnel onboarding.
    private var lockedServicesCount: Int {
        guard source == "onboarding" else { return 0 }
        return UserDefaults.standard.stringArray(forKey: "onboardingLockedServices")?.count ?? 0
    }

    @State private var isPurchasing = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false

    // Inizializzatore per onboarding
    init(hasCompletedOnboarding: Binding<Bool>) {
        self._hasCompletedOnboarding = hasCompletedOnboarding
        self.isSheet = false
        self.source = "onboarding"
    }

    // Inizializzatore per sheet (impostazioni, promo in-app)
    init(source: String = "settings") {
        self._hasCompletedOnboarding = .constant(false)
        self.isSheet = true
        self.source = source
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header con X per chiudere (a sinistra)
                    HStack {
                        Button {
                            AnalyticsService.shared.track(.paywallDismissed, properties: ["source": source])
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

                    // Trial reassurance
                    trialReassuranceRow
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
        .onAppear {
            AnalyticsService.shared.track(.paywallShown, properties: ["source": source])
        }
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

            if lockedServicesCount > 0 {
                // Header contestuale: l'utente ha scelto più servizi di quanti
                // il piano free ne tracci, il paywall sblocca esattamente quelli
                Text(String(localized: "Con il piano gratuito tracci \(SubscriptionViewModel.freeSubscriptionLimit) dei \(lockedServicesCount + SubscriptionViewModel.freeSubscriptionLimit) servizi che hai scelto. Sblocca subito gli altri \(lockedServicesCount)."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else if estimatedYearlySpend > 0 {
                // Header personalizzato: ancora il prezzo Pro alla spesa reale dell'utente
                Text(String(localized: "Spendi circa \(estimatedYearlySpend.currencyFormatted)/anno in abbonamenti. Riprendi il controllo."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Text(String(localized: "Accesso illimitato a tutte le funzioni"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
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
            // Annual Plan Card (consigliato, preselezionato)
            PaywallCompactPlanCard(
                badgeText: String(localized: "RISPARMI \(storeManager.savingsPercentage)%"),
                badgeColor: .red,
                title: String(localized: "Annuale"),
                priceLine: "\(storeManager.annualPrice)/" + String(localized: "anno"),
                detailLine: "\(storeManager.annualWeeklyEquivalent)/" + String(localized: "settimana"),
                isSelected: storeManager.selectedPlan == .annual
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    storeManager.selectedPlan = .annual
                }
                AnalyticsService.shared.track(.paywallPlanSelected, properties: ["plan": "annual", "source": source])
                Haptic.selection()
            }

            // Weekly Plan Card
            PaywallCompactPlanCard(
                badgeText: String(localized: "FLESSIBILE"),
                badgeColor: .appPrimary,
                title: String(localized: "Settimanale"),
                priceLine: "\(storeManager.weeklyPrice)/" + String(localized: "settimana"),
                detailLine: String(localized: "disdici quando vuoi"),
                isSelected: storeManager.selectedPlan == .weekly
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    storeManager.selectedPlan = .weekly
                }
                AnalyticsService.shared.track(.paywallPlanSelected, properties: ["plan": "weekly", "source": source])
                Haptic.selection()
            }
        }
    }

    // MARK: - Trial Reassurance

    private var trialReassuranceRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 18))
                .foregroundColor(.green)

            Text(String(localized: "3 giorni di prova gratuita inclusa. Nessun addebito se disdici prima della fine."))
                .font(.footnote)
                .foregroundColor(.primary)

            Spacer()
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
                AnalyticsService.shared.track(.purchaseStarted, properties: [
                    "plan": storeManager.selectedPlan == .annual ? "annual" : "weekly",
                    "source": source
                ])
                let success = await storeManager.purchase()
                isPurchasing = false

                if success {
                    AnalyticsService.shared.track(.purchaseCompleted, properties: [
                        "plan": storeManager.selectedPlan == .annual ? "annual" : "weekly",
                        "source": source
                    ])
                    Haptic.notification(.success)
                    showSuccessAlert = true
                } else if storeManager.errorMessage != nil {
                    AnalyticsService.shared.track(.purchaseFailed, properties: ["source": source])
                    Haptic.notification(.error)
                    showErrorAlert = true
                } else {
                    AnalyticsService.shared.track(.purchaseCancelled, properties: ["source": source])
                }
            }
        } label: {
            HStack(spacing: 8) {
                if isPurchasing || storeManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(String(localized: "Inizia la prova gratuita"))
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
            .opacity((isPurchasing || storeManager.isLoading || storeManager.selectedProduct == nil) ? 0.7 : 1.0)
        }
        .disabled(isPurchasing || storeManager.isLoading || storeManager.selectedProduct == nil)
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
        if storeManager.selectedPlan == .weekly {
            return String(localized: "Abbonamento Settimanale Premium: prova gratuita di 3 giorni, poi \(storeManager.weeklyPrice)/settimana. Rinnovo automatico settimanale. Puoi annullare in qualsiasi momento dalle Impostazioni.")
        } else {
            return String(localized: "Abbonamento Annuale Premium: prova gratuita di 3 giorni, poi \(storeManager.annualPrice)/anno. Rinnovo automatico annuale. Puoi annullare in qualsiasi momento dalle Impostazioni.")
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
                        AnalyticsService.shared.track(.purchasesRestored, properties: ["source": source])
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

// MARK: - Compact Plan Card

private struct PaywallCompactPlanCard: View {
    let badgeText: String
    let badgeColor: Color
    let title: String
    let priceLine: String
    let detailLine: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Badge
                Text(badgeText)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(badgeColor)
                    )

                // Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Price
                Text(priceLine)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Detail (equivalente settimanale / flessibilità)
                Text(detailLine)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Selection indicator
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
        .accessibilityLabel("\(title), \(priceLine)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
