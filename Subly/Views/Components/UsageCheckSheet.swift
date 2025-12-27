//
//  UsageCheckSheet.swift
//  SublySwift
//
//  Sheet che chiede all'utente se sta utilizzando un servizio
//

import SwiftUI

struct UsageCheckSheet: View {
    let subscriptionInfo: NotificationService.SubscriptionCheckInfo
    let onDismiss: () -> Void

    @State private var showCancellationHelp = false

    private let notificationService = NotificationService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Icona servizio
                ServiceLogoView(
                    serviceName: subscriptionInfo.serviceName,
                    category: .streaming, // Default, verrà sovrascritto dal logo
                    size: 80
                )

                // Domanda principale
                VStack(spacing: 8) {
                    Text("Stai utilizzando", comment: "Usage check question prefix")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text(subscriptionInfo.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Si rinnova tra 3 giorni • \(subscriptionInfo.cost)", comment: "Renewal info with cost")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .multilineTextAlignment(.center)

                Spacer()

                if showCancellationHelp {
                    // Mostra aiuto per la cancellazione
                    cancellationHelpView
                } else {
                    // Pulsanti Sì / No
                    responseButtons
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                }
            }
        }
    }

    // MARK: - Response Buttons

    private var responseButtons: some View {
        VStack(spacing: 16) {
            // Pulsante Sì
            Button {
                notificationService.markAsUsed(subscriptionId: subscriptionInfo.id)
                Haptic.notification(.success)
                onDismiss()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Sì, lo utilizzo", comment: "Confirm using subscription button")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(14)
            }

            // Pulsante No
            Button {
                notificationService.markAsNotUsed(subscriptionId: subscriptionInfo.id)
                notificationService.incrementNotUsedCount(for: subscriptionInfo.id)
                Haptic.impact(.medium)
                withAnimation {
                    showCancellationHelp = true
                }
            } label: {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("No, non lo uso", comment: "Deny using subscription button")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(14)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Cancellation Help View

    private var cancellationHelpView: some View {
        VStack(spacing: 20) {
            // Messaggio
            VStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)

                Text("Vuoi disdire l'abbonamento?", comment: "Cancellation help title")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Ti aiutiamo a risparmiare! Tocca il pulsante qui sotto per andare alla pagina di disdetta.", comment: "Cancellation help description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Pulsante per aprire pagina cancellazione
            Button {
                openCancellationPage()
            } label: {
                HStack {
                    Image(systemName: "arrow.up.right.square.fill")
                    Text("Vai alla pagina di disdetta", comment: "Go to cancellation page button")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(14)
            }

            // Pulsante per chiudere
            Button {
                onDismiss()
            } label: {
                Text("Ci penserò dopo", comment: "Dismiss cancellation help button")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Actions

    private func openCancellationPage() {
        if let service = ServiceCatalog.find(byName: subscriptionInfo.serviceName),
           let urlString = service.cancellationURL,
           let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        } else {
            // Fallback: cerca su Google
            let searchQuery = "\(subscriptionInfo.serviceName) disdetta abbonamento".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "https://www.google.com/search?q=\(searchQuery)") {
                UIApplication.shared.open(url)
            }
        }
        onDismiss()
    }
}

#Preview {
    UsageCheckSheet(
        subscriptionInfo: NotificationService.SubscriptionCheckInfo(
            id: "test",
            name: "Netflix",
            serviceName: "Netflix",
            cost: "€12,99"
        ),
        onDismiss: {}
    )
}
