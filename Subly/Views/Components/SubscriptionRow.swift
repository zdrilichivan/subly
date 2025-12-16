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
        HStack(spacing: 14) {
            // Service Logo
            ServiceLogoView(
                serviceName: subscription.serviceName,
                category: subscription.category,
                size: 48
            )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Categoria
                    Label(subscription.category.displayName, systemImage: subscription.category.iconName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    // Ciclo
                    Text("•")
                        .foregroundColor(.secondary)

                    Text(subscription.billingCycleDescription)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Price & Renewal
            VStack(alignment: .trailing, spacing: 4) {
                Text(subscription.cost.currencyFormatted)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                renewalBadge
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - Renewal Badge

    @ViewBuilder
    private var renewalBadge: some View {
        let daysUntil = subscription.daysUntilRenewal

        HStack(spacing: 4) {
            if daysUntil == 0 {
                Text("Oggi")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.red)
                    )
            } else if daysUntil == 1 {
                Text("Domani")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.orange)
                    )
            } else if daysUntil > 0 && daysUntil <= 7 {
                Text("Tra \(daysUntil) gg")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
            } else if daysUntil > 7 {
                Text(subscription.nextBillingDate.shortFormatted)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                Text("Scaduto")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.red)
            }
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
