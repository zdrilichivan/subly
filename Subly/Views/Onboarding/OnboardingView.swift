//
//  OnboardingView.swift
//  SublySwift
//
//  Vista di onboarding per il primo avvio dell'app.
//  Flusso orientato al valore: problema → selezione servizi →
//  spesa rivelata → funzioni reali → nome → paywall personalizzato.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @StateObject private var notificationService = NotificationService.shared

    @State private var currentPage = 0
    @AppStorage("userName") private var userName = ""
    @AppStorage("estimatedYearlySpend") private var estimatedYearlySpend: Double = 0
    @State private var nameInput = ""
    @FocusState private var isNameFieldFocused: Bool
    @State private var showPaywall = false

    /// Servizi selezionati nella pagina di quick-pick
    @State private var selectedServices: Set<String> = []

    private let totalPages = 5

    /// Servizi popolari proposti nell'onboarding (presi dal catalogo reale)
    private static let quickPickNames = [
        "Netflix Standard",
        "Spotify Individual",
        "Amazon Prime Annuale",
        "Disney+ Standard",
        "DAZN",
        "YouTube Premium",
        "Apple Music Individuale",
        "iCloud+ 200GB",
        "ChatGPT Plus",
        "NOW TV"
    ]

    private var quickPickServices: [Service] {
        Self.quickPickNames.compactMap { ServiceCatalog.find(byName: $0) }
    }

    private var selectedServiceModels: [Service] {
        quickPickServices.filter { selectedServices.contains($0.name) }
    }

    /// Spesa mensile stimata dai servizi selezionati
    private var estimatedMonthlyCost: Double {
        selectedServiceModels.reduce(0) { total, service in
            guard let cost = service.typicalCost else { return total }
            switch service.billingCycle {
            case .weekly: return total + cost * 4.33
            case .monthly: return total + cost
            case .yearly: return total + cost / 12
            }
        }
    }

    private var estimatedYearlyCost: Double {
        estimatedMonthlyCost * 12
    }

    init(hasCompletedOnboarding: Binding<Bool>) {
        self._hasCompletedOnboarding = hasCompletedOnboarding
        #if DEBUG
        if let page = UITestAutopilot.onboardingPage {
            _currentPage = State(initialValue: page)
        }
        if UITestAutopilot.showPaywall {
            _showPaywall = State(initialValue: true)
        }
        #endif
    }

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

                    // Page 2: Quick-pick dei servizi
                    servicePickPage
                        .tag(1)

                    // Page 3: La tua spesa rivelata
                    spendingRevealPage
                        .tag(2)

                    // Page 4: Funzioni reali (notifiche, disdetta, coach)
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
                    AnalyticsService.shared.track(.onboardingStepViewed, properties: ["step": "\(currentPage)"])
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
                            finishOnboardingAndShowPaywall()
                        } label: {
                            Text(String(localized: "Iniziamo!"))
                        }
                        .buttonStyle(EnhancedPrimaryButtonStyle())
                    } else {
                        Button {
                            // Verifica che non siamo già all'ultima pagina
                            guard currentPage < totalPages - 1 else { return }
                            if currentPage == 1 {
                                AnalyticsService.shared.track(.onboardingServicesSelected, properties: ["count": "\(selectedServices.count)"])
                            }
                            if currentPage == 2 {
                                AnalyticsService.shared.track(.onboardingSpendingRevealed, properties: ["yearly": String(format: "%.0f", estimatedYearlyCost)])
                            }
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                            Haptic.selection()
                        } label: {
                            Text(continueButtonTitle)
                        }
                        .buttonStyle(EnhancedPrimaryButtonStyle())
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            AnalyticsService.shared.track(.onboardingStarted)
        }
        .sheet(isPresented: $showPaywall, onDismiss: {
            // Quando la sheet viene chiusa, completa l'onboarding.
            // Se l'utente ha attivato Pro, aggiunge i servizi rimasti
            // fuori dal limite free; altrimenti programma il reminder soft
            // (copre sia la X sia la chiusura con swipe).
            handleLockedServicesAfterPaywall()
            if !StoreManager.shared.isPro {
                Task {
                    await NotificationService.shared.scheduleTrialReminderIfNeeded()
                }
            }
            AnalyticsService.shared.track(.onboardingCompleted)
            hasCompletedOnboarding = true
        }) {
            PaywallOnboardingView(source: "onboarding")
        }
    }

    private var continueButtonTitle: String {
        if currentPage == 1 && selectedServices.isEmpty {
            return String(localized: "Non uso nessuno di questi")
        }
        return String(localized: "Continua")
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

    // MARK: - Page 2: Quick-pick servizi

    private var servicePickPage: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(String(localized: "Quali di questi usi?"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(String(localized: "Tocca i servizi a cui sei abbonato: calcoliamo subito quanto ti costano davvero."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 8)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(quickPickServices) { service in
                        ServicePickChip(
                            service: service,
                            isSelected: selectedServices.contains(service.name)
                        ) {
                            if selectedServices.contains(service.name) {
                                selectedServices.remove(service.name)
                            } else {
                                selectedServices.insert(service.name)
                            }
                            Haptic.selection()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }

            if !selectedServices.isEmpty {
                Text(String(localized: "Spesa stimata: \(estimatedMonthlyCost.currencyFormatted)/mese"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appPrimary)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedServices)
    }

    // MARK: - Page 3: Spesa rivelata

    private var spendingRevealPage: some View {
        VStack(spacing: 32) {
            Spacer()

            if selectedServices.isEmpty {
                // Nessuna selezione: messaggio generico ma sempre orientato al valore
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

                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }

                VStack(spacing: 16) {
                    Text(String(localized: "Scopriamolo insieme"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(String(localized: "Aggiungi i tuoi abbonamenti dal catalogo di oltre 100 servizi e scopri quanto spendi davvero ogni anno."))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                }
            } else {
                VStack(spacing: 8) {
                    Text(String(localized: "I tuoi \(selectedServices.count) abbonamenti ti costano"))
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text(estimatedYearlyCost.currencyFormatted)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.red)

                    Text(String(localized: "all'anno"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 12) {
                    FeatureHighlight(
                        icon: "eye.fill",
                        text: String(localized: "\(estimatedMonthlyCost.currencyFormatted) che escono ogni mese, spesso senza accorgertene")
                    )
                    FeatureHighlight(
                        icon: "bell.badge.fill",
                        text: String(localized: "Subly ti avvisa prima di ogni rinnovo")
                    )
                    FeatureHighlight(
                        icon: "scissors",
                        text: String(localized: "E ti dà il link diretto per disdire ciò che non usi")
                    )
                }
                .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 4: Smart Control (funzioni reali)

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
                    icon: "brain.head.profile",
                    text: String(localized: "Money Coach con consigli quotidiani di risparmio")
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

                Text(String(localized: "Così possiamo salutarti per nome. Puoi anche saltare questo passaggio."))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }

            // Name input field (facoltativo)
            TextField(String(localized: "Il tuo nome (facoltativo)"), text: $nameInput)
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

            Spacer()
            Spacer()
        }
    }

    // MARK: - Actions

    private func finishOnboardingAndShowPaywall() {
        if !nameInput.trimmed.isEmpty {
            userName = nameInput.trimmed
        }
        isNameFieldFocused = false

        Task {
            // Aggiunge gli abbonamenti selezionati nel quick-pick.
            // Gli utenti free partono con al massimo `freeSubscriptionLimit`
            // servizi: i rimanenti vengono mostrati come "bloccati" nel paywall
            // e aggiunti automaticamente se l'utente attiva Pro.
            let limit = SubscriptionViewModel.freeSubscriptionLimit
            let isPro = StoreManager.shared.isPro
            let unlockedServices = isPro ? selectedServiceModels : Array(selectedServiceModels.prefix(limit))
            let lockedServices = isPro ? [] : Array(selectedServiceModels.dropFirst(limit))

            for service in unlockedServices {
                // Nel quick-pick non chiediamo la data di addebito:
                // stima a metà ciclo, correggibile con "Addebito arrivato"
                let subscription = Subscription(
                    serviceName: service.name,
                    cost: service.typicalCost ?? 0,
                    billingCycle: service.billingCycle,
                    nextBillingDate: Subscription.estimatedNextDate(cycle: service.billingCycle),
                    category: service.category,
                    isDateEstimated: true
                )
                await viewModel.addSubscription(subscription)
            }

            UserDefaults.standard.set(lockedServices.map(\.name), forKey: "onboardingLockedServices")

            // Salva la spesa stimata completa per il paywall personalizzato
            // (sovrascrive il valore parziale scritto dal viewModel)
            if estimatedYearlyCost > 0 {
                estimatedYearlySpend = estimatedYearlyCost
            }

            _ = await notificationService.requestAuthorization()

            withAnimation {
                showPaywall = true
            }
        }
    }

    /// Se l'utente ha attivato Pro dal paywall, aggiunge i servizi che erano
    /// rimasti fuori dal limite free; in ogni caso pulisce lo stato salvato.
    private func handleLockedServicesAfterPaywall() {
        let key = "onboardingLockedServices"
        guard let names = UserDefaults.standard.stringArray(forKey: key), !names.isEmpty else {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }
        UserDefaults.standard.removeObject(forKey: key)
        guard StoreManager.shared.isPro else { return }

        Task {
            for name in names {
                guard let service = ServiceCatalog.find(byName: name) else { continue }
                let subscription = Subscription(
                    serviceName: service.name,
                    cost: service.typicalCost ?? 0,
                    billingCycle: service.billingCycle,
                    nextBillingDate: Subscription.estimatedNextDate(cycle: service.billingCycle),
                    category: service.category,
                    isDateEstimated: true
                )
                await viewModel.addSubscription(subscription)
            }
        }
    }
}

// MARK: - Service Pick Chip

private struct ServicePickChip: View {
    let service: Service
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ServiceLogoView(serviceName: service.name, category: service.category, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(service.brandName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let cost = service.typicalCost {
                        Text("\(cost.currencyFormatted)\(service.billingCycle.shortName)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .appPrimary : Color(.systemGray4))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.appPrimary.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
