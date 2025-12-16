//
//  InsightCards.swift
//  Subly
//
//  Card per mostrare insight sul minimalismo digitale
//

import SwiftUI
import Combine

// MARK: - Spending Comparison Card (Cosa potresti fare)

struct SpendingComparisonCard: View {
    let yearlyCost: Double
    let comparison: SpendingComparison

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundColor(.green)

                Text("Cosa potresti fare")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)

                Spacer()

                Text(yearlyCost.currencyFormatted + "/anno")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Main comparison
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(comparison.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: comparison.icon)
                        .font(.title3)
                        .foregroundColor(comparison.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(comparison.title)
                        .font(.headline)

                    Text(comparison.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Motivational text
            Text("I tuoi abbonamenti ti costano quanto \(comparison.description.lowercased()). Ne vale la pena?")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Spending Carousel (multiple comparisons)

struct SpendingCarouselCard: View {
    let yearlyCost: Double
    let comparisons: [SpendingComparison]

    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 6, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundColor(.green)

                Text("Cosa potresti fare")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)

                Spacer()

                Text(yearlyCost.currencyFormatted + "/anno")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(comparisons.prefix(4).enumerated()), id: \.element.id) { index, comparison in
                    comparisonItem(comparison)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 100)

            // Page indicators (colore corrisponde all'icona attuale)
            HStack(spacing: 6) {
                ForEach(0..<min(comparisons.count, 4), id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? comparisons[currentIndex].color : Color(.systemGray4))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % min(comparisons.count, 4)
            }
        }
    }

    private func comparisonItem(_ comparison: SpendingComparison) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(comparison.color.opacity(0.15))
                        .frame(width: 54, height: 54)

                    Image(systemName: comparison.icon)
                        .font(.title2)
                        .foregroundColor(comparison.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(comparison.title)
                        .font(.headline)

                    Text(comparison.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Text("Ne vale la pena continuare a pagare?")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Minimalism Tip Card

struct MinimalismTipCard: View {
    let tip: MinimalismTip

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: tip.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(tip.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.08))
        )
    }
}

// MARK: - Provocative Question Card

struct ProvocativeQuestionCard: View {
    let question: ProvocativeQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.orange)
                Spacer()
            }

            Text(question.question)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(question.suggestion)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.orange.opacity(0.08))
        )
    }
}

// MARK: - Minimalism Score Card

struct MinimalismScoreCard: View {
    let score: MinimalismScore

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Il tuo punteggio")
                    .font(.headline)

                Spacer()

                Text(score.level)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(score.color)
            }

            // Score circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: CGFloat(score.score) / 100)
                    .stroke(score.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(score.score)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(score.color)

                    Text("/ 100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Message
            Text(score.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Stats
            HStack(spacing: 24) {
                VStack {
                    Text("\(score.subscriptionCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Abbonamenti")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 30)

                VStack {
                    Text(score.monthlyCost.currencyFormatted)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Al mese")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Rethink Section Card

struct RethinkSectionCard: View {
    let questions: [ProvocativeQuestion]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)

                Text("Ripensaci")
                    .font(.headline)

                Spacer()
            }

            if questions.isEmpty {
                Text("Ottimo! Non abbiamo suggerimenti per te al momento.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(questions.prefix(3)) { question in
                    ProvocativeQuestionCard(question: question)
                }
            }
        }
    }
}

// MARK: - Cancellation Help Card

struct CancellationHelpCard: View {
    @State private var isExpanded = false
    var onExpand: (() -> Void)?

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
                if isExpanded {
                    onExpand?()
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: isExpanded ? 14 : 0) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 48, height: 48)

                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ti aiutiamo a cancellare")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        if !isExpanded {
                            Text("Tocca per scoprire come")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Come funziona:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        HStack(alignment: .top, spacing: 10) {
                            Text("1.")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Text("Tocca un abbonamento dalla lista qui sopra")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(alignment: .top, spacing: 10) {
                            Text("2.")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Text("Nella pagina di dettaglio troverai il pulsante \"Cancella abbonamento\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(alignment: .top, spacing: 10) {
                            Text("3.")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Text("Verrai portato direttamente alla pagina di cancellazione del servizio")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("Semplice, veloce, senza stress!")
                            .font(.caption)
                            .italic()
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }
                    .padding(.leading, 62)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.blue.opacity(0.08))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SpendingComparisonCard(
                yearlyCost: 1200,
                comparison: SpendingComparison(
                    icon: "airplane",
                    title: "Weekend fuori",
                    description: "4 weekend in una città europea",
                    color: .blue
                )
            )

            MinimalismTipCard(
                tip: MinimalismTip(
                    title: "Uno alla volta",
                    message: "Hai davvero bisogno di Netflix, Prime Video E Disney+?",
                    icon: "tv.fill"
                )
            )

            MinimalismScoreCard(
                score: MinimalismScore(
                    score: 70,
                    level: "Equilibrato",
                    message: "Buon equilibrio, ma c'è margine di miglioramento.",
                    color: .yellow,
                    subscriptionCount: 4,
                    monthlyCost: 45.99
                )
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
