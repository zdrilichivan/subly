//
//  CancellationCelebrationView.swift
//  Subly
//
//  Schermata celebrativa mostrata quando l'utente disdice un abbonamento:
//  è la vittoria per cui l'app esiste, va festeggiata. Mostra il risparmio
//  annuo liberato e il totale cumulativo.
//

import SwiftUI

struct CancellationCelebrationView: View {
    let subscriptionName: String
    let yearlySavings: Double
    let totalYearlySavings: Double
    let cancelledCount: Int
    let onClose: () -> Void

    @State private var animate = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                // Icona celebrativa con anelli animati
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.green.opacity(0.25 - Double(i) * 0.07), lineWidth: 2)
                            .frame(width: CGFloat(130 + i * 36), height: CGFloat(130 + i * 36))
                            .scaleEffect(animate ? 1 : 0.4)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(Double(i) * 0.1), value: animate)
                    }

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 104, height: 104)
                            .shadow(color: .green.opacity(0.4), radius: 18, x: 0, y: 8)

                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 46))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(animate ? 0 : -25))
                    }
                    .scaleEffect(animate ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animate)
                }
                .frame(height: 190)

                VStack(spacing: Spacing.xs) {
                    Text(String(localized: "Hai liberato"))
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text(yearlySavings.currencyFormatted)
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .scaleEffect(animate ? 1 : 0.6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.15), value: animate)

                    Text(String(localized: "all'anno"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Text(String(localized: "Addio \(subscriptionName): soldi che restano in tasca tua. 💪"))
                    .font(Typography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if cancelledCount > 1 {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.green)

                        Text(String(localized: "Liberati finora con Subly: \(totalYearlySavings.currencyFormatted)/anno"))
                            .font(Typography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.green.opacity(0.1))
                    )
                }

                Spacer()

                Button {
                    onClose()
                } label: {
                    Text(String(localized: "Grande!"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.lg)
                        .background(
                            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.lg)
            }

            ConfettiView()
        }
        .onAppear {
            animate = true
            Haptic.notification(.success)
        }
    }
}

// MARK: - Confetti

/// Coriandoli leggeri in puro SwiftUI: rettangolini colorati che cadono
/// una volta sola all'apparire della vista.
private struct ConfettiView: View {

    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat          // posizione orizzontale relativa (0-1)
        let size: CGFloat
        let color: Color
        let delay: Double
        let duration: Double
        let rotation: Double
    }

    @State private var fall = false

    private let pieces: [Piece] = {
        let palette: [Color] = [.green, .mint, .yellow, .orange, .pink, .appPrimary, .cyan]
        return (0..<36).map { _ in
            Piece(
                x: CGFloat.random(in: 0.02...0.98),
                size: CGFloat.random(in: 6...11),
                color: palette.randomElement() ?? .green,
                delay: Double.random(in: 0...0.7),
                duration: Double.random(in: 1.6...2.8),
                rotation: Double.random(in: 180...720)
            )
        }
    }()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 1.7)
                        .rotationEffect(.degrees(fall ? piece.rotation : 0))
                        .position(
                            x: piece.x * geo.size.width,
                            y: fall ? geo.size.height + 60 : -40
                        )
                        .opacity(fall ? 0.9 : 0)
                        .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: fall)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { fall = true }
    }
}

#Preview {
    CancellationCelebrationView(
        subscriptionName: "DAZN",
        yearlySavings: 359.88,
        totalYearlySavings: 527.76,
        cancelledCount: 2
    ) { }
}
