//
//  NextRenewalHeroCard.swift
//  Subly
//
//  Card prominente in dashboard con il rinnovo più vicino:
//  trasforma la home da elenco a strumento decisionale ("lo uso ancora?").
//

import SwiftUI

struct NextRenewalHeroCard: View {
    let subscription: Subscription

    private var urgencyColor: Color {
        if subscription.isDateEstimated { return .secondary }
        switch subscription.daysUntilRenewal {
        case ...1: return .red
        case 2...7: return .orange
        default: return .appPrimary
        }
    }

    private var countdownText: String {
        let prefix = subscription.isDateEstimated ? "≈ " : ""
        return prefix + subscription.renewalText
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            ServiceLogoView(
                serviceName: subscription.serviceName,
                category: subscription.category,
                size: 52
            )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(String(localized: "Prossimo rinnovo"))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.8)

                Text(subscription.displayName)
                    .font(Typography.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    Text(countdownText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(urgencyColor)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(urgencyColor.opacity(0.12))
                        )

                    Text(subscription.nextBillingDate.shortFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(subscription.cost.currencyFormatted)
                    .font(Typography.numericMedium(20))
                    .foregroundColor(.primary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(urgencyColor.opacity(0.35), lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(String(localized: "Prossimo rinnovo")): \(subscription.displayName), \(countdownText), \(subscription.cost.currencyFormatted)")
    }
}

#Preview {
    VStack(spacing: 16) {
        NextRenewalHeroCard(
            subscription: Subscription(
                serviceName: "Netflix Standard",
                cost: 13.99,
                billingCycle: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                category: .streaming
            )
        )

        NextRenewalHeroCard(
            subscription: Subscription(
                serviceName: "iCloud+ 200GB",
                cost: 2.99,
                billingCycle: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
                category: .cloud,
                isDateEstimated: true
            )
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
