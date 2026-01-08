//
//  EmailScanView.swift
//  Subly
//
//  Vista principale per scansione email e rilevamento abbonamenti
//

import SwiftUI
import GoogleSignIn

struct EmailScanView: View {
    @ObservedObject private var scanner = GmailScannerService.shared
    @EnvironmentObject var viewModel: SubscriptionViewModel

    @State private var showingPermissionSheet = false
    @State private var showingResults = false
    @State private var showingError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                if scanner.isSignedIn {
                    // Account connesso
                    connectedSection
                } else {
                    // Non connesso
                    notConnectedSection
                }

                // Privacy info
                privacySection

                // iCloud limitation info
                iCloudInfoSection
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "Scansione AI"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPermissionSheet) {
            EmailPermissionView {
                await connectGmail()
            }
        }
        .sheet(isPresented: $showingResults) {
            ScanResultsView()
                .environmentObject(viewModel)
        }
        .alert(String(localized: "Errore"), isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(scanner.errorMessage ?? String(localized: "Si è verificato un errore"))
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "mail.and.text.magnifyingglass")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(String(localized: "Trova i tuoi abbonamenti"))
                .font(.title2)
                .fontWeight(.bold)

            Text(String(localized: "Collega il tuo account Gmail per trovare automaticamente gli abbonamenti dalle ricevute email."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Connected Section

    private var connectedSection: some View {
        VStack(spacing: 16) {
            // Account info
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Gmail collegato"))
                        .font(.headline)

                    Text(scanner.userEmail ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(String(localized: "Disconnetti")) {
                    scanner.signOut()
                }
                .font(.subheadline)
                .foregroundColor(.red)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )

            // Scan button
            Button {
                Task {
                    await scanEmails()
                }
            } label: {
                HStack {
                    if scanner.isScanning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "magnifyingglass")
                    }

                    Text(scanner.isScanning ?
                         String(localized: "Scansione in corso...") :
                         String(localized: "Avvia Scansione"))
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .disabled(scanner.isScanning)

            // Progress
            if scanner.isScanning {
                VStack(spacing: 8) {
                    ProgressView(value: scanner.scanProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))

                    Text(String(localized: "Analisi email in corso..."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
            }

            // Previous results
            if !scanner.foundSubscriptions.isEmpty && !scanner.isScanning {
                Button {
                    showingResults = true
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")

                        Text(String(localized: "Vedi \(scanner.foundSubscriptions.count) abbonamenti trovati"))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                }
                .foregroundColor(.primary)
            }
        }
    }

    // MARK: - Not Connected Section

    private var notConnectedSection: some View {
        VStack(spacing: 16) {
            // Features list
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "bolt.fill",
                    color: .orange,
                    title: String(localized: "Veloce"),
                    description: String(localized: "Scansiona centinaia di email in pochi secondi")
                )

                FeatureRow(
                    icon: "lock.fill",
                    color: .green,
                    title: String(localized: "Sicuro"),
                    description: String(localized: "I tuoi dati restano sul tuo dispositivo")
                )

                FeatureRow(
                    icon: "sparkles",
                    color: .purple,
                    title: String(localized: "Powered by AI"),
                    description: String(localized: "L'AI riconosce automaticamente tutti i servizi")
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )

            // Google Sign-In Button
            GoogleSignInButton {
                showingPermissionSheet = true
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "La tua privacy è importante"), systemImage: "hand.raised.fill")
                .font(.subheadline)
                .fontWeight(.medium)

            Text(String(localized: "Subly legge solo le email di ricevute e abbonamenti. Non accediamo mai alle tue email personali, allegati o contatti. Puoi disconnettere in qualsiasi momento."))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }

    // MARK: - iCloud Info Section

    private var iCloudInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "Perché solo Gmail?"), systemImage: "icloud.slash")
                .font(.subheadline)
                .fontWeight(.medium)

            Text(String(localized: "Apple non fornisce un'API pubblica per accedere alle email di iCloud Mail. Questa è una limitazione imposta da Apple, non da Subly. Gmail è l'unico servizio che offre un accesso sicuro via OAuth per la scansione delle email."))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Actions

    private func connectGmail() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            return
        }

        do {
            try await scanner.signIn(presenting: viewController)
        } catch {
            scanner.errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func scanEmails() async {
        do {
            let _ = try await scanner.scanEmails()
            if !scanner.foundSubscriptions.isEmpty {
                showingResults = true
            }
        } catch {
            showingError = true
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Email Permission View

struct EmailPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    let onContinue: () async -> Void

    @State private var isConnecting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Gmail Icon
                GmailLogoView(size: 80)

                // Title
                Text(String(localized: "Accesso Email"))
                    .font(.title)
                    .fontWeight(.bold)

                // Description
                VStack(spacing: 16) {
                    PermissionItem(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        text: String(localized: "Legge solo email di abbonamenti e ricevute")
                    )

                    PermissionItem(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        text: String(localized: "I dati restano sul tuo dispositivo")
                    )

                    PermissionItem(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        text: String(localized: "Puoi disconnettere quando vuoi")
                    )

                    PermissionItem(
                        icon: "xmark.circle.fill",
                        color: .red,
                        text: String(localized: "Non leggiamo email personali")
                    )

                    PermissionItem(
                        icon: "xmark.circle.fill",
                        color: .red,
                        text: String(localized: "Non salviamo contenuto email")
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )

                Spacer()

                // Continue button (Google style)
                Button {
                    Task {
                        isConnecting = true
                        await onContinue()
                        isConnecting = false
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 12) {
                        if isConnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(white: 0.3)))
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)

                                GoogleLogoView(size: 20)
                            }

                            Text(String(localized: "Continua con Google"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(white: 0.3))

                            Spacer()
                        }
                    }
                    .padding(.leading, 8)
                    .padding(.trailing, 16)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isConnecting)

                // Cancel
                Button(String(localized: "Annulla")) {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

private struct PermissionItem: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        EmailScanView()
            .environmentObject(SubscriptionViewModel())
    }
}
