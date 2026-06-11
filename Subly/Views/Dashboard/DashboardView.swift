//
//  DashboardView.swift
//  SublySwift
//
//  Vista principale della dashboard con lista abbonamenti
//

import SwiftUI
import UIKit

struct DashboardView: View {
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @Binding var selectedTab: Int
    @AppStorage("userName") private var userName = ""
    @AppStorage("userProfileImageData") private var profileImageData: Data?
    @State private var navigateToSettings = false
    @State private var showingServicePicker = false
    @State private var showingProUpgrade = false
    @State private var showingSuccessAlert = false
    @State private var showingMilestonePromo = false
    @State private var currentMilestone = 0
    @State private var selectedServiceForAdd: Service?
    @State private var selectedCategoryForAdd: ServiceCategory = .other
    @State private var selectedBillingCycleForAdd: BillingCycle = .monthly
    @State private var serviceForDateSheet: Service?
    @State private var statsRevealed = false
    #if DEBUG
    @State private var showingCelebrationPreview = false
    #endif
    @AppStorage("totalCancelledYearlySavings") private var totalCancelledSavings: Double = 0
    @AppStorage("cancelledSubscriptionsCount") private var cancelledCount = 0
    @ObservedObject private var storeManager = StoreManager.shared
    @StateObject private var coachService = PersonalCoachService.shared
    @StateObject private var tipsService = DailyTipsService.shared
    @StateObject private var updateService = UpdateCheckService.shared

    private let insightService = InsightService.shared

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
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
                            // Custom Header
                            headerSection

                            // Nuova versione disponibile sull'App Store
                            if updateService.shouldShowBanner {
                                updateBanner
                            }

                            // Cards statistiche
                            statsCardsSection

                        // Hero: il rinnovo più vicino, con azione diretta
                        if let nextRenewal = viewModel.subscriptionsByRenewalDate.first {
                            NavigationLink(destination: SubscriptionDetailView(subscription: nextRenewal)) {
                                NextRenewalHeroCard(subscription: nextRenewal)
                            }
                            .buttonStyle(StatCardButtonStyle())
                        }

                        // Risparmi liberati con le disdette
                        if totalCancelledSavings > 0 {
                            savingsBanner
                        }

                        // Il coach in home: consiglio del giorno → tab Coach
                        CoachInsightCard(
                            isPro: storeManager.isPro,
                            personalizedTip: coachService.personalizedTip,
                            fallbackTip: tipsService.todaysTip
                        ) {
                            Haptic.selection()
                            withAnimation { selectedTab = 2 }
                        }

                        // Insight: Cosa potresti fare (carousel con piu suggerimenti)
                        if viewModel.activeSubscriptions.isNotEmpty {
                            let comparisons = insightService.getSpendingComparisons(yearlyCost: viewModel.totalYearlyCost)
                            if comparisons.isNotEmpty {
                                SpendingCarouselCard(
                                    yearlyCost: viewModel.totalYearlyCost,
                                    comparisons: comparisons
                                )
                            }
                        }

                        // Lista abbonamenti
                        subscriptionsSection

                        // Card aiuto cancellazione (solo se ci sono abbonamenti)
                        if viewModel.activeSubscriptions.isNotEmpty {
                            CancellationHelpCard {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    withAnimation {
                                        scrollProxy.scrollTo("bottomAnchor", anchor: .bottom)
                                    }
                                }
                            }
                        }

                        // Anchor invisibile per lo scroll
                        Color.clear
                            .frame(height: 1)
                            .id("bottomAnchor")
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(isPresented: $showingServicePicker) {
                ServicePickerView(
                    selectedService: $selectedServiceForAdd,
                    category: $selectedCategoryForAdd,
                    billingCycle: $selectedBillingCycleForAdd
                )
            }
            .onChange(of: selectedServiceForAdd) { _, newService in
                guard let service = newService else { return }
                // Reset subito: se l'utente annulla la sheet della data,
                // ri-selezionare lo stesso servizio deve riattivare onChange
                selectedServiceForAdd = nil
                // Piccolo ritardo: la sheet del picker deve finire di
                // chiudersi prima di poterne presentare un'altra
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    serviceForDateSheet = service
                }
            }
            .sheet(item: $serviceForDateSheet) { service in
                BillingDateSheet(service: service) { nextBillingDate, isEstimated in
                    addSubscription(service, nextBillingDate: nextBillingDate, isDateEstimated: isEstimated)
                }
            }
            .sheet(isPresented: $showingProUpgrade) {
                PaywallOnboardingView(source: "free_limit")
            }
            .sheet(isPresented: $showingMilestonePromo) {
                MilestonePromotionView(subscriptionCount: currentMilestone) { }
            }
            .alert("Abbonamento tracciato", isPresented: $showingSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("L'abbonamento è stato aggiunto alla tua lista.")
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
            .onAppear {
                // Il consiglio del coach è in cache giornaliera: caricarlo
                // anche da qui non genera chiamate API extra
                if storeManager.isPro {
                    Task {
                        await coachService.loadPersonalizedTip(subscriptions: viewModel.subscriptions)
                    }
                }
                // Roll dei numeri solo al primo ingresso, non a ogni cambio tab
                if !statsRevealed {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.spring(response: 1.0, dampingFraction: 0.9)) {
                            statsRevealed = true
                        }
                    }
                }
                #if DEBUG
                if UITestAutopilot.showDateSheet, serviceForDateSheet == nil {
                    serviceForDateSheet = ServiceCatalog.find(byName: "Netflix Standard")
                }
                if UITestAutopilot.showCelebration {
                    showingCelebrationPreview = true
                }
                #endif
            }
            #if DEBUG
            .sheet(isPresented: $showingCelebrationPreview) {
                CancellationCelebrationView(
                    subscriptionName: "DAZN",
                    yearlySavings: 359.88,
                    totalYearlySavings: 671.64,
                    cancelledCount: 3
                ) { showingCelebrationPreview = false }
            }
            #endif
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // Left side - Greeting & Date
            VStack(alignment: .leading, spacing: 6) {
                Text(formattedDate)
                    .font(Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .textCase(.uppercase)

                Text(greetingText)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Right side - Pill with Add + Avatar
            HStack(spacing: Spacing.sm) {
                // Add button
                Button {
                    if viewModel.canAddSubscription {
                        selectedServiceForAdd = nil
                        showingServicePicker = true
                    } else {
                        AnalyticsService.shared.track(.freeLimitReached)
                        showingProUpgrade = true
                    }
                    Haptic.impact(.light)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.28, green: 0.32, blue: 0.52))
                            .frame(width: 38, height: 38)

                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .accessibilityLabel("Aggiungi abbonamento")

                // Avatar button
                Button {
                    navigateToSettings = true
                    Haptic.selection()
                } label: {
                    profileAvatarView
                }
                .accessibilityLabel("Impostazioni profilo")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(red: 0.22, green: 0.25, blue: 0.40))
            )
        }
        .padding(.bottom, Spacing.sm)
    }

    private var profileAvatarView: some View {
        Group {
            if let imageData = profileImageData,
               let uiImage = UIImage(data: imageData) {
                // User has a profile image
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
            } else {
                // Fallback to initial
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.appPrimary, .appSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)

                    Text(userInitial)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: Date()).uppercased()
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userName.isEmpty ? "!" : ", \(userName)!"
        switch hour {
        case 6..<12:
            return String(localized: "Buongiorno") + name
        case 12..<18:
            return String(localized: "Buon pomeriggio") + name
        default:
            return String(localized: "Buonasera") + name
        }
    }

    private var userInitial: String {
        if userName.isEmpty {
            return "?"
        }
        return String(userName.prefix(1)).uppercased()
    }

    // MARK: - Stats Cards Section

    private var statsCardsSection: some View {
        // I valori partono da zero e "rollano" fino al totale al primo
        // ingresso (contentTransition numericText dentro StatCard)
        HStack(spacing: Spacing.sm) {
            StatCard(
                title: String(localized: "Spesa mensile"),
                value: (statsRevealed ? viewModel.totalMonthlyCost : 0).currencyFormatted,
                icon: "calendar",
                color: .appPrimary
            )

            StatCard(
                title: String(localized: "Spesa annuale"),
                value: (statsRevealed ? viewModel.totalYearlyCost : 0).currencyFormatted,
                icon: "calendar.badge.clock",
                color: .appSecondary
            )
        }
    }

    // MARK: - Update Banner

    private var updateBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title3)
                .foregroundColor(.white)

            Text(String(localized: "C'è una nuova versione di Subly"))
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Spacer()

            if let url = updateService.storeURL {
                Link(String(localized: "Aggiorna"), destination: url)
                    .font(Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white))
            }

            Button {
                updateService.dismissBanner()
                Haptic.selection()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.white.opacity(0.15))
        )
    }

    // MARK: - Savings Banner

    private var savingsBanner: some View {
        HStack(spacing: Spacing.md) {
            IconContainer(
                systemName: "party.popper.fill",
                size: IconContainerSize.md,
                color: .green,
                backgroundOpacity: IconBackgroundOpacity.medium
            )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(String(localized: "Hai liberato \(totalCancelledSavings.currencyFormatted)/anno"))
                    .font(Typography.subheadline)
                    .fontWeight(.semibold)

                Text(cancelledCount == 1
                     ? String(localized: "1 abbonamento disdetto con Subly")
                     : String(localized: "\(cancelledCount) abbonamenti disdetti con Subly"))
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.green.opacity(0.12))
        )
    }

    // MARK: - Subscriptions Section

    private var subscriptionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center) {
                Text("I tuoi abbonamenti")
                    .font(Typography.headline)

                if viewModel.activeSubscriptions.isNotEmpty {
                    Text("\(viewModel.activeSubscriptions.count)")
                        .font(Typography.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )
                }

                Spacer()
            }

            if viewModel.subscriptionsByRenewalDate.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(viewModel.subscriptionsByRenewalDate) { subscription in
                        NavigationLink(destination: SubscriptionDetailView(subscription: subscription)) {
                            SubscriptionRow(subscription: subscription)
                        }
                        .buttonStyle(StatCardButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            IconContainer(
                systemName: "creditcard.fill",
                size: 64,
                color: .secondary,
                backgroundOpacity: 0.1
            )

            Text("Nessun abbonamento")
                .font(Typography.headline)
                .foregroundColor(.secondary)

            Text("Inizia a tracciare i tuoi abbonamenti esistenti per tenere sotto controllo le spese")
                .font(Typography.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                if viewModel.canAddSubscription {
                    selectedServiceForAdd = nil
                    showingServicePicker = true
                } else {
                    showingProUpgrade = true
                }
                Haptic.impact(.light)
            } label: {
                Label("Traccia abbonamento", systemImage: "plus")
            }
            .buttonStyle(EnhancedPrimaryButtonStyle())
            .padding(.horizontal, 40)
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 8)
        )
    }

    // MARK: - Actions

    private func addSubscription(_ service: Service, nextBillingDate: Date, isDateEstimated: Bool) {
        // Il ciclo vive nel Service: i custom lo ricevono dal form
        // (createCustomService), quelli a catalogo lo hanno di fabbrica
        let subscription = Subscription(
            serviceName: service.name,
            cost: service.typicalCost ?? 0,
            billingCycle: service.billingCycle,
            nextBillingDate: nextBillingDate,
            category: service.category,
            isDateEstimated: isDateEstimated
        )

        Task {
            await viewModel.addSubscription(subscription)
            Haptic.notification(.success)

            // Milestone raggiunta? Promo Pro al posto dell'alert di conferma.
            // Piccolo ritardo: la sheet del picker deve finire di chiudersi
            // prima di poterne presentare un'altra.
            if let milestone = MilestoneTracker.checkAndMarkMilestone(
                count: viewModel.activeSubscriptionCount,
                isPro: storeManager.isPro
            ) {
                currentMilestone = milestone
                AnalyticsService.shared.track(.milestoneShown, properties: ["milestone": "\(milestone)"])
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingMilestonePromo = true
                }
            } else {
                showingSuccessAlert = true
            }
        }
    }
}

// MARK: - Rounded Corner Shape

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    DashboardView(selectedTab: .constant(0))
        .environmentObject(SubscriptionViewModel())
}
