//
//  RegionPickerView.swift
//  Subly
//
//  Vista per selezionare la regione e valuta
//

import SwiftUI

struct RegionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedRegion: Region
    let onSelect: (Region) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Region.supportedRegions) { region in
                        RegionRow(
                            region: region,
                            isSelected: region.id == selectedRegion.id,
                            action: {
                                Haptic.selection()
                                onSelect(region)
                                dismiss()
                            }
                        )
                    }
                } header: {
                    Text(String(localized: "Seleziona la tua regione"))
                } footer: {
                    Text(String(localized: "La regione determina quali servizi vengono mostrati e i prezzi suggeriti nella valuta locale."))
                }
            }
            .navigationTitle(String(localized: "Regione"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Fine")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Region Row

struct RegionRow: View {
    let region: Region
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Flag
                Text(region.flagEmoji)
                    .font(.title2)

                // Name and currency
                VStack(alignment: .leading, spacing: 2) {
                    Text(region.localizedName)
                        .font(Typography.body)
                        .foregroundColor(.primary)

                    Text("\(region.currency) • \(region.currencySymbol)")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Checkmark if selected
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appPrimary)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RegionPickerView(selectedRegion: Region.defaultRegion) { _ in }
}
