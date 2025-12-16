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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingICloudAlert = false
    @State private var iCloudAlertMessage = ""

    init() {
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
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    // iCloud disponibile, tutto ok
                    break
                case .noAccount:
                    iCloudAlertMessage = "Non hai effettuato l'accesso a iCloud. I tuoi dati non verranno sincronizzati tra i dispositivi. Vai su Impostazioni > Apple ID > iCloud per accedere."
                    showingICloudAlert = true
                case .restricted:
                    iCloudAlertMessage = "L'accesso a iCloud è limitato. I tuoi dati potrebbero non essere sincronizzati."
                    showingICloudAlert = true
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
