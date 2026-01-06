//
//  ProUpgradeView.swift
//  Subly
//
//  Vista per l'upgrade a Subly Pro con abbonamento
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
            VStack(spacing: 0) {
                // Contenuto scrollabile
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        headerSection

                        // Plan Selection
                        planSelectionSection

                        // Benefits
                        benefitsSection
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.md)
                }

                // Pulsanti fissi in basso
                VStack(spacing: Spacing.sm) {
                    purchaseButton

                    restoreButton

                    footerText
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.lg)
                .padding(.top, Spacing.md)
                .background(
                    Color(.systemGroupedBackground)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -4)
                )
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
            .alert(String(localized: "Abbonamento attivato!"), isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(String(localized: "Grazie per aver scelto Subly Pro! Tutte le funzionalità sono ora sbloccate."))
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
        VStack(spacing: Spacing.md) {
            // Pro Icon - usando design system
            GradientIconContainer(
                systemName: "crown.fill",
                size: IconContainerSize.xl,
                gradientColors: [.yellow, .orange],
                hasShadow: true
            )

            Text(String(localized: "Subly Pro"))
                .font(Typography.title1)

            Text(String(localized: "Sblocca tutte le funzionalita"))
                .font(Typography.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Trial banner - sempre visibile e prominente
            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "gift.fill")
                        .font(.title3)
                    Text(String(localized: "7 giorni GRATIS"))
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Text(String(localized: "Prova tutte le funzionalità Pro senza impegno"))
                    .font(Typography.caption)
                    .opacity(0.9)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Plan Selection Section

    private var planSelectionSection: some View {
        VStack(spacing: Spacing.sm) {
            // Annual Plan - Consigliato
            PlanCard(
                title: String(localized: "Annuale"),
                price: storeManager.annualPrice,
                period: String(localized: "/anno"),
                subtitle: "\(storeManager.annualMonthlyEquivalent)" + String(localized: "/mese"),
                savingsPercent: storeManager.savingsPercentage,
                isSelected: storeManager.selectedPlan == .annual,
                isRecommended: true
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    storeManager.selectedPlan = .annual
                }
                Haptic.selection()
            }

            // Monthly Plan
            PlanCard(
                title: String(localized: "Mensile"),
                price: storeManager.monthlyPrice,
                period: String(localized: "/mese"),
                subtitle: nil,
                savingsPercent: nil,
                isSelected: storeManager.selectedPlan == .monthly,
                isRecommended: false
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    storeManager.selectedPlan = .monthly
                }
                Haptic.selection()
            }
        }
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: Spacing.md) {
            BenefitRow(
                icon: "list.bullet.rectangle.portrait.fill",
                iconColor: .green,
                title: String(localized: "Abbonamenti illimitati"),
                description: String(localized: "Traccia tutti i tuoi abbonamenti senza limiti")
            )

            BenefitRow(
                icon: "mail.and.text.magnifyingglass",
                iconColor: .blue,
                title: String(localized: "Scansione Email Completa"),
                description: String(localized: "Trova tutti gli abbonamenti dalle tue email")
            )

            BenefitRow(
                icon: "lightbulb.fill",
                iconColor: .orange,
                title: String(localized: "Money Coach"),
                description: String(localized: "Consigli giornalieri per risparmiare")
            )

            BenefitRow(
                icon: "square.grid.2x2",
                iconColor: .purple,
                title: String(localized: "Widget Home Screen"),
                description: String(localized: "Monitora le spese dalla schermata Home")
            )

            BenefitRow(
                icon: "heart.fill",
                iconColor: .pink,
                title: String(localized: "Supporta lo sviluppatore"),
                description: String(localized: "Aiutami a migliorare Subly")
            )
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
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
            HStack(spacing: Spacing.xs) {
                if isPurchasing || storeManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "crown.fill")
                    Text(subscribeButtonText)
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: ButtonHeight.lg)
            .background(
                LinearGradient(
                    colors: [.appPrimary, .appSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .opacity((isPurchasing || storeManager.isLoading) ? 0.7 : 1.0)
        }
        .disabled(isPurchasing || storeManager.isLoading)
        .animation(.easeInOut(duration: 0.2), value: isPurchasing)
    }

    private var subscribeButtonText: String {
        // Mostra sempre la prova gratuita nel pulsante
        return String(localized: "Inizia 7 giorni gratis")
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
        Text(String(localized: "Prova gratis per 7 giorni. Poi \(storeManager.selectedPlan == .annual ? storeManager.annualPrice + "/anno" : storeManager.monthlyPrice + "/mese"). Annulla quando vuoi dalle impostazioni Apple."))
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

// MARK: - Plan Card (Redesigned)

struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let subtitle: String?
    let savingsPercent: Int?
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Recommended banner (solo per piano annuale)
                if isRecommended {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text(String(localized: "Piu popolare"))
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.appPrimary, .appSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }

                // Card content
                HStack(spacing: Spacing.md) {
                    // Radio button con animazione
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
                                .frame(width: 14, height: 14)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                    // Plan info
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        HStack(spacing: Spacing.xs) {
                            Text(title)
                                .font(Typography.headline)
                                .foregroundColor(.primary)

                            // Savings badge (solo se presente)
                            if let savings = savingsPercent, savings > 0 {
                                BadgeView(
                                    text: "-\(savings)%",
                                    style: .filled(.green),
                                    fontSize: 10
                                )
                            }
                        }

                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Price
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(price)
                            .font(Typography.numericMedium(20))
                            .foregroundColor(isSelected ? .appPrimary : .primary)

                        Text(period)
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(Spacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(
                        isSelected ? Color.appPrimary : Color(.systemGray5),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .shadow(
                color: isSelected ? Color.appPrimary.opacity(0.15) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title), \(price) \(period)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconContainer(
                systemName: icon,
                size: IconContainerSize.md,
                color: iconColor,
                backgroundOpacity: IconBackgroundOpacity.medium
            )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.headline)

                Text(description)
                    .font(Typography.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    ProUpgradeView()
}
