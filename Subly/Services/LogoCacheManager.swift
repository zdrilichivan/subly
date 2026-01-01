//
//  LogoCacheManager.swift
//  Subly
//
//  Gestisce il caching locale dei loghi dei servizi con Google Favicon
//

import UIKit
import os

class LogoCacheManager {

    // MARK: - Singleton
    static let shared = LogoCacheManager()

    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ivanzdrilich.Subly", category: "LogoCache")
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var memoryCache: [String: UIImage] = [:]

    // MARK: - Init
    private init() {
        // Usa la cartella Caches per i loghi
        let cachesPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesPath.appendingPathComponent("ServiceLogos", isDirectory: true)

        // Crea la directory se non esiste
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        logger.info("📁 Logo cache directory: \(self.cacheDirectory.path)")
    }

    // MARK: - Public Methods

    /// Ottiene il logo dalla cache (memory → disk → nil)
    func getCachedLogo(for serviceName: String) -> UIImage? {
        let key = cacheKey(for: serviceName)

        // 1. Controlla memory cache
        if let cachedImage = memoryCache[key] {
            return cachedImage
        }

        // 2. Controlla disk cache
        let filePath = cacheDirectory.appendingPathComponent("\(key).png")
        if let data = try? Data(contentsOf: filePath),
           let image = UIImage(data: data) {
            // Salva in memory cache per accessi futuri
            memoryCache[key] = image
            logger.debug("📂 Logo loaded from disk cache: \(serviceName)")
            return image
        }

        return nil
    }

    /// Salva il logo nella cache (memory + disk)
    func cacheLogo(_ image: UIImage, for serviceName: String) {
        let key = cacheKey(for: serviceName)

        // Salva in memory cache
        memoryCache[key] = image

        // Salva su disco in background
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            let filePath = self.cacheDirectory.appendingPathComponent("\(key).png")
            if let data = image.pngData() {
                try? data.write(to: filePath)
                self.logger.debug("💾 Logo saved to disk cache: \(serviceName)")
            }
        }
    }

    /// Scarica logo da Google Favicon e lo salva in cache
    func fetchAndCacheLogo(for domain: String, serviceName: String) async -> UIImage? {
        guard let url = URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=256") else {
            logger.warning("⚠️ Invalid URL for: \(serviceName)")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                logger.warning("⚠️ Failed to download logo for: \(serviceName)")
                return nil
            }

            // Salva in cache
            cacheLogo(image, for: serviceName)
            logger.info("✅ Logo cached: \(serviceName)")

            return image
        } catch {
            logger.error("❌ Error downloading logo: \(error.localizedDescription)")
            return nil
        }
    }

    /// Pulisce la cache (chiamare periodicamente o su richiesta)
    func clearCache() {
        memoryCache.removeAll()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        logger.info("🗑️ Logo cache cleared")
    }

    /// Dimensione della cache su disco
    func cacheSize() -> String {
        var size: Int64 = 0
        if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    // MARK: - Private Methods

    private func cacheKey(for serviceName: String) -> String {
        // Crea una chiave sicura per il filesystem
        return serviceName
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "+", with: "plus")
            .replacingOccurrences(of: "/", with: "_")
    }
}
