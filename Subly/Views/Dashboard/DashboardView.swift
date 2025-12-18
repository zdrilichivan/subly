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
    @StateObject private var storeService = StoreService.shared
    @AppStorage("userName") private var userName = ""
    @AppStorage("userProfileImageData") private var profileImageData: Data?
    @State private var navigateToSettings = false
    @State private var showingAddSheet = false

    private let insightService = InsightService.shared

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Custom Header
                        headerSection

                        // Cards statistiche
                        statsCardsSection

                        // Insight: Cosa potresti fare (carousel con più suggerimenti)
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
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSubscriptionView()
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 16) {
            // Left side - Greeting & Date
            VStack(alignment: .leading, spacing: 6) {
                Text(formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                HStack(spacing: 8) {
                    Text(greetingText)
                        .font(.system(size: 26, weight: .bold))

                    if storeService.isUnlocked {
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                            )
                    }
                }
            }

            Spacer()

            // Right side - Pill with Add + Avatar
            HStack(spacing: 12) {
                // Add button - styled like card icons
                Button {
                    showingAddSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.12))
                            .frame(width: 38, height: 38)

                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.appPrimary)
                    }
                }

                // Avatar button
                Button {
                    navigateToSettings = true
                } label: {
                    profileAvatarView
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
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
        HStack(spacing: 12) {
            StatCard(
                title: String(localized: "Mensile"),
                value: viewModel.totalMonthlyCost.currencyFormatted,
                icon: "calendar",
                color: .appPrimary
            )

            StatCard(
                title: String(localized: "Annuale"),
                value: viewModel.totalYearlyCost.currencyFormatted,
                icon: "calendar.badge.clock",
                color: .appSecondary
            )
        }
    }

    // MARK: - Subscriptions Section

    private var subscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("I tuoi abbonamenti")
                    .font(.headline)

                if viewModel.activeSubscriptions.isNotEmpty {
                    Text("\(viewModel.activeSubscriptions.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
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
                LazyVStack(spacing: 12) {
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
        VStack(spacing: 16) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Nessun abbonamento")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Inizia a tracciare i tuoi abbonamenti esistenti per tenere sotto controllo le spese")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddSheet = true
            } label: {
                Label("Traccia abbonamento", systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8)
        )
    }
}

#Preview {
    DashboardView()
        .environmentObject(SubscriptionViewModel())
}
