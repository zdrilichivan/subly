//
//  Region.swift
//  Subly
//
//  Modello per regioni geografiche e localizzazione
//

import Foundation

// MARK: - Region Model
struct Region: Identifiable, Codable, Equatable, Hashable {
    let id: String              // ISO 3166-1 alpha-2 (es: "IT", "US")
    let name: String            // Nome inglese (es: "Italy")
    let localizedNameKey: String // Chiave per localizzazione
    let currency: String        // ISO 4217 (es: "EUR", "USD")
    let currencySymbol: String  // Simbolo (es: "€", "$")
    let locale: String          // Locale identifier (es: "it_IT")
    let flagEmoji: String       // Emoji bandiera
    let languageCode: String    // Lingua principale (es: "it", "en")

    // MARK: - Localized Name
    var localizedName: String {
        String(localized: String.LocalizationValue(localizedNameKey))
    }

    // MARK: - Supported Regions
    static let supportedRegions: [Region] = [
        Region(
            id: "IT",
            name: "Italy",
            localizedNameKey: "Italia",
            currency: "EUR",
            currencySymbol: "€",
            locale: "it_IT",
            flagEmoji: "🇮🇹",
            languageCode: "it"
        ),
        Region(
            id: "US",
            name: "United States",
            localizedNameKey: "Stati Uniti",
            currency: "USD",
            currencySymbol: "$",
            locale: "en_US",
            flagEmoji: "🇺🇸",
            languageCode: "en"
        ),
        Region(
            id: "ES",
            name: "Spain",
            localizedNameKey: "Spagna",
            currency: "EUR",
            currencySymbol: "€",
            locale: "es_ES",
            flagEmoji: "🇪🇸",
            languageCode: "es"
        ),
        Region(
            id: "UK",
            name: "United Kingdom",
            localizedNameKey: "Regno Unito",
            currency: "GBP",
            currencySymbol: "£",
            locale: "en_GB",
            flagEmoji: "🇬🇧",
            languageCode: "en"
        ),
        Region(
            id: "DE",
            name: "Germany",
            localizedNameKey: "Germania",
            currency: "EUR",
            currencySymbol: "€",
            locale: "de_DE",
            flagEmoji: "🇩🇪",
            languageCode: "de"
        ),
        Region(
            id: "FR",
            name: "France",
            localizedNameKey: "Francia",
            currency: "EUR",
            currencySymbol: "€",
            locale: "fr_FR",
            flagEmoji: "🇫🇷",
            languageCode: "fr"
        ),
        Region(
            id: "BR",
            name: "Brazil",
            localizedNameKey: "Brasile",
            currency: "BRL",
            currencySymbol: "R$",
            locale: "pt_BR",
            flagEmoji: "🇧🇷",
            languageCode: "pt"
        ),
        Region(
            id: "MX",
            name: "Mexico",
            localizedNameKey: "Messico",
            currency: "MXN",
            currencySymbol: "$",
            locale: "es_MX",
            flagEmoji: "🇲🇽",
            languageCode: "es"
        )
    ]

    // MARK: - Helpers

    /// Trova regione per ID
    static func find(byId id: String) -> Region? {
        supportedRegions.first { $0.id == id.uppercased() }
    }

    /// Regione di default (Italia)
    static var defaultRegion: Region {
        supportedRegions.first { $0.id == "IT" }!
    }

    /// Tutte le valute supportate
    static var supportedCurrencies: [String] {
        Array(Set(supportedRegions.map { $0.currency })).sorted()
    }

    /// Regioni che usano una specifica valuta
    static func regions(forCurrency currency: String) -> [Region] {
        supportedRegions.filter { $0.currency == currency }
    }
}

// MARK: - Currency Conversion Rates (static fallback)
struct CurrencyRates {
    /// Tassi di cambio approssimati rispetto all'EUR (aggiornare periodicamente)
    /// Base: EUR = 1.0
    static let rates: [String: Double] = [
        "EUR": 1.0,
        "USD": 1.08,
        "GBP": 0.86,
        "BRL": 5.40,
        "MXN": 18.50
    ]

    /// Converti un importo da una valuta all'altra
    static func convert(_ amount: Double, from: String, to: String) -> Double {
        guard let fromRate = rates[from], let toRate = rates[to] else {
            return amount
        }
        // Converti in EUR poi nella valuta target
        let inEUR = amount / fromRate
        return inEUR * toRate
    }
}
