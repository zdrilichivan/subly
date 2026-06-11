//
//  SubscriptionRow.swift
//  SublySwift
//
//  Riga per visualizzare un abbonamento nella lista
//

import SwiftUI

struct SubscriptionRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Service Logo
            ServiceLogoView(
                serviceName: subscription.serviceName,
                category: subscription.category,
                size: 48
            )

            // Info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(subscription.displayName)
                    .font(Typography.numericSmall())
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    // Categoria
                    Label(subscription.category.displayName, systemImage: subscription.category.iconName)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)

                    // Ciclo
                    Text("•")
                        .foregroundColor(.secondary)

                    Text(subscription.billingCycleDescription)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Price + countdown rinnovo
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(subscription.cost.currencyFormatted)
                    .font(Typography.numericSmall())
                    .foregroundColor(.primary)

                Text(renewalCountdownText)
                    .font(.caption2)
                    .fontWeight(subscription.daysUntilRenewal <= 1 ? .bold : .medium)
                    .foregroundColor(renewalColor)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subscription.displayName), \(subscription.cost.currencyFormatted), \(renewalCountdownText)")
    }

    /// Countdown del rinnovo, con "≈" se la data è stimata
    private var renewalCountdownText: String {
        let prefix = subscription.isDateEstimated ? "≈ " : ""
        return prefix + subscription.renewalText
    }

    /// Urgenza a colori: rosso se imminente, arancio entro la settimana
    private var renewalColor: Color {
        guard !subscription.isDateEstimated else { return .secondary }
        switch subscription.daysUntilRenewal {
        case ...1: return .red
        case 2...7: return .orange
        default: return .secondary
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SubscriptionRow(
            subscription: Subscription(
                serviceName: "Netflix",
                cost: 12.99,
                billingCycle: .monthly,
                nextBillingDate: Date(),
                category: .streaming
            )
        )

        SubscriptionRow(
            subscription: Subscription(
                serviceName: "Spotify",
                cost: 10.99,
                billingCycle: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                category: .music
            )
        )

        SubscriptionRow(
            subscription: Subscription(
                serviceName: "Adobe Creative Cloud",
                cost: 62.99,
                billingCycle: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                category: .software
            )
        )

        SubscriptionRow(
            subscription: Subscription(
                serviceName: "PlayStation Plus",
                cost: 59.99,
                billingCycle: .yearly,
                nextBillingDate: Calendar.current.date(byAdding: .month, value: 2, to: Date())!,
                category: .gaming
            )
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
