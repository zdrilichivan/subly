//
//  ServicePickerView.swift
//  SublySwift
//
//  Vista per selezionare un servizio dal catalogo (raggruppato per brand)
//

import SwiftUI

struct ServicePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedService: Service?
    @Binding var category: ServiceCategory
    @Binding var billingCycle: BillingCycle

    @StateObject private var catalogManager = ServiceCatalogManager.shared
    @StateObject private var regionService = RegionService.shared

    @State private var searchText = ""
    @State private var selectedCategory: ServiceCategory?
    @State private var showingCustomService = false
    @State private var customServiceName = ""
    @State private var customServicePrice = ""
    @State private var customServiceBillingCycle: BillingCycle = .monthly
    @State private var selectedGroup: ServiceGroup?

    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Filter
                categoryFilter

                // Search
                searchField

                // Services Grid or Custom Service
                if showingCustomService {
                    customServiceForm
                } else {
                    servicesGrid
                }
            }
            .navigationTitle("Seleziona servizio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCustomService.toggle()
                    } label: {
                        Image(systemName: showingCustomService ? "list.bullet" : "plus")
                    }
                }
            }
            .sheet(item: $selectedGroup) { group in
                VariantPickerSheet(
                    group: group,
                    onSelect: { service in
                        selectService(service)
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "Tutti",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                ForEach(ServiceCategory.allCases, id: \.self) { cat in
                    CategoryChip(
                        title: cat.displayName,
                        icon: cat.iconName,
                        color: cat.color,
                        isSelected: selectedCategory == cat,
                        action: { selectedCategory = cat }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Cerca servizio...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    // MARK: - Services Grid (Grouped by Brand)

    private var servicesGrid: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Services grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredGroups) { group in
                        BrandGridItem(
                            group: group,
                            action: {
                                handleGroupTap(group)
                            }
                        )
                    }
                }

                // "Service not found?" prompt
                if filteredGroups.isEmpty || !searchText.isEmpty {
                    serviceNotFoundPrompt
                }

                // Always show "Create Custom" option at the bottom
                createCustomCard
            }
            .padding()
        }
    }

    // MARK: - Service Not Found Prompt

    private var serviceNotFoundPrompt: some View {
        VStack(spacing: Spacing.sm) {
            if filteredGroups.isEmpty && !searchText.isEmpty {
                Text(String(localized: "Nessun risultato per \"\(searchText)\""))
                    .font(Typography.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Create Custom Card

    private var createCustomCard: some View {
        VStack(spacing: Spacing.sm) {
            Divider()
                .padding(.vertical, Spacing.sm)

            Text(String(localized: "Non trovi il tuo servizio?"))
                .font(Typography.caption)
                .foregroundColor(.secondary)

            Button {
                Haptic.selection()
                showingCustomService = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.appPrimary.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.appPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Crea servizio personalizzato"))
                            .font(Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text(String(localized: "Aggiungi qualsiasi abbonamento"))
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var filteredGroups: [ServiceGroup] {
        // Use ServiceCatalogManager for region-aware filtering
        var groups = catalogManager.groups(for: selectedCategory)

        if !searchText.isEmpty {
            groups = catalogManager.searchGroups(searchText)
            if let cat = selectedCategory {
                groups = groups.filter { $0.category == cat }
            }
        }

        return groups
    }

    // MARK: - Custom Service Form

    private var customServiceForm: some View {
        Form {
            Section {
                TextField(String(localized: "Nome del servizio"), text: $customServiceName)

                Picker(String(localized: "Categoria"), selection: $category) {
                    ForEach(ServiceCategory.allCases, id: \.self) { cat in
                        Label(cat.displayName, systemImage: cat.iconName)
                            .tag(cat)
                    }
                }
            } header: {
                Text(String(localized: "Servizio personalizzato"))
            } footer: {
                Text(String(localized: "Inserisci il nome di un servizio non presente nel catalogo."))
            }

            Section {
                HStack {
                    Text(regionService.currentRegion.currencySymbol)
                        .foregroundColor(.secondary)

                    TextField("0,00", text: $customServicePrice)
                        .keyboardType(.decimalPad)
                }

                Picker(String(localized: "Frequenza"), selection: $customServiceBillingCycle) {
                    ForEach(BillingCycle.allCases, id: \.self) { cycle in
                        Text(cycle.displayName).tag(cycle)
                    }
                }
            } header: {
                Text(String(localized: "Costo"))
            }

            Section {
                Button {
                    createCustomService()
                } label: {
                    HStack {
                        Spacer()
                        Text(String(localized: "Aggiungi abbonamento"))
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(customServiceName.trimmed.isEmpty || !isCustomPriceValid)
            }
        }
    }

    private var isCustomPriceValid: Bool {
        guard !customServicePrice.isEmpty else { return false }
        let normalized = customServicePrice.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value > 0 else { return false }
        return true
    }

    // MARK: - Actions

    private func handleGroupTap(_ group: ServiceGroup) {
        Haptic.selection()

        if let singleService = group.singleService {
            // Solo una variante: seleziona direttamente
            selectService(singleService)
        } else {
            // Multiple varianti: mostra sheet
            selectedGroup = group
        }
    }

    private func selectService(_ service: Service) {
        Haptic.selection()
        selectedService = service
        category = service.category
        selectedGroup = nil
        dismiss()
    }

    private func createCustomService() {
        let priceValue = Double(customServicePrice.replacingOccurrences(of: ",", with: "."))
        // Il ciclo scelto nel form vive nel Service stesso: chi riceve
        // selectedService può sempre fidarsi di service.billingCycle
        let customService = ServiceCatalog.createCustomService(
            name: customServiceName.trimmed,
            category: category,
            typicalCost: priceValue,
            billingCycle: customServiceBillingCycle
        )
        billingCycle = customServiceBillingCycle
        selectService(customService)
    }
}

// MARK: - Brand Grid Item

struct BrandGridItem: View {
    let group: ServiceGroup
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Logo
                ServiceLogoView(
                    serviceName: group.brandName,
                    category: group.category,
                    size: 56
                )

                // Brand Name
                Text(group.brandName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Variant Picker Sheet

struct VariantPickerSheet: View {
    let group: ServiceGroup
    let onSelect: (Service) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header con logo
                VStack(spacing: Spacing.sm) {
                    ServiceLogoView(
                        serviceName: group.brandName,
                        category: group.category,
                        size: 64
                    )

                    Text(group.brandName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Seleziona il tuo piano")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

                // Lista varianti
                ScrollView {
                    VStack(spacing: Spacing.sm) {
                        ForEach(group.services) { service in
                            VariantRow(service: service) {
                                onSelect(service)
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Variant Row

struct VariantRow: View {
    let service: Service
    let action: () -> Void

    private var catalogManager: ServiceCatalogManager { ServiceCatalogManager.shared }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Variant name
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.variantName ?? service.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if service.variantName != nil {
                        Text(service.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Price (region-aware)
                priceView

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var priceView: some View {
        if let price = catalogManager.price(for: service) {
            HStack(spacing: 4) {
                Text(price.formattedAmount)
                    .font(Typography.numericSmall())
                    .foregroundColor(price.isEstimated ? .secondary : .appPrimary)

                if price.isEstimated {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        } else if let cost = service.typicalCost {
            // Fallback to typicalCost
            Text(cost.currencyFormatted)
                .font(Typography.numericSmall())
                .foregroundColor(.appPrimary)
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    var icon: String?
    var color: Color = .appPrimary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ServicePickerView(
        selectedService: .constant(nil),
        category: .constant(.other),
        billingCycle: .constant(.monthly)
    )
}
