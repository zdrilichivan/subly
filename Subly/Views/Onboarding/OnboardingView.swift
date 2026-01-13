//
//  OnboardingView.swift
//  SublySwift
//
//  Vista di onboarding per il primo avvio dell'app
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @StateObject private var notificationService = NotificationService.shared

    @State private var currentPage = 0
    @AppStorage("userName") private var userName = ""
    @State private var nameInput = ""
    @FocusState private var isNameFieldFocused: Bool
    @State private var showPaywall = false

    private let totalPages = 5 // 4 info pages + 1 name page

    var body: some View {
        ZStack {
            // Main onboarding content
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button(String(localized: "Salta")) {
                            withAnimation {
                                currentPage = totalPages - 1
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding()

                // Page content
                TabView(selection: $currentPage) {
                    // Page 1: Welcome - Il problema
                    welcomePage
                        .tag(0)

                    // Page 2: AI Email Scanning
                    aiScanPage
                        .tag(1)

                    // Page 3: AI Money Coach
                    aiCoachPage
                        .tag(2)

                    // Page 4: Smart Control
                    smartControlPage
                        .tag(3)

                    // Page 5: Name input
                    nameInputPage
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, newValue in
                    // Limita la navigazione ai valori validi
                    if newValue < 0 {
                        currentPage = 0
                    } else if newValue >= totalPages {
                        currentPage = totalPages - 1
                    }
                }

                // Page indicators
                PageIndicator(
                    totalPages: totalPages,
                    currentPage: currentPage,
                    activeColor: .appPrimary,
                    size: 10,
                    spacing: 10
                )
                .padding(.vertical, Spacing.lg)

                // Buttons
                VStack(spacing: Spacing.sm) {
                    if currentPage == totalPages - 1 {
                        Button {
                            saveNameAndShowPaywall()
                        } label: {
                            Text(String(localized: "Iniziamo!"))
                        }
                        .buttonStyle(EnhancedPrimaryButtonStyle())
                        .disabled(nameInput.trimmed.isEmpty)
                        .opacity(nameInput.trimmed.isEmpty ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: nameInput.trimmed.isEmpty)
                    } else {
                        Button {
                            // Verifica che non siamo già all'ultima pagina
                            guard currentPage < totalPages - 1 else { return }
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                            Haptic.selection()
                        } label: {
                            Text(String(localized: "Continua"))
                        }
                        .buttonStyle(EnhancedPrimaryButtonStyle())
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showPaywall, onDismiss: {
            // Quando la sheet viene chiusa, completa l'onboarding
            hasCompletedOnboarding = true
        }) {
            PaywallOnboardingView()
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.15), Color.orange.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.red.opacity(0.4), radius: 20, x: 0, y: 10)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                Text(String(localized: "Stai sprecando soldi"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(String(localized: "L'italiano medio ha 12 abbonamenti attivi e ne dimentica almeno 3. Sono soldi che volano via ogni mese senza che tu te ne accorga."))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }

            // Stats highlight
            HStack(spacing: 20) {
                StatHighlight(value: "€247", label: String(localized: "sprecati/anno"))
                StatHighlight(value: "12", label: String(localized: "abbonamenti medi"))
                StatHighlight(value: "3+", label: String(localized: "dimenticati"))
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 2: AI Email Scanning

    private var aiScanPage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.15), Color.cyan.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.blue.opacity(0.4), radius: 20, x: 0, y: 10)

                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    Text(String(localized: "Scansione Email"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("AI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }

                Text(String(localized: "La nostra AI analizza le tue email e trova TUTTI gli abbonamenti attivi in pochi secondi. Netflix, Spotify, palestra, cloud... niente sfugge."))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }

            // Feature highlights
            VStack(spacing: 12) {
                FeatureHighlight(
                    icon: "envelope.badge",
                    text: String(localized: "Analizza centinaia di email in secondi")
                )
                FeatureHighlight(
                    icon: "checkmark.shield",
                    text: String(localized: "Trova abbonamenti nascosti e dimenticati")
                )
                FeatureHighlight(
                    icon: "bolt.fill",
                    text: String(localized: "Setup automatico con un tap")
                )
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 3: AI Money Coach

    private var aiCoachPage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.15), Color.mint.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.green.opacity(0.4), radius: 20, x: 0, y: 10)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    Text(String(localized: "Money Coach"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("AI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }

                Text(String(localized: "Il tuo coach finanziario personale. Ogni giorno ricevi consigli smart, sfide settimanali e strategie per risparmiare senza rinunciare a nulla."))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }

            // Feature highlights
            VStack(spacing: 12) {
                FeatureHighlight(
                    icon: "calendar.badge.clock",
                    text: String(localized: "Consiglio del giorno personalizzato")
                )
                FeatureHighlight(
                    icon: "target",
                    text: String(localized: "Sfide settimanali per risparmiare")
                )
                FeatureHighlight(
                    icon: "lightbulb.max",
                    text: String(localized: "Trucchi e hack per spendere meno")
                )
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 4: Smart Control

    private var smartControlPage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.15), Color.pink.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.purple.opacity(0.4), radius: 20, x: 0, y: 10)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                Text(String(localized: "Mai più sorprese"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(String(localized: "Prima di ogni rinnovo ti chiediamo: \"Lo stai usando?\". Se la risposta è no, ti diamo il link diretto per disdire. Semplice."))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }

            // Feature highlights
            VStack(spacing: 12) {
                FeatureHighlight(
                    icon: "bell.and.waves.left.and.right",
                    text: String(localized: "Notifiche prima di ogni rinnovo")
                )
                FeatureHighlight(
                    icon: "link",
                    text: String(localized: "Link diretto alla pagina di disdetta")
                )
                FeatureHighlight(
                    icon: "chart.pie",
                    text: String(localized: "Statistiche chiare sulle tue spese")
                )
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 5: Name Input

    private var nameInputPage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.15), Color.appSecondary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.appPrimary, .appSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 20, x: 0, y: 10)

                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                Text(String(localized: "Come ti chiami?"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(String(localized: "Iniziamo a risparmiare insieme. La tua AI è pronta ad aiutarti!"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }

            // Name input field
            TextField(String(localized: "Il tuo nome"), text: $nameInput)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 48)
                .focused($isNameFieldFocused)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isNameFieldFocused = true
                    }
                }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Actions

    private func saveNameAndShowPaywall() {
        // Guard: verifica che il nome non sia vuoto
        guard !nameInput.trimmed.isEmpty else { return }

        userName = nameInput.trimmed
        isNameFieldFocused = false

        Task {
            _ = await notificationService.requestAuthorization()

            withAnimation {
                showPaywall = true
            }
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
        Haptic.notification(.success)
    }
}

// MARK: - Stat Highlight Component

private struct StatHighlight: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.red)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Feature Highlight Component

private struct FeatureHighlight: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.appPrimary)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Onboarding Page Model (kept for compatibility)

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    var gradientColors: [Color] = []
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(SubscriptionViewModel())
}
