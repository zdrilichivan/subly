//
//  ServiceCatalogManager.swift
//  Subly
//
//  Gestore unificato del catalogo servizi con supporto multi-regione
//

import Foundation
import Combine
import OSLog

// MARK: - Service Catalog Manager
@MainActor
class ServiceCatalogManager: ObservableObject {
    static let shared = ServiceCatalogManager()

    private let logger = Logger(subsystem: "com.ivanzdrilich.Subly", category: "CatalogManager")
    private let syncService = CatalogSyncService.shared
    private let regionService = RegionService.shared

    // Published properties
    @Published private(set) var services: [Service] = []
    @Published private(set) var isLoading = true
    @Published private(set) var lastError: Error?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init() {
        loadCatalog()
        setupObservers()
    }

    // MARK: - Setup

    private func loadCatalog() {
        isLoading = true

        // 1. Try to load from sync service cache
        if let cachedServices = syncService.getCachedServices(), !cachedServices.isEmpty {
            services = mergeWithEmbedded(cachedServices)
            logger.info("📚 Loaded \(self.services.count) services from cache")
        } else {
            // 2. Fallback to embedded catalog
            services = ServiceCatalog.allServices
            logger.info("📚 Loaded \(self.services.count) services from embedded catalog")
        }

        isLoading = false

        // 3. Sync in background
        Task {
            await syncService.syncCatalogIfNeeded()
        }
    }

    private func setupObservers() {
        // Reload when catalog updates
        NotificationCenter.default.publisher(for: .catalogDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadFromCache()
            }
            .store(in: &cancellables)

        // Refresh when region changes
        NotificationCenter.default.publisher(for: .regionDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func reloadFromCache() {
        if let cachedServices = syncService.getCachedServices(), !cachedServices.isEmpty {
            services = mergeWithEmbedded(cachedServices)
            logger.info("📚 Reloaded \(self.services.count) services from updated cache")
        }
    }

    // MARK: - Public API

    /// Current region ID
    var currentRegionId: String {
        regionService.currentRegion.id
    }

    /// Current currency
    var currentCurrency: String {
        regionService.currentRegion.currency
    }

    /// All services available for current region
    var servicesForCurrentRegion: [Service] {
        services.filter { $0.isAvailable(in: currentRegionId) }
    }

    /// Services grouped by brand for current region
    var groupedByBrand: [ServiceGroup] {
        let regionServices = servicesForCurrentRegion
        let grouped = Dictionary(grouping: regionServices, by: { $0.brandName })
        return grouped.map { brandName, services in
            ServiceGroup(
                brandName: brandName,
                services: services.sorted { ($0.typicalCost ?? 0) < ($1.typicalCost ?? 0) },
                category: services.first?.category ?? .other
            )
        }.sorted { $0.brandName < $1.brandName }
    }

    /// Search services in current region
    func search(_ query: String) -> [Service] {
        guard !query.isEmpty else { return servicesForCurrentRegion }
        let lowercased = query.lowercased()
        return servicesForCurrentRegion.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.brandName.lowercased().contains(lowercased)
        }
    }

    /// Search groups in current region
    func searchGroups(_ query: String) -> [ServiceGroup] {
        guard !query.isEmpty else { return groupedByBrand }
        let lowercased = query.lowercased()
        return groupedByBrand.filter { group in
            group.brandName.lowercased().contains(lowercased) ||
            group.services.contains { $0.name.lowercased().contains(lowercased) }
        }
    }

    /// Groups for category in current region
    func groups(for category: ServiceCategory?) -> [ServiceGroup] {
        guard let category = category else { return groupedByBrand }
        return groupedByBrand.filter { $0.category == category }
    }

    /// Get price for service in current region
    func price(for service: Service, cycle: BillingCycle = .monthly) -> ServicePrice? {
        let region = regionService.currentRegion

        // 1. Exact region price
        if let regionPricing = service.pricing.first(where: { $0.region == region.id }),
           let plan = regionPricing.plans.first(where: { $0.billingCycle == cycle }) {
            return ServicePrice(
                amount: plan.price,
                currency: regionPricing.currency,
                source: plan.priceSource,
                isEstimated: false
            )
        }

        // 2. Same currency from different region
        if let sameCurrencyPricing = service.pricing.first(where: { $0.currency == region.currency }),
           let plan = sameCurrencyPricing.plans.first(where: { $0.billingCycle == cycle }) {
            return ServicePrice(
                amount: plan.price,
                currency: region.currency,
                source: .estimated,
                isEstimated: true
            )
        }

        // 3. Fallback to typicalCost (EUR) with conversion
        if let cost = service.typicalCost, cycle == service.billingCycle {
            let converted = CurrencyRates.convert(cost, from: "EUR", to: region.currency)
            return ServicePrice(
                amount: converted,
                currency: region.currency,
                source: .estimated,
                isEstimated: true
            )
        }

        return nil
    }

    /// Format price for display
    func formatPrice(_ price: ServicePrice) -> String {
        regionService.formatPrice(price.amount)
    }

    /// Find service by name
    func find(byName name: String) -> Service? {
        services.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Find service by stable ID
    func find(byServiceId serviceId: String) -> Service? {
        services.first { $0.serviceId == serviceId }
    }

    /// Get cancellation URL for current region
    func cancellationURL(for service: Service) -> String? {
        service.cancellationURL(for: currentRegionId)
    }

    /// Force sync catalog
    func forceSync() async {
        await syncService.syncCatalog()
    }

    // MARK: - Private Helpers

    private func mergeWithEmbedded(_ remote: [Service]) -> [Service] {
        var merged = remote
        let remoteIds = Set(remote.map { $0.serviceId })

        // Add embedded services not in remote
        for embedded in ServiceCatalog.allServices where !remoteIds.contains(embedded.serviceId) {
            merged.append(embedded)
        }

        return merged
    }
}

// MARK: - Service Price
struct ServicePrice: Equatable {
    let amount: Double
    let currency: String
    let source: PriceSource
    let isEstimated: Bool

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
