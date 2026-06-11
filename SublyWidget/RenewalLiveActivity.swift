//
//  RenewalLiveActivity.swift
//  SublyWidget
//
//  UI della Live Activity "rinnovo imminente": banner lock screen e
//  Dynamic Island. Gli attributi sono la copia identica di quelli
//  definiti in LiveActivityService nell'app (matching per nome di tipo).
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RenewalActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var daysLeft: Int   // 0 = oggi, 1 = domani
    }

    var subscriptionID: UUID
    var serviceName: String
    var cost: Double
    var currencyCode: String
    var categoryIcon: String
}

private extension RenewalActivityAttributes {
    var formattedCost: String {
        cost.formatted(.currency(code: currencyCode))
    }
}

struct RenewalLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RenewalActivityAttributes.self) { context in
            // Lock screen / banner
            lockScreenView(context: context)
                .padding(16)
                .activityBackgroundTint(nil)
                .activitySystemActionForegroundColor(.orange)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: context.attributes.categoryIcon)
                            .font(.title3)
                            .foregroundColor(.orange)
                        Text(context.attributes.serviceName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(renewalText(daysLeft: context.state.daysLeft))
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.formattedCost)
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Text(String(localized: "Lo usi ancora? Apri Subly"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: context.attributes.categoryIcon)
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text(context.state.daysLeft == 0
                     ? String(localized: "Oggi")
                     : String(localized: "Domani"))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            } minimal: {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.orange)
            }
        }
    }

    private func renewalText(daysLeft: Int) -> String {
        daysLeft == 0
            ? String(localized: "Si rinnova oggi")
            : String(localized: "Si rinnova domani")
    }

    private func lockScreenView(context: ActivityViewContext<RenewalActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: context.attributes.categoryIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.serviceName)
                    .font(.headline)
                    .lineLimit(1)

                Text(renewalText(daysLeft: context.state.daysLeft))
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(context.attributes.formattedCost)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(String(localized: "Lo usi ancora?"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
