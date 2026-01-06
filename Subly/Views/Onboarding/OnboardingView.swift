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

    private let totalPages = 5 // 4 info pages + 1 name page

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "questionmark.circle.fill",
            iconColor: .orange,
            gradientColors: [.orange, .red],
            title: "Quanti abbonamenti hai?",
            description: "L'italiano medio ne ha 12 attivi. Netflix, Spotify, palestra, cloud... Li usi davvero tutti?"
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            iconColor: .purple,
            gradientColors: [.purple, .indigo],
            title: "Ti chiediamo solo una cosa",
            description: "\"Stai usando questo servizio?\" Prima di ogni rinnovo, ti aiutiamo a decidere con consapevolezza."
        ),
        OnboardingPage(
            icon: "hand.raised.fill",
            iconColor: .green,
            gradientColors: [.green, .mint],
            title: "Se non lo usi, via",
            description: "Link diretto alla disdetta. Niente più abbonamenti dimenticati che si rinnovano in silenzio."
        ),
        OnboardingPage(
            icon: "leaf.fill",
            iconColor: .appPrimary,
            gradientColors: [.appPrimary, .appSecondary],
            title: "Paga solo ciò che ami",
            description: "Il minimalismo digitale non è privarsi, è scegliere con intenzione. Meno abbonamenti, più valore."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                if currentPage < totalPages - 1 {
                    Button("Salta") {
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
                // Info pages
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(for: pages[index])
                        .tag(index)
                }

                // Name input page (last)
                nameInputPage
                    .tag(pages.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicators - migliorati con design system
            PageIndicator(
                totalPages: totalPages,
                currentPage: currentPage,
                activeColor: .appPrimary,
                size: 10,
                spacing: 10
            )
            .padding(.vertical, Spacing.lg)

            // Buttons - migliorati con stato disabled visibile
            VStack(spacing: Spacing.sm) {
                if currentPage == totalPages - 1 {
                    // Last page - name input
                    Button {
                        saveNameAndComplete()
                    } label: {
                        Text("Inizia")
                    }
                    .buttonStyle(EnhancedPrimaryButtonStyle())
                    .disabled(nameInput.trimmed.isEmpty)
                    .opacity(nameInput.trimmed.isEmpty ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: nameInput.trimmed.isEmpty)
                } else {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                        Haptic.selection()
                    } label: {
                        Text("Continua")
                    }
                    .buttonStyle(EnhancedPrimaryButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Page View

    private func pageView(for page: OnboardingPage) -> some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon con gradient
            ZStack {
                // Cerchio esterno sfumato
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradientColors.isEmpty ? [page.iconColor.opacity(0.3), page.iconColor.opacity(0.1)] : page.gradientColors.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                // Cerchio interno
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradientColors.isEmpty ? [page.iconColor] : page.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: (page.gradientColors.first ?? page.iconColor).opacity(0.4), radius: 20, x: 0, y: 10)

                Image(systemName: page.icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Name Input Page

    private var nameInputPage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon con gradient
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

                Image(systemName: "person.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Text
            VStack(spacing: 16) {
                Text("Come ti chiami?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Saremo la tua guida verso un rapporto più sano con i servizi digitali")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }

            // Name input field
            TextField("Il tuo nome", text: $nameInput)
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

    private func saveNameAndComplete() {
        userName = nameInput.trimmed
        Task {
            _ = await notificationService.requestAuthorization()
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
        Haptic.notification(.success)
    }
}

// MARK: - Onboarding Page Model

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
