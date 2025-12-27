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

    private let totalPages = 8 // 7 info pages + 1 name page

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "leaf.fill",
            iconColor: .green,
            title: "Benvenuto in Subly",
            description: "L'app che ti aiuta a riprendere il controllo dei tuoi abbonamenti e a vivere con meno, ma meglio."
        ),
        OnboardingPage(
            icon: "creditcard.fill",
            iconColor: .appPrimary,
            title: "Traccia i tuoi abbonamenti",
            description: "Aggiungi tutti i tuoi abbonamenti da oltre 80 servizi. Saprai sempre quanto spendi ogni mese e ogni anno."
        ),
        OnboardingPage(
            icon: "lightbulb.fill",
            iconColor: .green,
            title: "Scopri cosa potresti fare",
            description: "Ti mostreremo cosa potresti fare con i soldi che spendi: viaggi, cene, esperienze. Vale la pena continuare a pagare?"
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            iconColor: .purple,
            title: "Ripensa alle tue scelte",
            description: "Domande provocatorie e suggerimenti personalizzati per aiutarti a capire di quali abbonamenti hai davvero bisogno."
        ),
        OnboardingPage(
            icon: "hand.raised.fill",
            iconColor: .blue,
            title: "Ti aiutiamo a cancellare",
            description: "Per ogni servizio troverai il link diretto alla pagina di cancellazione. Disdire non è mai stato così facile."
        ),
        OnboardingPage(
            icon: "bell.fill",
            iconColor: .red,
            title: "Mai più rinnovi a sorpresa",
            description: "Notifiche intelligenti 3 giorni, 1 giorno e il giorno stesso del rinnovo. Decidi tu se continuare."
        ),
        OnboardingPage(
            icon: "icloud.fill",
            iconColor: .cyan,
            title: "Sempre sincronizzato",
            description: "I tuoi dati sono al sicuro su iCloud e sincronizzati su tutti i tuoi dispositivi Apple."
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

            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.appPrimary : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.vertical, 20)

            // Buttons
            VStack(spacing: 12) {
                if currentPage == totalPages - 1 {
                    // Last page - name input
                    Button {
                        saveNameAndComplete()
                    } label: {
                        Text("Inizia")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(nameInput.trimmed.isEmpty)
                } else {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("Continua")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Page View

    private func pageView(for page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(page.iconColor)
            }

            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Name Input Page

    private var nameInputPage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "person.fill")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.appPrimary)
            }

            // Text
            VStack(spacing: 16) {
                Text("Come ti chiami?")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Ti accompagneremo nel tuo percorso verso il minimalismo digitale")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Name input field
            TextField("Il tuo nome", text: $nameInput)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
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
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(SubscriptionViewModel())
}
