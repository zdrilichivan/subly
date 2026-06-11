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

    init() {
        // Tab bar meno trasparente
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        #if DEBUG
        if let tab = UITestAutopilot.initialTab {
            _selectedTab = State(initialValue: tab)
        }
        #endif
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard
            DashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            // Tab 2: Statistiche
            StatsView()
                .tabItem {
                    Label("Statistiche", systemImage: "chart.bar")
                }
                .tag(1)

            // Tab 3: Money Coach AI
            DailyTipsView()
                .tabItem {
                    Label("Coach AI", systemImage: "brain.head.profile")
                }
                .tag(2)

            // Tab 4: Impostazioni
            SettingsView()
                .tabItem {
                    Label("Impostazioni", systemImage: "gearshape")
                }
                .tag(3)
        }
        .tint(Color(red: 0.25, green: 0.30, blue: 0.55)) // Indaco più intenso
    }
}

#Preview {
    ContentView()
        .environmentObject(SubscriptionViewModel())
}
