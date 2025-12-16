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
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }

            // Value & Title
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
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
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            Spacer()

            // Value & Title
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
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
