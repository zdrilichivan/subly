//
//  MilestonePromotionView.swift
//  Subly
//
//  Vista celebrativa che promuove Pro dopo milestone di abbonamenti
//

import SwiftUI

struct MilestonePromotionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager.shared

    let subscriptionCount: Int
    let onDismiss: () -> Void

    @State private var isPurchasing = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var animateConfetti = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Celebration Header
                    celebrationHeader

                    // Stats Card
                    statsCard

                    // Pro Offer
                    proOfferCard

                    // Purchase Button
                    purchaseButton

                    // Maybe Later
                    maybeLaterButton
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert(String(localized: "Acquisto completato!"), isPresented: $showSuccessAlert) {
                Button("OK") {
                    onDismiss()
                    dismiss()
                }
            } message: {
                Text(String(localized: "Grazie per aver acquistato Subly Pro! La pubblicità è stata rimossa."))
            }
            .alert(String(localized: "Errore"), isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(storeManager.errorMessage ?? String(localized: "Si è verificato un errore"))
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateConfetti = true
                }
            }
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            // Animated celebration icon
            ZStack {
                // Background circles
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.appPrimary.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                        .frame(width: CGFloat(120 + i * 30), height: CGFloat(120 + i * 30))
                        .scaleEffect(animateConfetti ? 1 : 0.5)
                        .opacity(animateConfetti ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(Double(i) * 0.1), value: animateConfetti)
                }

                // Main icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.appPrimary, .appSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(animateConfetti ? 0 : -20))
                        .animation(.spring(response: 0.5, dampingFraction: 0.5), value: animateConfetti)
                }
                .shadow(color: .appPrimary.opacity(0.4), radius: 20, x: 0, y: 10)
                .scaleEffect(animateConfetti ? 1 : 0.3)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateConfetti)
            }
            .frame(height: 180)

            Text(String(localized: "Fantastico!"))
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(celebrationMessage)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var celebrationMessage: String {
        switch subscriptionCount {
        case 3:
            return String(localized: "Hai aggiunto 3 abbonamenti!")
        case 5:
            return String(localized: "Hai aggiunto 5 abbonamenti!")
        case 10:
            return String(localized: "Wow! 10 abbonamenti tracciati!")
        default:
            return String(localized: "Stai tenendo tutto sotto controllo!")
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        HStack(spacing: 20) {
            StatItem(
                value: "\(subscriptionCount)",
                label: String(localized: "Abbonamenti"),
                color: .appPrimary
            )

            Divider()
                .frame(height: 40)

            StatItem(
                value: String(localized: "Pro"),
                label: String(localized: "Prossimo livello"),
                color: .orange
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Pro Offer Card

    private var proOfferCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text(String(localized: "Passa a Subly Pro"))
                    .font(.headline)

                Spacer()
            }

            Text(String(localized: "Stai usando Subly come un professionista! Sblocca abbonamenti illimitati e tutte le funzionalità Pro."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)

            HStack {
                Text(String(localized: "Da \(storeManager.weeklyPrice)/settimana"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.appPrimary)

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.orange.opacity(0.5), .yellow.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                isPurchasing = true
                let success = await storeManager.purchase()
                isPurchasing = false

                if success {
                    showSuccessAlert = true
                } else if storeManager.errorMessage != nil {
                    showErrorAlert = true
                }
            }
        } label: {
            HStack {
                if isPurchasing || storeManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "crown.fill")
                    Text(String(localized: "Acquista Subly Pro"))
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.orange, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(isPurchasing || storeManager.isLoading)
    }

    // MARK: - Maybe Later Button

    private var maybeLaterButton: some View {
        Button {
            onDismiss()
            dismiss()
        } label: {
            Text(String(localized: "Magari più tardi"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MilestonePromotionView(subscriptionCount: 5, onDismiss: {})
}
