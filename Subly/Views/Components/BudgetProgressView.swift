//
//  BudgetProgressView.swift
//  SublySwift
//
//  Progress bar per il budget
//

import SwiftUI

struct BudgetProgressView: View {
    let percentage: Double
    let color: Color
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(.systemGray5))
                    .frame(height: height)

                // Progress
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: min(geometry.size.width * CGFloat(percentage / 100), geometry.size.width), height: height)
                    .animation(.easeInOut(duration: 0.5), value: percentage)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Circular Budget Progress
struct CircularBudgetProgress: View {
    let percentage: Double
    let color: Color
    var lineWidth: CGFloat = 10
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: min(CGFloat(percentage / 100), 1))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: percentage)

            // Percentage text
            VStack(spacing: 2) {
                Text("\(Int(min(percentage, 999)))%")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("usato")
                    .font(.system(size: size * 0.1))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 30) {
        // Linear progress bars
        VStack(spacing: 16) {
            BudgetProgressView(percentage: 50, color: .budgetSafe)
            BudgetProgressView(percentage: 85, color: .budgetWarning)
            BudgetProgressView(percentage: 110, color: .budgetDanger)
        }
        .padding()

        // Circular progress
        HStack(spacing: 20) {
            CircularBudgetProgress(percentage: 50, color: .budgetSafe, size: 80)
            CircularBudgetProgress(percentage: 85, color: .budgetWarning, size: 80)
            CircularBudgetProgress(percentage: 110, color: .budgetDanger, size: 80)
        }
    }
    .padding()
}
