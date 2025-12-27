//
//  ContentView.swift
//  SublySwift
//
//  Vista principale con TabView
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @State private var selectedTab = 0

    // Tab indices
    private let statsTabIndex = 1
    private let tipsTabIndex = 2

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // Tab 2: Statistiche
            StatsView()
                .tabItem {
                    Label("Statistiche", systemImage: "chart.bar.fill")
                }
                .tag(1)

            // Tab 3: Money Coach
            DailyTipsView()
                .tabItem {
                    Label("Coach", systemImage: "lightbulb.fill")
                }
                .tag(2)

            // Tab 4: Impostazioni
            SettingsView()
                .tabItem {
                    Label("Impostazioni", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.appPrimary)
        .onChange(of: selectedTab) { oldValue, newValue in
            // Mostra interstitial DOPO la navigazione, solo 1 volta per sessione
            if newValue == statsTabIndex {
                AdManager.shared.showInterstitialOncePerSession(for: .stats, delay: 2.0)
            } else if newValue == tipsTabIndex {
                AdManager.shared.showInterstitialOncePerSession(for: .coach, delay: 2.0)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SubscriptionViewModel())
}
