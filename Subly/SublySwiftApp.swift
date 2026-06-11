//
//  SublySwiftApp.swift
//  SublySwift
//
//  Gestione Abbonamenti - App iOS Nativa
//

import SwiftUI
import CloudKit

@main
struct SublySwiftApp: App {
    @StateObject private var viewModel = SubscriptionViewModel()
    @ObservedObject private var notificationService = NotificationService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingICloudAlert = false
    @State private var iCloudAlertMessage = ""
    @State private var showUsageCheckSheet = false

    init() {
        #if DEBUG
        UITestAutopilot.applyOnLaunch()
        #endif

        // Setup callback per aprire pagina di cancellazione dalle notifiche
        NotificationService.shared.onOpenCancellationPage = { serviceName in
            if let service = ServiceCatalog.find(byName: serviceName),
               let urlString = service.cancellationURL,
               let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(viewModel)
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .environmentObject(viewModel)
                }
            }
            .onAppear {
                checkiCloudStatus()
            }
            .onChange(of: notificationService.subscriptionToCheck) { _, newValue in
                if newValue != nil {
                    showUsageCheckSheet = true
                }
            }
            .sheet(isPresented: $showUsageCheckSheet) {
                if let subscriptionInfo = notificationService.subscriptionToCheck {
                    UsageCheckSheet(subscriptionInfo: subscriptionInfo) {
                        showUsageCheckSheet = false
                        notificationService.subscriptionToCheck = nil
                    }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
            .alert("iCloud non disponibile", isPresented: $showingICloudAlert) {
                Button("Apri Impostazioni") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Continua comunque", role: .cancel) { }
            } message: {
                Text(iCloudAlertMessage)
            }
        }
    }

    private func checkiCloudStatus() {
        #if DEBUG
        // Niente alert iCloud durante screenshot/ispezione UI da simctl
        guard !UITestAutopilot.isActive else { return }
        #endif

        // Mai bloccare il primo contatto col prodotto: l'alert appare solo
        // dopo l'onboarding e una volta sola (i dati restano comunque locali)
        guard hasCompletedOnboarding,
              !UserDefaults.standard.bool(forKey: "iCloudAlertShown") else { return }

        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    // iCloud disponibile, tutto ok
                    break
                case .noAccount:
                    iCloudAlertMessage = "Non hai effettuato l'accesso a iCloud. I tuoi dati non verranno sincronizzati tra i dispositivi. Vai su Impostazioni > Apple ID > iCloud per accedere."
                    showingICloudAlert = true
                    UserDefaults.standard.set(true, forKey: "iCloudAlertShown")
                case .restricted:
                    iCloudAlertMessage = "L'accesso a iCloud è limitato. I tuoi dati potrebbero non essere sincronizzati."
                    showingICloudAlert = true
                    UserDefaults.standard.set(true, forKey: "iCloudAlertShown")
                case .couldNotDetermine:
                    // Non mostrare alert, potrebbe essere temporaneo
                    break
                case .temporarilyUnavailable:
                    // Non mostrare alert, è temporaneo
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}
