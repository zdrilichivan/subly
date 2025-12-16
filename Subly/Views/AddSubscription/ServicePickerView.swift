//
//  ServicePickerView.swift
//  SublySwift
//
//  Vista per selezionare un servizio dal catalogo
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
        .background(Color(.systemBackground))
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

    // MARK: - Services Grid

    private var servicesGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredServices) { service in
                    ServiceLogoGridItem(
                        service: service,
                        isSelected: selectedService?.id == service.id,
                        action: {
                            selectService(service)
                        }
                    )
                }
            }
            .padding()
        }
    }

    private var filteredServices: [Service] {
        var services = ServiceCatalog.allServices

        // Filter by category
        if let cat = selectedCategory {
            services = services.filter { $0.category == cat }
        }

        // Filter by search
        if !searchText.isEmpty {
            services = ServiceCatalog.search(searchText)
            if let cat = selectedCategory {
                services = services.filter { $0.category == cat }
            }
        }

        return services
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

    private func selectService(_ service: Service) {
        Haptic.selection()
        selectedService = service
        category = service.category
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
