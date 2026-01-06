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

    @State private var searchText = ""
    @State private var selectedCategory: ServiceCategory?
    @State private var showingCustomService = false
    @State private var customServiceName = ""
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
            .padding()
        }
    }

    private var filteredGroups: [ServiceGroup] {
        var groups = ServiceCatalog.groups(for: selectedCategory)

        if !searchText.isEmpty {
            groups = ServiceCatalog.searchGroups(searchText)
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
                TextField("Nome del servizio", text: $customServiceName)

                Picker("Categoria", selection: $category) {
                    ForEach(ServiceCategory.allCases, id: \.self) { cat in
                        Label(cat.displayName, systemImage: cat.iconName)
                            .tag(cat)
                    }
                }
            } header: {
                Text("Servizio personalizzato")
            } footer: {
                Text("Inserisci il nome di un servizio non presente nel catalogo.")
            }

            Section {
                Button {
                    createCustomService()
                } label: {
                    HStack {
                        Spacer()
                        Text("Crea servizio")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(customServiceName.trimmed.isEmpty)
            }
        }
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
        let customService = ServiceCatalog.createCustomService(
            name: customServiceName.trimmed,
            category: category
        )
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

                // Price
                if let cost = service.typicalCost {
                    Text(cost.currencyFormatted)
                        .font(Typography.numericSmall())
                        .foregroundColor(.appPrimary)
                }

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
        category: .constant(.other)
    )
}
