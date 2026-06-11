//
//  WhatsNewView.swift
//  Subly
//
//  Sheet mostrata una sola volta alla prima apertura dopo un
//  aggiornamento: gli utenti esistenti aggiornano in silenzio e senza
//  questa schermata non scoprirebbero mai le novità. Per i free è anche
//  un aggancio naturale al trial (le novità più ricche sono Pro).
//

import SwiftUI

struct WhatsNewView: View {
    let onClose: () -> Void

    @ObservedObject private var storeManager = StoreManager.shared
    @State private var showingPaywall = false
    @State private var animate = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.appPrimary, .appSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 76, height: 76)
                                .shadow(color: .appPrimary.opacity(0.4), radius: 14, x: 0, y: 6)

                            Image(systemName: "sparkles")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(animate ? 1 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animate)

                        Text(String(localized: "Subly è cresciuta!"))
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(String(localized: "Ecco cosa trovi in questa versione"))
                            .font(Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, Spacing.xl)

                    // Novità
                    VStack(spacing: Spacing.sm) {
                        WhatsNewRow(
                            icon: "square.grid.2x2.fill",
                            color: .appPrimary,
                            title: String(localized: "Widget per la schermata Home"),
                            subtitle: String(localized: "Il prossimo rinnovo sempre sott'occhio, senza aprire l'app"),
                            isPro: true
                        )
                        WhatsNewRow(
                            icon: "bell.and.waves.left.and.right.fill",
                            color: .orange,
                            title: String(localized: "Avvisi in tempo reale"),
                            subtitle: String(localized: "Lock screen e Dynamic Island il giorno del rinnovo"),
                            isPro: false
                        )
                        WhatsNewRow(
                            icon: "sparkles",
                            color: .purple,
                            title: String(localized: "Coach AI personale"),
                            subtitle: String(localized: "Consigli generati sui tuoi abbonamenti, sfide settimanali e streak"),
                            isPro: true
                        )
                        WhatsNewRow(
                            icon: "calendar.badge.checkmark",
                            color: .green,
                            title: String(localized: "Date senza pensieri"),
                            subtitle: String(localized: "Non ricordi quando ti addebitano? Lo stimiamo noi, tu confermi con un tocco"),
                            isPro: false
                        )
                        WhatsNewRow(
                            icon: "party.popper.fill",
                            color: .pink,
                            title: String(localized: "Disdette che valgono"),
                            subtitle: String(localized: "Vedi quanto liberi ogni anno quando tagli un abbonamento"),
                            isPro: false
                        )
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .padding(.bottom, Spacing.md)
            }

            // CTA
            VStack(spacing: Spacing.sm) {
                if storeManager.isPro {
                    Button {
                        onClose()
                    } label: {
                        Text(String(localized: "Fantastico!"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: ButtonHeight.lg)
                            .background(
                                LinearGradient(colors: [.appPrimary, .appSecondary], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    }
                } else {
                    Button {
                        AnalyticsService.shared.track(.paywallShown, properties: ["source": "whats_new_cta"])
                        showingPaywall = true
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "crown.fill")
                            Text(String(localized: "Prova tutto gratis per 3 giorni"))
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.lg)
                        .background(
                            LinearGradient(colors: [.appPrimary, .appSecondary], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    }

                    Button {
                        onClose()
                    } label: {
                        Text(String(localized: "Più tardi"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(.thinMaterial)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { animate = true }
        .sheet(isPresented: $showingPaywall, onDismiss: { onClose() }) {
            PaywallOnboardingView(source: "whats_new")
        }
    }
}

// MARK: - Row

private struct WhatsNewRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let isPro: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconContainer(
                systemName: icon,
                size: IconContainerSize.md,
                color: color,
                backgroundOpacity: IconBackgroundOpacity.medium
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.subheadline)
                        .fontWeight(.semibold)

                    if isPro {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                            Text("Pro")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                    }
                }

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    WhatsNewView { }
}
