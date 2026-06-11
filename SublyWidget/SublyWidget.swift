//
//  SublyWidget.swift
//  SublyWidget
//
//  Widget "Prossimo rinnovo": small (rinnovo più vicino) e medium
//  (prossimi 3 rinnovi + totale mensile). Legge lo snapshot scritto
//  dall'app nell'App Group (vedi WidgetDataBridge nell'app).
//  Funzione Pro: per i free mostra l'invito a sbloccare.
//

import WidgetKit
import SwiftUI

// MARK: - Modello condiviso (JSON-compatibile con WidgetDataBridge)

struct WidgetSubscription: Codable, Identifiable {
    let id: UUID
    let name: String
    let cost: Double
    let currencyCode: String
    let nextBillingDate: Date
    let categoryIcon: String
    let isDateEstimated: Bool
}

struct WidgetSnapshot: Codable {
    let subscriptions: [WidgetSubscription]
    let monthlyTotal: Double
}

enum WidgetStore {
    static let appGroupID = "group.com.ivanzdrilich.Subly"

    static func loadSnapshot() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "widgetSnapshot") else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    static var isPro: Bool {
        UserDefaults(suiteName: appGroupID)?.bool(forKey: "widgetIsPro") ?? false
    }
}

// MARK: - Timeline

struct RenewalEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let isPro: Bool
}

struct RenewalProvider: TimelineProvider {

    func placeholder(in context: Context) -> RenewalEntry {
        RenewalEntry(date: .now, snapshot: .sample, isPro: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (RenewalEntry) -> Void) {
        // In galleria mostra sempre dati di esempio
        if context.isPreview {
            completion(RenewalEntry(date: .now, snapshot: .sample, isPro: true))
        } else {
            completion(RenewalEntry(date: .now, snapshot: WidgetStore.loadSnapshot(), isPro: WidgetStore.isPro))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RenewalEntry>) -> Void) {
        let entry = RenewalEntry(date: .now, snapshot: WidgetStore.loadSnapshot(), isPro: WidgetStore.isPro)
        // Ricarica a mezzanotte: i countdown cambiano col giorno
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        let midnight = Calendar.current.startOfDay(for: tomorrow)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

extension WidgetSnapshot {
    static let sample = WidgetSnapshot(
        subscriptions: [
            WidgetSubscription(id: UUID(), name: "Netflix", cost: 13.99, currencyCode: "EUR",
                               nextBillingDate: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now,
                               categoryIcon: "play.tv.fill", isDateEstimated: false),
            WidgetSubscription(id: UUID(), name: "Spotify", cost: 10.99, currencyCode: "EUR",
                               nextBillingDate: Calendar.current.date(byAdding: .day, value: 6, to: .now) ?? .now,
                               categoryIcon: "music.note", isDateEstimated: false),
            WidgetSubscription(id: UUID(), name: "iCloud+", cost: 2.99, currencyCode: "EUR",
                               nextBillingDate: Calendar.current.date(byAdding: .day, value: 11, to: .now) ?? .now,
                               categoryIcon: "icloud.fill", isDateEstimated: true)
        ],
        monthlyTotal: 27.97
    )
}

// MARK: - Helpers

private extension WidgetSubscription {
    func daysUntilRenewal(from date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: nextBillingDate)
        ).day ?? 0
    }

    func countdownText(from date: Date) -> String {
        let days = daysUntilRenewal(from: date)
        let prefix = isDateEstimated ? "≈ " : ""
        switch days {
        case ...0: return prefix + String(localized: "Oggi")
        case 1: return prefix + String(localized: "Domani")
        default: return prefix + String(localized: "Tra \(days) giorni")
        }
    }

    func urgencyColor(from date: Date) -> Color {
        guard !isDateEstimated else { return .secondary }
        switch daysUntilRenewal(from: date) {
        case ...1: return .red
        case 2...7: return .orange
        default: return Color(red: 0.45, green: 0.40, blue: 0.95)
        }
    }

    var formattedCost: String {
        cost.formatted(.currency(code: currencyCode))
    }
}

// MARK: - Widget

struct NextRenewalWidget: Widget {

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextRenewalWidget", provider: RenewalProvider()) { entry in
            NextRenewalWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(uiColor: .systemBackground)
                }
        }
        .configurationDisplayName(String(localized: "Prossimo rinnovo"))
        .description(String(localized: "Tieni d'occhio i rinnovi senza aprire l'app."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NextRenewalWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RenewalEntry

    var body: some View {
        if !entry.isPro {
            lockedView
        } else if let snapshot = entry.snapshot, let next = snapshot.subscriptions.first {
            switch family {
            case .systemMedium:
                mediumView(snapshot: snapshot, next: next)
            default:
                smallView(next: next)
            }
        } else {
            emptyView
        }
    }

    // MARK: Small

    private func smallView(next: WidgetSubscription) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "Prossimo rinnovo"))
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: next.categoryIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(next.urgencyColor(from: entry.date))

                Text(next.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(next.countdownText(from: entry.date))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(next.urgencyColor(from: entry.date))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(next.formattedCost)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // MARK: Medium

    private func mediumView(snapshot: WidgetSnapshot, next: WidgetSubscription) -> some View {
        HStack(spacing: 14) {
            // Colonna sinistra: il prossimo
            VStack(alignment: .leading, spacing: 5) {
                Text(String(localized: "Prossimo rinnovo"))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Spacer(minLength: 0)

                Image(systemName: next.categoryIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(next.urgencyColor(from: entry.date))

                Text(next.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(next.countdownText(from: entry.date))
                    .font(.headline)
                    .foregroundColor(next.urgencyColor(from: entry.date))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(next.formattedCost)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Colonna destra: i successivi + totale
            VStack(alignment: .leading, spacing: 6) {
                ForEach(snapshot.subscriptions.dropFirst().prefix(3)) { sub in
                    HStack(spacing: 6) {
                        Text(sub.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        Text(sub.countdownText(from: entry.date))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(sub.urgencyColor(from: entry.date))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                HStack {
                    Text(String(localized: "Totale"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(snapshot.monthlyTotal.formatted(.currency(code: snapshot.subscriptions.first?.currencyCode ?? "EUR")) + String(localized: "/mese"))
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Stati speciali

    private var lockedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                )

            Text(String(localized: "Widget incluso in Subly Pro"))
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(String(localized: "Apri l'app per sbloccarlo"))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "creditcard.fill")
                .font(.title2)
                .foregroundColor(.secondary)

            Text(String(localized: "Apri Subly e aggiungi i tuoi abbonamenti"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(as: .systemSmall) {
    NextRenewalWidget()
} timeline: {
    RenewalEntry(date: .now, snapshot: .sample, isPro: true)
}

#Preview(as: .systemMedium) {
    NextRenewalWidget()
} timeline: {
    RenewalEntry(date: .now, snapshot: .sample, isPro: true)
}
