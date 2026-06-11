//
//  CoachInsightCard.swift
//  Subly
//
//  Porta il coach in home: stessa identità visiva della card AI nella
//  tab Coach (chip + bordo sfumato). Per i Pro mostra il consiglio
//  personalizzato del giorno, per i free un teaser che apre la promo.
//

import SwiftUI

struct CoachInsightCard: View {
    let isPro: Bool
    let personalizedTip: String?
    let fallbackTip: DailyTip
    let action: () -> Void

    private var contentText: String {
        if isPro {
            return personalizedTip ?? fallbackTip.content
        }
        return fallbackTip.shortTitle
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text(String(localized: "Dal tuo coach"))
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.appPrimary.opacity(0.12))
                    )

                    Spacer()

                    if !isPro {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                            Text("Pro")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.orange)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Text(contentText)
                    .font(Typography.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .lineSpacing(3)

                if !isPro {
                    Text(String(localized: "Tocca per il consiglio di oggi e le sfide di risparmio"))
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: [.appPrimary.opacity(0.5), .appSecondary.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(String(localized: "Dal tuo coach")): \(contentText)")
    }
}
