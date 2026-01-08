//
//  CoachPromoView.swift
//  Subly
//
//  Vista promozionale del Money Coach per utenti free
//

import SwiftUI

struct CoachPromoView: View {
    @State private var showingProUpgrade = false
    @State private var animateItems = false

    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack(alignment: .top) {
                    // Gradient che scrolla con i contenuti
                    LinearGradient(
                        colors: [
                            Color(red: 0.35, green: 0.40, blue: 0.65),
                            Color(red: 0.12, green: 0.14, blue: 0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 380)
                    .frame(maxWidth: .infinity)
                    .offset(y: -220)

                    VStack(spacing: Spacing.lg) {
                        // Custom Header con gradiente
                        pageHeaderSection

                        // Header card
                        headerSection

                        // Features
                        featuresSection

                        // CTA Button
                        ctaSection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    animateItems = true
                }
            }
            .sheet(isPresented: $showingProUpgrade) {
                PaywallOnboardingView()
            }
        }
    }

    // MARK: - Page Header Section

    private var pageHeaderSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formattedDate)
                .font(Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)

            Text("Money Coach AI")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Spacing.sm)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: Date()).uppercased()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: Spacing.lg) {
            // Icon più compatto
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            .scaleEffect(animateItems ? 1 : 0.8)
            .opacity(animateItems ? 1 : 0)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Il tuo consulente finanziario AI")
                    .font(Typography.subheadline)
                    .foregroundColor(.secondary)

                // Pro badge
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                    Text("Funzione Pro")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("Cosa include")
                .font(Typography.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: Spacing.sm) {
                FeatureRow(
                    icon: "calendar.badge.clock",
                    iconColor: .green,
                    title: "Consiglio del giorno",
                    description: "Ogni giorno un nuovo consiglio pratico per risparmiare"
                )
                .offset(x: animateItems ? 0 : -50)
                .opacity(animateItems ? 1 : 0)

                FeatureRow(
                    icon: "brain.head.profile",
                    iconColor: .purple,
                    title: "Mindset finanziario",
                    description: "Cambia il tuo approccio al denaro"
                )
                .offset(x: animateItems ? 0 : -50)
                .opacity(animateItems ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animateItems)

                FeatureRow(
                    icon: "target",
                    iconColor: .orange,
                    title: "Sfide settimanali",
                    description: "Metti alla prova le tue abitudini di spesa"
                )
                .offset(x: animateItems ? 0 : -50)
                .opacity(animateItems ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animateItems)

                FeatureRow(
                    icon: "lightbulb.max",
                    iconColor: .yellow,
                    title: "Trucchi e hack",
                    description: "Spendi meno senza rinunciare a nulla"
                )
                .offset(x: animateItems ? 0 : -50)
                .opacity(animateItems ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: animateItems)

                FeatureRow(
                    icon: "bell.badge",
                    iconColor: .blue,
                    title: "Notifiche motivazionali",
                    description: "Promemoria per restare in carreggiata"
                )
                .offset(x: animateItems ? 0 : -50)
                .opacity(animateItems ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: animateItems)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                showingProUpgrade = true
                Haptic.impact(.light)
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Prova gratis per 3 giorni")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: ButtonHeight.lg)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }

            Text("Incluso con Subly Pro")
                .font(Typography.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}

#Preview {
    CoachPromoView()
}
