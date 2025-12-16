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

            // Tab 3: Minimalismo
            MinimalismView()
                .tabItem {
                    Label("Minimalismo", systemImage: "leaf.fill")
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
    }
}

#Preview {
    ContentView()
        .environmentObject(SubscriptionViewModel())
}
