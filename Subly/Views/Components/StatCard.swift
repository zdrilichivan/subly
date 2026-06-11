//
//  StatCard.swift
//  SublySwift
//
//  Card per le statistiche nella dashboard
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Icon - usando design system per coerenza
            IconContainer(
                systemName: icon,
                size: IconContainerSize.lg,
                color: color,
                backgroundOpacity: IconBackgroundOpacity.medium
            )

            // Value & Title
            VStack(spacing: Spacing.xxs) {
                Text(value)
                    .font(Typography.numericMedium())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.numericText())

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Mini Stat Card (per Stats View)
struct MiniStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Icon - usando design system
            IconContainer(
                systemName: icon,
                size: IconContainerSize.md,
                color: color,
                backgroundOpacity: IconBackgroundOpacity.medium
            )

            Spacer()

            // Value & Title
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(value)
                    .font(Typography.numericMedium(20))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 120)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Dashboard cards
            HStack(spacing: 12) {
                StatCard(
                    title: "Mensile",
                    value: "€127,90",
                    icon: "calendar",
                    color: .blue
                )

                StatCard(
                    title: "Annuale",
                    value: "€1.534,80",
                    icon: "calendar.badge.clock",
                    color: .purple
                )
            }

            // Stats View cards
            Text("Panoramica")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MiniStatCard(
                    title: "Abbonamenti attivi",
                    value: "12",
                    icon: "creditcard.fill",
                    color: .appPrimary
                )

                MiniStatCard(
                    title: "Spesa mensile",
                    value: "€127,90",
                    icon: "calendar",
                    color: .green
                )

                MiniStatCard(
                    title: "Spesa annuale",
                    value: "€1.534,80",
                    icon: "calendar.badge.clock",
                    color: .purple
                )

                MiniStatCard(
                    title: "Rinnovi prossimi 7gg",
                    value: "3",
                    icon: "bell.fill",
                    color: .orange
                )
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
