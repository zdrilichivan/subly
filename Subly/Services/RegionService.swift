//
//  RegionService.swift
//  Subly
//
//  Servizio per rilevamento e gestione della regione dell'utente
//

import Foundation
import OSLog
import Combine

// MARK: - Region Service
@MainActor
class RegionService: ObservableObject {
    static let shared = RegionService()

    private let logger = Logger(subsystem: "com.ivanzdrilich.Subly", category: "RegionService")
    private let userDefaultsKey = "selectedRegionId"

    @Published private(set) var currentRegion: Region

    // MARK: - Init

    private init() {
        // 1. Prova a caricare regione salvata
        if let savedId = UserDefaults.standard.string(forKey: userDefaultsKey),
           let saved = Region.find(byId: savedId) {
            currentRegion = saved
            logger.info("📍 Region loaded from preferences: \(saved.id)")
        } else {
            // 2. Rileva automaticamente
            currentRegion = Self.detectRegion()
            logger.info("📍 Region auto-detected: \(self.currentRegion.id)")
        }
    }

    // MARK: - Auto Detection

    /// Rileva la regione basandosi sulle impostazioni del dispositivo
    static func detectRegion() -> Region {
        // 1. Prova dal region identifier del dispositivo
        if let regionCode = Locale.current.region?.identifier,
           let matched = Region.find(byId: regionCode) {
            return matched
        }

        // 2. Fallback basato sulla lingua
        let languageCode = Locale.current.language.languageCode?.identifier ?? "it"

        switch languageCode {
        case "en":
            // Per inglese, verifica timezone per distinguere US/UK
            let timezone = TimeZone.current.identifier
            if timezone.contains("Europe/London") || timezone.contains("GB") {
                return Region.find(byId: "UK") ?? Region.defaultRegion
            }
            return Region.find(byId: "US") ?? Region.defaultRegion

        case "es":
            // Per spagnolo, verifica timezone per distinguere ES/MX
            let timezone = TimeZone.current.identifier
            if timezone.contains("America/Mexico") || timezone.contains("Mexico") {
                return Region.find(byId: "MX") ?? Region.defaultRegion
            }
            return Region.find(byId: "ES") ?? Region.defaultRegion

        case "pt":
            return Region.find(byId: "BR") ?? Region.defaultRegion

        case "de":
            return Region.find(byId: "DE") ?? Region.defaultRegion

        case "fr":
            return Region.find(byId: "FR") ?? Region.defaultRegion

        case "it":
            return Region.find(byId: "IT") ?? Region.defaultRegion

        default:
            return Region.defaultRegion
        }
    }

    // MARK: - Manual Selection

    /// Cambia regione manualmente
    func setRegion(_ region: Region) {
        guard region.id != currentRegion.id else { return }

        currentRegion = region
        UserDefaults.standard.set(region.id, forKey: userDefaultsKey)

        logger.info("📍 Region changed to: \(region.id) (\(region.name))")

        // Notifica il cambio per aggiornare le UI
        NotificationCenter.default.post(name: .regionDidChange, object: region)
    }

    /// Resetta alla regione auto-rilevata
    func resetToAutoDetected() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        let detected = Self.detectRegion()
        currentRegion = detected

        logger.info("📍 Region reset to auto-detected: \(detected.id)")

        NotificationCenter.default.post(name: .regionDidChange, object: detected)
    }

    // MARK: - Helpers

    /// Valuta corrente
    var currency: String {
        currentRegion.currency
    }

    /// Simbolo valuta
    var currencySymbol: String {
        currentRegion.currencySymbol
    }

    /// Locale per formattazione
    var locale: Locale {
        Locale(identifier: currentRegion.locale)
    }

    /// Formatta un prezzo nella valuta corrente
    func formatPrice(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currentRegion.currency
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)\(amount)"
    }

    /// Converti prezzo dalla valuta sorgente alla valuta corrente
    func convertToCurrentCurrency(_ amount: Double, from sourceCurrency: String) -> Double {
        guard sourceCurrency != currentRegion.currency else { return amount }
        return CurrencyRates.convert(amount, from: sourceCurrency, to: currentRegion.currency)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let regionDidChange = Notification.Name("regionDidChange")
}
