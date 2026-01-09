//
//  CatalogSyncService.swift
//  Subly
//
//  Servizio per sincronizzazione catalogo servizi da GitHub Pages
//

import Foundation
import OSLog
import Combine

// MARK: - Catalog Sync Service
class CatalogSyncService: ObservableObject {
    static let shared = CatalogSyncService()

    private let logger = Logger(subsystem: "com.ivanzdrilich.Subly", category: "CatalogSync")
    private let baseURL = "https://zdrilichivan.github.io/subly/api/v1"
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    // Published properties
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: Error?
    @Published private(set) var catalogVersion: Int = 0

    // Cache keys
    private let versionKey = "catalog_version"
    private let lastSyncKey = "catalog_last_sync"
    private let catalogFileName = "catalog.json"
    private let manifestFileName = "manifest.json"

    // Sync interval (6 hours)
    private let syncInterval: TimeInterval = 6 * 60 * 60

    // MARK: - Init

    private init() {
        let cachesPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesPath.appendingPathComponent("ServiceCatalog", isDirectory: true)

        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Load cached data
        catalogVersion = UserDefaults.standard.integer(forKey: versionKey)
        if let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            lastSyncDate = lastSync
        }

        logger.info("📦 CatalogSyncService initialized - version: \(self.catalogVersion)")
    }

    // MARK: - Public Methods

    /// Sync catalog if needed (based on last sync time)
    func syncCatalogIfNeeded() async {
        // Skip if synced recently
        if let lastSync = lastSyncDate,
           Date().timeIntervalSince(lastSync) < syncInterval {
            logger.info("📦 Catalog sync skipped - recent sync exists (\(lastSync.formatted()))")
            return
        }

        await syncCatalog()
    }

    /// Force sync catalog
    func syncCatalog() async {
        guard !isSyncing else {
            logger.info("📦 Sync already in progress")
            return
        }

        await MainActor.run {
            isSyncing = true
            syncError = nil
        }

        defer {
            Task { @MainActor in
                isSyncing = false
            }
        }

        do {
            // 1. Fetch manifest to check version
            let manifest = try await fetchManifest()

            // 2. Check if update needed
            if manifest.version <= catalogVersion {
                logger.info("📦 Catalog up to date (v\(self.catalogVersion))")
                await updateLastSyncDate()
                return
            }

            // 3. Check minimum app version if specified
            if let minVersion = manifest.minAppVersion {
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                if appVersion.compare(minVersion, options: .numeric) == .orderedAscending {
                    logger.warning("📦 Catalog requires app version \(minVersion), current: \(appVersion)")
                    // Don't fail, just skip update
                    return
                }
            }

            // 4. Download catalog
            let catalog = try await fetchCatalog()

            // 5. Save to cache
            try saveCatalogToCache(catalog)

            // 6. Update version and sync date
            await MainActor.run {
                catalogVersion = manifest.version
                UserDefaults.standard.set(manifest.version, forKey: versionKey)
            }
            await updateLastSyncDate()

            logger.info("✅ Catalog synced to v\(manifest.version) (\(catalog.services.count) services)")

            // 7. Notify listeners
            NotificationCenter.default.post(name: .catalogDidUpdate, object: nil)

        } catch {
            await MainActor.run {
                syncError = error
            }
            logger.error("❌ Catalog sync failed: \(error.localizedDescription)")
        }
    }

    /// Get cached catalog services
    func getCachedServices() -> [Service]? {
        guard let catalog = loadCatalogFromCache() else {
            return nil
        }
        return catalog.services
    }

    /// Clear cache and reset version
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory.appendingPathComponent(catalogFileName))
        UserDefaults.standard.removeObject(forKey: versionKey)
        UserDefaults.standard.removeObject(forKey: lastSyncKey)
        catalogVersion = 0
        lastSyncDate = nil
        logger.info("📦 Catalog cache cleared")
    }

    // MARK: - Private Methods

    private func fetchManifest() async throws -> CatalogManifest {
        guard let url = URL(string: "\(baseURL)/\(manifestFileName)") else {
            throw CatalogSyncError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CatalogSyncError.networkError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(CatalogManifest.self, from: data)
        } catch {
            logger.error("📦 Manifest decode error: \(error)")
            throw CatalogSyncError.parseError
        }
    }

    private func fetchCatalog() async throws -> CatalogResponse {
        guard let url = URL(string: "\(baseURL)/\(catalogFileName)") else {
            throw CatalogSyncError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CatalogSyncError.networkError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(CatalogResponse.self, from: data)
        } catch {
            logger.error("📦 Catalog decode error: \(error)")
            throw CatalogSyncError.parseError
        }
    }

    private func saveCatalogToCache(_ catalog: CatalogResponse) throws {
        let filePath = cacheDirectory.appendingPathComponent(catalogFileName)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(catalog)
        try data.write(to: filePath)
        logger.info("📦 Catalog saved to cache: \(filePath.path)")
    }

    private func loadCatalogFromCache() -> CatalogResponse? {
        let filePath = cacheDirectory.appendingPathComponent(catalogFileName)

        guard let data = try? Data(contentsOf: filePath) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(CatalogResponse.self, from: data)
        } catch {
            logger.error("📦 Cache decode error: \(error)")
            return nil
        }
    }

    private func updateLastSyncDate() async {
        let now = Date()
        await MainActor.run {
            lastSyncDate = now
        }
        UserDefaults.standard.set(now, forKey: lastSyncKey)
    }
}

// MARK: - Models

struct CatalogManifest: Codable {
    let version: Int
    let lastUpdated: Date
    let catalogHash: String?
    let minAppVersion: String?
    let regions: [String]?

    enum CodingKeys: String, CodingKey {
        case version
        case lastUpdated
        case catalogHash
        case minAppVersion
        case regions
    }
}

struct CatalogResponse: Codable {
    let version: Int
    let generatedAt: Date
    let services: [Service]

    enum CodingKeys: String, CodingKey {
        case version
        case generatedAt
        case services
    }
}

// MARK: - Errors

enum CatalogSyncError: LocalizedError {
    case invalidURL
    case networkError
    case parseError
    case noCache

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "URL catalogo non valido")
        case .networkError:
            return String(localized: "Errore di rete durante il download del catalogo")
        case .parseError:
            return String(localized: "Errore nella lettura del catalogo")
        case .noCache:
            return String(localized: "Nessun catalogo disponibile offline")
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let catalogDidUpdate = Notification.Name("catalogDidUpdate")
}
