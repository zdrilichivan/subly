//
//  BillingDateSheet.swift
//  Subly
//
//  Step "Quando ti arriva l'addebito?" mostrato dopo la scelta del servizio.
//  Tre risposte facili al posto di un date picker obbligatorio:
//  - "Mi è appena arrivato"  → oggi + un ciclo (caso più comune)
//  - "So che giorno arriva"  → solo il giorno del mese (o del la settimana)
//  - "Non lo ricordo"        → stima a metà ciclo, marcata come ≈ e
//                              correggibile con un tocco al primo addebito reale
//

import SwiftUI

struct BillingDateSheet: View {

    let service: Service
    let onConfirm: (_ nextBillingDate: Date, _ isEstimated: Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    private enum Choice {
        case justCharged
        case pickDay
        case unknown
    }

    @State private var choice: Choice = .justCharged
    @State private var selectedDay = Calendar.current.component(.day, from: Date())
    @State private var selectedWeekday = Calendar.current.component(.weekday, from: Date())
    @State private var selectedYearlyDate = Date()

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection

                    VStack(spacing: Spacing.sm) {
                        justChargedCard
                        pickDayCard
                        unknownCard
                    }

                    renewalPreview
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.md)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Annulla")) {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                confirmButton
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(.thinMaterial)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ServiceLogoView(serviceName: service.name, category: service.category, size: 56)

            Text(service.brandName)
                .font(Typography.headline)

            if let cost = service.typicalCost {
                Text("\(cost.currencyFormatted)\(service.billingCycle.shortName)")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }

            Text(String(localized: "Quando ti arriva l'addebito?"))
                .font(.title3)
                .fontWeight(.bold)
                .padding(.top, Spacing.xs)

            Text(String(localized: "Serve solo per avvisarti prima del rinnovo."))
                .font(Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Option Cards

    private var justChargedCard: some View {
        BillingDateOptionCard(
            icon: "creditcard.fill",
            iconColor: .green,
            title: String(localized: "Mi è appena arrivato"),
            subtitle: String(localized: "Oggi o in questi giorni"),
            isSelected: choice == .justCharged
        ) {
            select(.justCharged)
        }
    }

    private var pickDayCard: some View {
        VStack(spacing: 0) {
            BillingDateOptionCard(
                icon: "calendar",
                iconColor: .appPrimary,
                title: String(localized: "So che giorno arriva"),
                subtitle: pickDaySubtitle,
                isSelected: choice == .pickDay
            ) {
                select(.pickDay)
            }

            if choice == .pickDay {
                dayPicker
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.top, Spacing.xxs)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: choice)
    }

    private var pickDaySubtitle: String {
        switch service.billingCycle {
        case .weekly: return String(localized: "Scegli il giorno della settimana")
        case .monthly: return String(localized: "Scegli il giorno del mese")
        case .yearly: return String(localized: "Scegli la data del rinnovo")
        }
    }

    private var unknownCard: some View {
        VStack(spacing: 0) {
            BillingDateOptionCard(
                icon: "questionmark.circle.fill",
                iconColor: .orange,
                title: String(localized: "Non lo ricordo"),
                subtitle: String(localized: "Nessun problema: lo stimiamo noi"),
                isSelected: choice == .unknown
            ) {
                select(.unknown)
            }

            if choice == .unknown {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.orange)

                    Text(String(localized: "La data sarà segnata come stimata (≈). Quando ti arriva l'addebito vero, apri l'abbonamento e tocca \"Addebito arrivato\": diventa esatta per sempre."))
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.orange.opacity(0.08))
                )
                .padding(.top, Spacing.xxs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: choice)
    }

    // MARK: - Day Picker (per ciclo)

    @ViewBuilder
    private var dayPicker: some View {
        switch service.billingCycle {
        case .monthly:
            monthDayGrid
        case .weekly:
            weekdayPicker
        case .yearly:
            DatePicker(
                String(localized: "Data del prossimo addebito"),
                selection: $selectedYearlyDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
        }
    }

    private var monthDayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
            ForEach(1...31, id: \.self) { day in
                Button {
                    selectedDay = day
                    Haptic.selection()
                } label: {
                    Text("\(day)")
                        .font(.system(size: 15, weight: selectedDay == day ? .bold : .regular, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(
                            Circle()
                                .fill(selectedDay == day ? Color.appPrimary : Color.clear)
                        )
                        .foregroundColor(selectedDay == day ? .white : .primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var weekdayPicker: some View {
        HStack(spacing: 6) {
            // weekdaySymbols è indicizzato da 0 (domenica): riordina partendo da firstWeekday
            let symbols = calendar.shortWeekdaySymbols
            let order = (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 }
            ForEach(order, id: \.self) { index in
                let weekday = index + 1
                Button {
                    selectedWeekday = weekday
                    Haptic.selection()
                } label: {
                    Text(symbols[index].capitalized)
                        .font(.system(size: 13, weight: selectedWeekday == weekday ? .bold : .regular))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(
                            Capsule()
                                .fill(selectedWeekday == weekday ? Color.appPrimary : Color(.systemGray5))
                        )
                        .foregroundColor(selectedWeekday == weekday ? .white : .primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Preview rinnovo

    private var renewalPreview: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "bell.badge")
                .foregroundColor(.appPrimary)

            Text(String(localized: "Prossimo rinnovo: \(previewText)"))
                .font(Typography.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.appPrimary.opacity(0.08))
        )
    }

    private var previewText: String {
        let date = computedNextBillingDate
        let prefix = choice == .unknown ? "≈ " : ""
        return prefix + date.shortFormatted
    }

    // MARK: - Confirm

    private var confirmButton: some View {
        Button {
            Haptic.notification(.success)
            onConfirm(computedNextBillingDate, choice == .unknown)
            dismiss()
        } label: {
            Text(String(localized: "Aggiungi abbonamento"))
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: ButtonHeight.lg)
                .background(
                    LinearGradient(colors: [.appPrimary, .appSecondary], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
    }

    // MARK: - Calcolo data

    private var computedNextBillingDate: Date {
        switch choice {
        case .justCharged:
            return Subscription.nextDate(after: Date(), cycle: service.billingCycle)

        case .unknown:
            return Subscription.estimatedNextDate(cycle: service.billingCycle)

        case .pickDay:
            switch service.billingCycle {
            case .monthly:
                return nextMonthlyDate(day: selectedDay)
            case .weekly:
                return calendar.nextDate(
                    after: Date(),
                    matching: DateComponents(weekday: selectedWeekday),
                    matchingPolicy: .nextTime
                ) ?? Date()
            case .yearly:
                let date = calendar.startOfDay(for: selectedYearlyDate)
                let today = calendar.startOfDay(for: Date())
                return date > today ? date : (calendar.date(byAdding: .year, value: 1, to: date) ?? date)
            }
        }
    }

    /// Prossima occorrenza futura del giorno del mese scelto,
    /// con clamp ai mesi più corti (31 → ultimo giorno di febbraio, ecc.)
    private func nextMonthlyDate(day: Int) -> Date {
        let today = calendar.startOfDay(for: Date())

        func dateWith(day: Int, addingMonths months: Int) -> Date? {
            guard let base = calendar.date(byAdding: .month, value: months, to: today) else { return nil }
            var comps = calendar.dateComponents([.year, .month], from: base)
            let daysInMonth = calendar.range(of: .day, in: .month, for: base)?.count ?? 28
            comps.day = min(day, daysInMonth)
            return calendar.date(from: comps)
        }

        if let thisMonth = dateWith(day: day, addingMonths: 0), thisMonth > today {
            return thisMonth
        }
        return dateWith(day: day, addingMonths: 1) ?? today
    }

    private func select(_ newChoice: Choice) {
        choice = newChoice
        Haptic.selection()
    }
}

// MARK: - Option Card

private struct BillingDateOptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                IconContainer(
                    systemName: icon,
                    size: IconContainerSize.md,
                    color: iconColor,
                    backgroundOpacity: IconBackgroundOpacity.medium
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .appPrimary : Color(.systemGray4))
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    BillingDateSheet(
        service: ServiceCatalog.find(byName: "Netflix Standard") ?? ServiceCatalog.createCustomService(name: "Netflix", category: .streaming, typicalCost: 13.99)
    ) { _, _ in }
}
