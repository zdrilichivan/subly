//
//  ServiceCatalog.swift
//  SublySwift
//
//  Catalogo di servizi di abbonamento multi-regione
//

import Foundation
import SwiftUI

// MARK: - Price Source
enum PriceSource: String, Codable {
    case catalog = "catalog"           // Database manuale
    case userReported = "user"         // Crowdsourcing utenti
    case emailDetected = "email"       // Rilevato da email scan
    case estimated = "estimated"       // Stima/conversione valuta
}

// MARK: - Pricing Plan
struct PricingPlan: Codable, Equatable {
    let billingCycle: BillingCycle
    let price: Double
    let priceSource: PriceSource
    let lastVerified: Date?

    init(
        billingCycle: BillingCycle,
        price: Double,
        priceSource: PriceSource = .catalog,
        lastVerified: Date? = nil
    ) {
        self.billingCycle = billingCycle
        self.price = price
        self.priceSource = priceSource
        self.lastVerified = lastVerified
    }
}

// MARK: - Region Pricing
struct RegionPricing: Codable, Equatable {
    let region: String      // "IT", "US", etc.
    let currency: String    // "EUR", "USD", etc.
    let plans: [PricingPlan]

    init(region: String, currency: String, plans: [PricingPlan]) {
        self.region = region
        self.currency = currency
        self.plans = plans
    }

    /// Ottiene il prezzo per un ciclo specifico
    func price(for cycle: BillingCycle) -> PricingPlan? {
        plans.first { $0.billingCycle == cycle }
    }
}

// MARK: - Service Model
struct Service: Identifiable, Equatable, Codable {
    let id: UUID
    let serviceId: String           // ID stabile per sync (es: "netflix_standard")
    let name: String
    let category: ServiceCategory
    let iconName: String
    let domain: String?             // Per fetch icone (es: "netflix.com")
    let typicalCost: Double?        // Costo legacy (EUR) - mantiene retrocompatibilità
    let billingCycle: BillingCycle
    let cancellationURL: String?
    let brandName: String           // Nome del brand (es. "Netflix")
    let variantName: String?        // Nome della variante (es. "Standard", "Premium")

    // Multi-region support
    let availableRegions: [String]  // ["*"] = globale, ["IT", "UK"] = specifico
    let pricing: [RegionPricing]    // Prezzi per regione
    let cancellationURLs: [String: String]? // URL per regione: ["IT": "url", "US": "url"]

    // MARK: - Init (retrocompatibile)
    init(
        id: UUID = UUID(),
        serviceId: String? = nil,
        name: String,
        category: ServiceCategory,
        iconName: String = "",
        domain: String? = nil,
        typicalCost: Double? = nil,
        billingCycle: BillingCycle = .monthly,
        cancellationURL: String? = nil,
        brandName: String? = nil,
        variantName: String? = nil,
        availableRegions: [String] = ["*"],
        pricing: [RegionPricing] = [],
        cancellationURLs: [String: String]? = nil
    ) {
        self.id = id
        self.serviceId = serviceId ?? name.slugified
        self.name = name
        self.category = category
        self.iconName = iconName.isEmpty ? category.iconName : iconName
        self.domain = domain
        self.typicalCost = typicalCost
        self.billingCycle = billingCycle
        self.cancellationURL = cancellationURL
        self.brandName = brandName ?? name
        self.variantName = variantName
        self.availableRegions = availableRegions
        self.pricing = pricing
        self.cancellationURLs = cancellationURLs
    }

    // MARK: - Region Helpers

    /// Verifica se il servizio è disponibile in una regione
    func isAvailable(in regionId: String) -> Bool {
        availableRegions.contains("*") || availableRegions.contains(regionId.uppercased())
    }

    /// Ottiene il prezzo per una regione specifica
    func price(for regionId: String, cycle: BillingCycle = .monthly) -> PricingPlan? {
        // Cerca prezzo esatto per regione
        if let regionPricing = pricing.first(where: { $0.region == regionId }) {
            return regionPricing.price(for: cycle)
        }
        // Fallback: usa typicalCost come EUR
        if let cost = typicalCost, cycle == billingCycle {
            return PricingPlan(billingCycle: billingCycle, price: cost, priceSource: .catalog)
        }
        return nil
    }

    /// Ottiene l'URL di cancellazione per una regione
    func cancellationURL(for regionId: String) -> String? {
        cancellationURLs?[regionId] ?? cancellationURL
    }
}

// MARK: - String Extension for Service ID
extension String {
    var slugified: String {
        self.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "+", with: "plus")
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")).inverted)
            .joined()
    }
}

// MARK: - Service Group (per raggruppare varianti)
struct ServiceGroup: Identifiable {
    let id = UUID()
    let brandName: String
    let services: [Service]
    let category: ServiceCategory

    var iconName: String {
        services.first?.iconName ?? category.iconName
    }

    var hasMultipleVariants: Bool {
        services.count > 1
    }

    var singleService: Service? {
        services.count == 1 ? services.first : nil
    }
}

// MARK: - Service Catalog
struct ServiceCatalog {

    // MARK: - All Services (80+)
    static let allServices: [Service] = [
        // MARK: Streaming Video
        // Netflix - tutti i piani
        Service(name: "Netflix Standard con pubblicità", category: .streaming, iconName: "play.tv.fill", typicalCost: 6.99, cancellationURL: "https://www.netflix.com/cancelplan", brandName: "Netflix", variantName: "Standard con pubblicità"),
        Service(name: "Netflix Standard", category: .streaming, iconName: "play.tv.fill", typicalCost: 13.99, cancellationURL: "https://www.netflix.com/cancelplan", brandName: "Netflix", variantName: "Standard"),
        Service(name: "Netflix Premium", category: .streaming, iconName: "play.tv.fill", typicalCost: 18.99, cancellationURL: "https://www.netflix.com/cancelplan", brandName: "Netflix", variantName: "Premium"),

        // Disney+ - tutti i piani
        Service(name: "Disney+ Standard con pubblicità", category: .streaming, iconName: "play.tv.fill", typicalCost: 5.99, cancellationURL: "https://www.disneyplus.com/account/subscription", brandName: "Disney+", variantName: "Standard con pubblicità"),
        Service(name: "Disney+ Standard", category: .streaming, iconName: "play.tv.fill", typicalCost: 8.99, cancellationURL: "https://www.disneyplus.com/account/subscription", brandName: "Disney+", variantName: "Standard"),
        Service(name: "Disney+ Premium", category: .streaming, iconName: "play.tv.fill", typicalCost: 11.99, cancellationURL: "https://www.disneyplus.com/account/subscription", brandName: "Disney+", variantName: "Premium"),
        Service(name: "NOW TV", category: .streaming, iconName: "play.tv.fill", typicalCost: 14.99, cancellationURL: "https://www.nowtv.it/account"),
        Service(name: "Sky Go", category: .streaming, iconName: "play.tv.fill", typicalCost: 29.90, cancellationURL: "https://www.sky.it/assistenza/info-disdette"),
        Service(name: "DAZN", category: .streaming, iconName: "sportscourt.fill", typicalCost: 29.99, cancellationURL: "https://www.dazn.com/it-IT/account/subscription"),
        Service(name: "Apple TV+", category: .streaming, iconName: "appletv.fill", typicalCost: 9.99, cancellationURL: "https://support.apple.com/it-it/HT202039"),
        Service(name: "Paramount+", category: .streaming, iconName: "play.tv.fill", typicalCost: 7.99, cancellationURL: "https://www.paramountplus.com/account/"),
        Service(name: "Discovery+", category: .streaming, iconName: "play.tv.fill", typicalCost: 3.99, cancellationURL: "https://www.discoveryplus.com/it/account"),
        Service(name: "Infinity+", category: .streaming, iconName: "play.tv.fill", typicalCost: 7.99, cancellationURL: "https://www.infinitytv.it/account"),
        Service(name: "RaiPlay", category: .streaming, iconName: "play.tv.fill", typicalCost: 0),
        Service(name: "TimVision", category: .streaming, iconName: "play.tv.fill", typicalCost: 6.99, cancellationURL: "https://www.tim.it/assistenza"),
        Service(name: "Crunchyroll", category: .streaming, iconName: "play.tv.fill", typicalCost: 4.99, cancellationURL: "https://www.crunchyroll.com/account/subscription"),
        Service(name: "MUBI", category: .streaming, iconName: "film.fill", typicalCost: 10.99, cancellationURL: "https://mubi.com/account"),
        Service(name: "Chili", category: .streaming, iconName: "play.tv.fill", typicalCost: 7.99, cancellationURL: "https://it.chili.com/account"),
        Service(name: "YouTube Premium", category: .streaming, iconName: "play.rectangle.fill", typicalCost: 11.99, cancellationURL: "https://www.youtube.com/paid_memberships"),

        // MARK: Musica
        // Spotify - tutti i piani
        Service(name: "Spotify Individual", category: .music, iconName: "music.note", typicalCost: 10.99, cancellationURL: "https://www.spotify.com/it/account/subscription/", brandName: "Spotify", variantName: "Individual"),
        Service(name: "Spotify Duo", category: .music, iconName: "music.note", typicalCost: 14.99, cancellationURL: "https://www.spotify.com/it/account/subscription/", brandName: "Spotify", variantName: "Duo"),
        Service(name: "Spotify Family", category: .music, iconName: "music.note", typicalCost: 17.99, cancellationURL: "https://www.spotify.com/it/account/subscription/", brandName: "Spotify", variantName: "Family"),
        Service(name: "Spotify Student", category: .music, iconName: "music.note", typicalCost: 5.99, cancellationURL: "https://www.spotify.com/it/account/subscription/", brandName: "Spotify", variantName: "Student"),

        // Apple Music - tutti i piani
        Service(name: "Apple Music Individuale", category: .music, iconName: "music.note", typicalCost: 10.99, cancellationURL: "https://support.apple.com/it-it/HT202039", brandName: "Apple Music", variantName: "Individuale"),
        Service(name: "Apple Music Famiglia", category: .music, iconName: "music.note", typicalCost: 16.99, cancellationURL: "https://support.apple.com/it-it/HT202039", brandName: "Apple Music", variantName: "Famiglia"),
        Service(name: "Apple Music Studenti", category: .music, iconName: "music.note", typicalCost: 5.99, cancellationURL: "https://support.apple.com/it-it/HT202039", brandName: "Apple Music", variantName: "Studenti"),
        Service(name: "Amazon Music Unlimited", category: .music, iconName: "music.note", typicalCost: 9.99, cancellationURL: "https://www.amazon.it/music/settings"),
        Service(name: "YouTube Music", category: .music, iconName: "music.note", typicalCost: 9.99, cancellationURL: "https://www.youtube.com/paid_memberships"),
        Service(name: "Deezer", category: .music, iconName: "music.note", typicalCost: 10.99, cancellationURL: "https://www.deezer.com/account/subscription"),
        Service(name: "Tidal", category: .music, iconName: "music.note", typicalCost: 10.99, cancellationURL: "https://tidal.com/settings/subscription"),
        Service(name: "SoundCloud Go+", category: .music, iconName: "music.note", typicalCost: 9.99, cancellationURL: "https://soundcloud.com/settings/subscription"),
        Service(name: "Audible", category: .music, iconName: "book.fill", typicalCost: 9.99, cancellationURL: "https://www.audible.it/account/overview"),
        Service(name: "Storytel", category: .music, iconName: "book.fill", typicalCost: 9.99, cancellationURL: "https://www.storytel.com/it/it/account"),

        // MARK: Software & Productivity
        Service(name: "Microsoft 365", category: .software, iconName: "doc.fill", typicalCost: 7.00, cancellationURL: "https://account.microsoft.com/services"),
        Service(name: "Adobe Creative Cloud", category: .software, iconName: "paintbrush.fill", typicalCost: 62.99, cancellationURL: "https://account.adobe.com/plans"),
        Service(name: "Adobe Photoshop", category: .software, iconName: "paintbrush.fill", typicalCost: 26.64, cancellationURL: "https://account.adobe.com/plans"),
        Service(name: "Adobe Lightroom", category: .software, iconName: "camera.fill", typicalCost: 12.19, cancellationURL: "https://account.adobe.com/plans"),
        Service(name: "Notion", category: .software, iconName: "doc.text.fill", typicalCost: 10.00, cancellationURL: "https://www.notion.so/my-account"),
        Service(name: "Evernote", category: .software, iconName: "note.text", typicalCost: 8.99, cancellationURL: "https://www.evernote.com/Settings.action"),
        Service(name: "Dropbox", category: .software, iconName: "externaldrive.fill", typicalCost: 11.99, cancellationURL: "https://www.dropbox.com/account/plan"),
        Service(name: "1Password", category: .software, iconName: "lock.fill", typicalCost: 2.99, cancellationURL: "https://my.1password.com/settings/billing"),
        Service(name: "LastPass", category: .software, iconName: "lock.fill", typicalCost: 2.90, cancellationURL: "https://lastpass.com/account.php"),
        Service(name: "Dashlane", category: .software, iconName: "lock.fill", typicalCost: 3.33, cancellationURL: "https://app.dashlane.com/settings/subscription"),
        Service(name: "NordVPN", category: .software, iconName: "network", typicalCost: 4.99, cancellationURL: "https://my.nordaccount.com/dashboard/nordvpn/"),
        Service(name: "ExpressVPN", category: .software, iconName: "network", typicalCost: 8.32, cancellationURL: "https://www.expressvpn.com/subscriptions"),
        Service(name: "Surfshark", category: .software, iconName: "network", typicalCost: 2.49, cancellationURL: "https://my.surfshark.com/account/subscription"),
        Service(name: "Canva Pro", category: .software, iconName: "paintpalette.fill", typicalCost: 11.99, cancellationURL: "https://www.canva.com/settings/billing"),
        Service(name: "Figma", category: .software, iconName: "pencil.and.ruler.fill", typicalCost: 12.00, cancellationURL: "https://www.figma.com/settings"),
        Service(name: "Sketch", category: .software, iconName: "pencil.and.ruler.fill", typicalCost: 9.00, cancellationURL: "https://www.sketch.com/account/"),
        Service(name: "Slack", category: .software, iconName: "message.fill", typicalCost: 7.25, cancellationURL: "https://slack.com/account/settings"),
        Service(name: "Zoom", category: .software, iconName: "video.fill", typicalCost: 13.99, cancellationURL: "https://zoom.us/account"),
        Service(name: "ChatGPT Plus", category: .software, iconName: "bubble.left.fill", typicalCost: 20.00, cancellationURL: "https://chat.openai.com/settings/subscription"),
        Service(name: "Claude Pro", category: .software, iconName: "bubble.left.fill", typicalCost: 20.00, cancellationURL: "https://claude.ai/settings"),
        Service(name: "Grammarly", category: .software, iconName: "textformat", typicalCost: 12.00, cancellationURL: "https://account.grammarly.com/subscription"),
        Service(name: "Todoist", category: .software, iconName: "checklist", typicalCost: 4.00, cancellationURL: "https://todoist.com/app/settings/subscription"),

        // MARK: Fitness
        Service(name: "Apple Fitness+", category: .fitness, iconName: "figure.run", typicalCost: 9.99, cancellationURL: "https://support.apple.com/it-it/HT202039"),
        Service(name: "Peloton", category: .fitness, iconName: "bicycle", typicalCost: 12.99, cancellationURL: "https://members.onepeloton.com/preferences/subscriptions"),
        Service(name: "Nike Training Club", category: .fitness, iconName: "figure.strengthtraining.traditional", typicalCost: 9.99, cancellationURL: "https://www.nike.com/it/member/settings"),
        Service(name: "Strava", category: .fitness, iconName: "figure.run", typicalCost: 5.00, cancellationURL: "https://www.strava.com/settings/subscription"),
        Service(name: "MyFitnessPal", category: .fitness, iconName: "heart.fill", typicalCost: 9.99, cancellationURL: "https://www.myfitnesspal.com/account/subscriptions"),
        Service(name: "Headspace", category: .fitness, iconName: "brain.head.profile", typicalCost: 12.99, cancellationURL: "https://www.headspace.com/settings/subscription"),
        Service(name: "Calm", category: .fitness, iconName: "leaf.fill", typicalCost: 14.99, cancellationURL: "https://www.calm.com/account"),
        Service(name: "Freeletics", category: .fitness, iconName: "figure.highintensity.intervaltraining", typicalCost: 7.49, cancellationURL: "https://www.freeletics.com/it/account"),
        Service(name: "Fitbit Premium", category: .fitness, iconName: "heart.fill", typicalCost: 8.99, cancellationURL: "https://www.fitbit.com/settings/subscription"),
        Service(name: "SWEAT", category: .fitness, iconName: "figure.dance", typicalCost: 19.99, cancellationURL: "https://sweat.com/account"),

        // MARK: Cloud Storage
        Service(name: "iCloud+ 50GB", category: .cloud, iconName: "icloud.fill", typicalCost: 0.99, cancellationURL: "https://support.apple.com/it-it/HT202039", brandName: "iCloud+", variantName: "50GB"),
        Service(name: "iCloud+ 200GB", category: .cloud, iconName: "icloud.fill", typicalCost: 2.99, cancellationURL: "https://support.apple.com/it-it/HT202039", brandName: "iCloud+", variantName: "200GB"),
        Service(name: "iCloud+ 2TB", category: .cloud, iconName: "icloud.fill", typicalCost: 9.99, cancellationURL: "https://support.apple.com/it-it/HT202039", brandName: "iCloud+", variantName: "2TB"),
        Service(name: "Google One 100GB", category: .cloud, iconName: "cloud.fill", typicalCost: 1.99, cancellationURL: "https://one.google.com/settings", brandName: "Google One", variantName: "100GB"),
        Service(name: "Google One 200GB", category: .cloud, iconName: "cloud.fill", typicalCost: 2.99, cancellationURL: "https://one.google.com/settings", brandName: "Google One", variantName: "200GB"),
        Service(name: "Google One 2TB", category: .cloud, iconName: "cloud.fill", typicalCost: 9.99, cancellationURL: "https://one.google.com/settings", brandName: "Google One", variantName: "2TB"),
        Service(name: "OneDrive 100GB", category: .cloud, iconName: "cloud.fill", typicalCost: 2.00, cancellationURL: "https://account.microsoft.com/services"),
        Service(name: "pCloud", category: .cloud, iconName: "cloud.fill", typicalCost: 4.99, cancellationURL: "https://www.pcloud.com/settings/"),

        // MARK: News & Media
        Service(name: "Corriere della Sera", category: .news, iconName: "newspaper.fill", typicalCost: 9.99, cancellationURL: "https://www.corriere.it/digitalcorr/abbonamenti/"),
        Service(name: "La Repubblica", category: .news, iconName: "newspaper.fill", typicalCost: 9.99, cancellationURL: "https://www.repubblica.it/servizi/profilo/"),
        Service(name: "Il Sole 24 Ore", category: .news, iconName: "newspaper.fill", typicalCost: 14.99, cancellationURL: "https://www.ilsole24ore.com/area-utente"),
        Service(name: "La Stampa", category: .news, iconName: "newspaper.fill", typicalCost: 9.99, cancellationURL: "https://www.lastampa.it/profilo/"),
        Service(name: "The Economist", category: .news, iconName: "newspaper.fill", typicalCost: 25.00, cancellationURL: "https://myaccount.economist.com/s/"),
        Service(name: "Financial Times", category: .news, iconName: "newspaper.fill", typicalCost: 35.00, cancellationURL: "https://myaccount.ft.com/"),
        Service(name: "Wall Street Journal", category: .news, iconName: "newspaper.fill", typicalCost: 38.99, cancellationURL: "https://customercenter.wsj.com/"),
        Service(name: "New York Times", category: .news, iconName: "newspaper.fill", typicalCost: 4.00, cancellationURL: "https://myaccount.nytimes.com/seg/subscription"),
        Service(name: "Medium", category: .news, iconName: "text.book.closed.fill", typicalCost: 5.00, cancellationURL: "https://medium.com/me/settings"),
        Service(name: "Substack", category: .news, iconName: "envelope.fill", typicalCost: 5.00, cancellationURL: "https://substack.com/account/settings"),

        // MARK: Gaming
        Service(name: "PlayStation Plus Essential", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 8.99, cancellationURL: "https://www.playstation.com/it-it/support/store/cancel-ps-store-subscription/", brandName: "PlayStation Plus", variantName: "Essential"),
        Service(name: "PlayStation Plus Extra", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 13.99, cancellationURL: "https://www.playstation.com/it-it/support/store/cancel-ps-store-subscription/", brandName: "PlayStation Plus", variantName: "Extra"),
        Service(name: "PlayStation Plus Premium", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 16.99, cancellationURL: "https://www.playstation.com/it-it/support/store/cancel-ps-store-subscription/", brandName: "PlayStation Plus", variantName: "Premium"),
        Service(name: "Xbox Game Pass Core", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 6.99, cancellationURL: "https://account.microsoft.com/services", brandName: "Xbox Game Pass", variantName: "Core"),
        Service(name: "Xbox Game Pass Standard", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 12.99, cancellationURL: "https://account.microsoft.com/services", brandName: "Xbox Game Pass", variantName: "Standard"),
        Service(name: "Xbox Game Pass Ultimate", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 14.99, cancellationURL: "https://account.microsoft.com/services", brandName: "Xbox Game Pass", variantName: "Ultimate"),
        Service(name: "Nintendo Switch Online", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 3.99, cancellationURL: "https://accounts.nintendo.com/shop/subscription"),
        Service(name: "EA Play", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 4.99, cancellationURL: "https://myaccount.ea.com/cp-ui/subscriptions"),
        Service(name: "Ubisoft+", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 14.99, cancellationURL: "https://store.ubi.com/account"),
        Service(name: "Apple Arcade", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 6.99, cancellationURL: "https://support.apple.com/it-it/HT202039"),
        Service(name: "GeForce NOW", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 9.99, cancellationURL: "https://www.nvidia.com/it-it/account/"),
        Service(name: "Twitch Turbo", category: .gaming, iconName: "video.fill", typicalCost: 8.99, cancellationURL: "https://www.twitch.tv/subscriptions"),

        // MARK: Telefonia
        Service(name: "TIM Mobile", category: .phone, iconName: "phone.fill", typicalCost: 9.99, cancellationURL: "https://www.tim.it/assistenza/gestione-linea"),
        Service(name: "Vodafone Mobile", category: .phone, iconName: "phone.fill", typicalCost: 9.99, cancellationURL: "https://www.vodafone.it/portal/Privati/Supporto/"),
        Service(name: "WindTre Mobile", category: .phone, iconName: "phone.fill", typicalCost: 9.99, cancellationURL: "https://www.windtre.it/assistenza/"),
        Service(name: "Iliad", category: .phone, iconName: "phone.fill", typicalCost: 9.99, cancellationURL: "https://www.iliad.it/account/"),
        Service(name: "Fastweb Mobile", category: .phone, iconName: "phone.fill", typicalCost: 7.95, cancellationURL: "https://www.fastweb.it/myfastweb/"),
        Service(name: "PosteMobile", category: .phone, iconName: "phone.fill", typicalCost: 6.99, cancellationURL: "https://www.postemobile.it/area-personale"),
        Service(name: "ho. Mobile", category: .phone, iconName: "phone.fill", typicalCost: 6.99, cancellationURL: "https://www.ho-mobile.it/area-personale/"),
        Service(name: "Kena Mobile", category: .phone, iconName: "phone.fill", typicalCost: 5.99, cancellationURL: "https://www.kenamobile.it/area-clienti/"),
        Service(name: "Very Mobile", category: .phone, iconName: "phone.fill", typicalCost: 5.99, cancellationURL: "https://www.verymobile.it/area-personale/"),
        Service(name: "Spusu", category: .phone, iconName: "phone.fill", typicalCost: 5.98, cancellationURL: "https://www.spusu.it/area-clienti"),
        Service(name: "TIM Fisso", category: .phone, iconName: "wifi", typicalCost: 29.90, cancellationURL: "https://www.tim.it/assistenza/gestione-linea"),
        Service(name: "Vodafone Fisso", category: .phone, iconName: "wifi", typicalCost: 29.90, cancellationURL: "https://www.vodafone.it/portal/Privati/Supporto/"),
        Service(name: "WindTre Fisso", category: .phone, iconName: "wifi", typicalCost: 26.99, cancellationURL: "https://www.windtre.it/assistenza/"),
        Service(name: "Fastweb Fisso", category: .phone, iconName: "wifi", typicalCost: 27.95, cancellationURL: "https://www.fastweb.it/myfastweb/"),
        Service(name: "Sky WiFi", category: .phone, iconName: "wifi", typicalCost: 29.90, cancellationURL: "https://www.sky.it/assistenza/info-disdette"),

        // MARK: Altro
        // Amazon Prime - varianti mensile/annuale
        Service(
            name: "Amazon Prime Mensile",
            category: .other,
            iconName: "shippingbox.fill",
            domain: "amazon.com",
            typicalCost: 4.99,
            billingCycle: .monthly,
            brandName: "Amazon Prime",
            variantName: "Mensile",
            pricing: [
                RegionPricing(region: "IT", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 4.99)]),
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 14.99)]),
                RegionPricing(region: "UK", currency: "GBP", plans: [PricingPlan(billingCycle: .monthly, price: 8.99)]),
                RegionPricing(region: "DE", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 8.99)]),
                RegionPricing(region: "ES", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 4.99)]),
                RegionPricing(region: "FR", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 6.99)]),
                RegionPricing(region: "BR", currency: "BRL", plans: [PricingPlan(billingCycle: .monthly, price: 19.90)]),
                RegionPricing(region: "MX", currency: "MXN", plans: [PricingPlan(billingCycle: .monthly, price: 99.00)])
            ],
            cancellationURLs: [
                "IT": "https://www.amazon.it/gp/primecentral",
                "US": "https://www.amazon.com/gp/primecentral",
                "UK": "https://www.amazon.co.uk/gp/primecentral",
                "DE": "https://www.amazon.de/gp/primecentral",
                "ES": "https://www.amazon.es/gp/primecentral",
                "FR": "https://www.amazon.fr/gp/primecentral",
                "BR": "https://www.amazon.com.br/gp/primecentral",
                "MX": "https://www.amazon.com.mx/gp/primecentral"
            ]
        ),
        Service(
            name: "Amazon Prime Annuale",
            category: .other,
            iconName: "shippingbox.fill",
            domain: "amazon.com",
            typicalCost: 49.90,
            billingCycle: .yearly,
            brandName: "Amazon Prime",
            variantName: "Annuale",
            pricing: [
                RegionPricing(region: "IT", currency: "EUR", plans: [PricingPlan(billingCycle: .yearly, price: 49.90)]),
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .yearly, price: 139.00)]),
                RegionPricing(region: "UK", currency: "GBP", plans: [PricingPlan(billingCycle: .yearly, price: 95.00)]),
                RegionPricing(region: "DE", currency: "EUR", plans: [PricingPlan(billingCycle: .yearly, price: 89.90)]),
                RegionPricing(region: "ES", currency: "EUR", plans: [PricingPlan(billingCycle: .yearly, price: 49.90)]),
                RegionPricing(region: "FR", currency: "EUR", plans: [PricingPlan(billingCycle: .yearly, price: 69.90)]),
                RegionPricing(region: "BR", currency: "BRL", plans: [PricingPlan(billingCycle: .yearly, price: 166.80)]),
                RegionPricing(region: "MX", currency: "MXN", plans: [PricingPlan(billingCycle: .yearly, price: 899.00)])
            ],
            cancellationURLs: [
                "IT": "https://www.amazon.it/gp/primecentral",
                "US": "https://www.amazon.com/gp/primecentral",
                "UK": "https://www.amazon.co.uk/gp/primecentral"
            ]
        ),
        Service(name: "Deliveroo Plus", category: .other, iconName: "bag.fill", domain: "deliveroo.com", typicalCost: 3.99, cancellationURL: "https://deliveroo.it/account/subscription", availableRegions: ["IT", "UK", "FR", "ES", "DE"]),
        Service(name: "Glovo Prime", category: .other, iconName: "bag.fill", domain: "glovoapp.com", typicalCost: 5.99, cancellationURL: "https://glovoapp.com/it/profile/", availableRegions: ["IT", "ES"]),
        Service(name: "Just Eat Plus", category: .other, iconName: "bag.fill", domain: "justeat.com", typicalCost: 4.99, cancellationURL: "https://www.justeat.it/account/", availableRegions: ["IT", "UK"]),
        Service(name: "Satispay", category: .other, iconName: "creditcard.fill", domain: "satispay.com", typicalCost: 0, availableRegions: ["IT"]),
        Service(name: "Revolut Premium", category: .other, iconName: "creditcard.fill", domain: "revolut.com", typicalCost: 7.99, cancellationURL: "https://app.revolut.com/settings/subscription"),
        Service(name: "N26 You", category: .other, iconName: "creditcard.fill", domain: "n26.com", typicalCost: 9.90, cancellationURL: "https://app.n26.com/settings/membership", availableRegions: ["IT", "DE", "ES", "FR"]),
        Service(name: "Enjoy", category: .other, iconName: "car.fill", typicalCost: 0, availableRegions: ["IT"]),
        Service(name: "ShareNow", category: .other, iconName: "car.fill", domain: "share-now.com", typicalCost: 0, cancellationURL: "https://www.share-now.com/it/it/account/", availableRegions: ["IT", "DE", "FR", "ES"]),
        Service(name: "Altro", category: .other, iconName: "square.grid.2x2.fill", typicalCost: nil),

        // MARK: - Servizi Regionali US
        // HBO Max (US, ES, MX, BR)
        Service(
            name: "HBO Max",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "max.com",
            typicalCost: 15.99,
            availableRegions: ["US", "ES", "MX", "BR"],
            pricing: [
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 15.99)]),
                RegionPricing(region: "ES", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 13.99)]),
                RegionPricing(region: "MX", currency: "MXN", plans: [PricingPlan(billingCycle: .monthly, price: 199.00)]),
                RegionPricing(region: "BR", currency: "BRL", plans: [PricingPlan(billingCycle: .monthly, price: 34.90)])
            ],
            cancellationURLs: ["US": "https://www.max.com/account"]
        ),
        Service(
            name: "Hulu",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "hulu.com",
            typicalCost: 7.99,
            availableRegions: ["US"],
            pricing: [
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 7.99)])
            ],
            cancellationURLs: ["US": "https://secure.hulu.com/account"]
        ),
        Service(
            name: "Peacock",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "peacocktv.com",
            typicalCost: 5.99,
            availableRegions: ["US", "UK"],
            pricing: [
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 5.99)]),
                RegionPricing(region: "UK", currency: "GBP", plans: [PricingPlan(billingCycle: .monthly, price: 4.99)])
            ],
            cancellationURLs: ["US": "https://www.peacocktv.com/account"]
        ),
        Service(
            name: "ESPN+",
            category: .streaming,
            iconName: "sportscourt.fill",
            domain: "espn.com",
            typicalCost: 10.99,
            availableRegions: ["US"],
            pricing: [
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 10.99)])
            ],
            cancellationURLs: ["US": "https://plus.espn.com/account"]
        ),

        // MARK: - Servizi Regionali UK
        Service(
            name: "BBC iPlayer",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "bbc.co.uk",
            typicalCost: 0,
            availableRegions: ["UK"]
        ),
        Service(
            name: "NOW TV",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "nowtv.com",
            typicalCost: 9.99,
            availableRegions: ["UK"],
            pricing: [
                RegionPricing(region: "UK", currency: "GBP", plans: [PricingPlan(billingCycle: .monthly, price: 9.99)])
            ],
            cancellationURLs: ["UK": "https://www.nowtv.com/account"]
        ),
        Service(
            name: "BritBox",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "britbox.com",
            typicalCost: 5.99,
            availableRegions: ["UK", "US"],
            pricing: [
                RegionPricing(region: "UK", currency: "GBP", plans: [PricingPlan(billingCycle: .monthly, price: 5.99)]),
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 8.99)])
            ],
            cancellationURLs: ["UK": "https://www.britbox.com/account"]
        ),

        // MARK: - Servizi Regionali ES
        Service(
            name: "Movistar+",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "movistarplus.es",
            typicalCost: 10.00,
            availableRegions: ["ES"],
            pricing: [
                RegionPricing(region: "ES", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 10.00)])
            ],
            cancellationURLs: ["ES": "https://www.movistar.es/particulares/"]
        ),
        Service(
            name: "Orange TV",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "orange.es",
            typicalCost: 7.00,
            availableRegions: ["ES", "FR"],
            pricing: [
                RegionPricing(region: "ES", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 7.00)]),
                RegionPricing(region: "FR", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 9.99)])
            ]
        ),

        // MARK: - Servizi Regionali BR
        Service(
            name: "Globoplay",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "globoplay.globo.com",
            typicalCost: 24.90,
            availableRegions: ["BR"],
            pricing: [
                RegionPricing(region: "BR", currency: "BRL", plans: [PricingPlan(billingCycle: .monthly, price: 24.90)])
            ],
            cancellationURLs: ["BR": "https://globoplay.globo.com/minha-conta"]
        ),
        Service(
            name: "Telecine",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "telecineplay.com.br",
            typicalCost: 37.90,
            availableRegions: ["BR"],
            pricing: [
                RegionPricing(region: "BR", currency: "BRL", plans: [PricingPlan(billingCycle: .monthly, price: 37.90)])
            ]
        ),

        // MARK: - Servizi Regionali MX
        Service(
            name: "Blim",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "blim.com",
            typicalCost: 109.00,
            availableRegions: ["MX"],
            pricing: [
                RegionPricing(region: "MX", currency: "MXN", plans: [PricingPlan(billingCycle: .monthly, price: 109.00)])
            ]
        ),
        Service(
            name: "Claro Video",
            category: .streaming,
            iconName: "play.tv.fill",
            domain: "clarovideo.com",
            typicalCost: 99.00,
            availableRegions: ["MX", "BR"],
            pricing: [
                RegionPricing(region: "MX", currency: "MXN", plans: [PricingPlan(billingCycle: .monthly, price: 99.00)]),
                RegionPricing(region: "BR", currency: "BRL", plans: [PricingPlan(billingCycle: .monthly, price: 19.90)])
            ]
        ),

        // MARK: - Apple One (varianti globali)
        Service(
            name: "Apple One Individual",
            category: .software,
            iconName: "apple.logo",
            domain: "apple.com",
            typicalCost: 19.95,
            brandName: "Apple One",
            variantName: "Individual",
            pricing: [
                RegionPricing(region: "IT", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 19.95)]),
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 19.95)]),
                RegionPricing(region: "UK", currency: "GBP", plans: [PricingPlan(billingCycle: .monthly, price: 18.95)])
            ],
            cancellationURLs: ["IT": "https://support.apple.com/it-it/HT202039"]
        ),
        Service(
            name: "Apple One Family",
            category: .software,
            iconName: "apple.logo",
            domain: "apple.com",
            typicalCost: 25.95,
            brandName: "Apple One",
            variantName: "Family",
            pricing: [
                RegionPricing(region: "IT", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 25.95)]),
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 25.95)]),
                RegionPricing(region: "UK", currency: "GBP", plans: [PricingPlan(billingCycle: .monthly, price: 24.95)])
            ],
            cancellationURLs: ["IT": "https://support.apple.com/it-it/HT202039"]
        ),
        Service(
            name: "Apple One Premier",
            category: .software,
            iconName: "apple.logo",
            domain: "apple.com",
            typicalCost: 34.95,
            brandName: "Apple One",
            variantName: "Premier",
            availableRegions: ["US", "UK"],
            pricing: [
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 37.95)]),
                RegionPricing(region: "UK", currency: "GBP", plans: [PricingPlan(billingCycle: .monthly, price: 34.95)])
            ],
            cancellationURLs: ["US": "https://support.apple.com/en-us/HT202039"]
        ),

        // MARK: - YouTube Premium (varianti)
        Service(
            name: "YouTube Premium Individual",
            category: .streaming,
            iconName: "play.rectangle.fill",
            domain: "youtube.com",
            typicalCost: 11.99,
            brandName: "YouTube Premium",
            variantName: "Individual",
            pricing: [
                RegionPricing(region: "IT", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 11.99)]),
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 13.99)]),
                RegionPricing(region: "UK", currency: "GBP", plans: [PricingPlan(billingCycle: .monthly, price: 12.99)])
            ],
            cancellationURLs: ["IT": "https://www.youtube.com/paid_memberships"]
        ),
        Service(
            name: "YouTube Premium Family",
            category: .streaming,
            iconName: "play.rectangle.fill",
            domain: "youtube.com",
            typicalCost: 17.99,
            brandName: "YouTube Premium",
            variantName: "Family",
            pricing: [
                RegionPricing(region: "IT", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 17.99)]),
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 22.99)]),
                RegionPricing(region: "UK", currency: "GBP", plans: [PricingPlan(billingCycle: .monthly, price: 19.99)])
            ],
            cancellationURLs: ["IT": "https://www.youtube.com/paid_memberships"]
        ),
        Service(
            name: "YouTube Premium Student",
            category: .streaming,
            iconName: "play.rectangle.fill",
            domain: "youtube.com",
            typicalCost: 6.99,
            brandName: "YouTube Premium",
            variantName: "Student",
            pricing: [
                RegionPricing(region: "IT", currency: "EUR", plans: [PricingPlan(billingCycle: .monthly, price: 6.99)]),
                RegionPricing(region: "US", currency: "USD", plans: [PricingPlan(billingCycle: .monthly, price: 7.99)])
            ],
            cancellationURLs: ["IT": "https://www.youtube.com/paid_memberships"]
        ),
    ]

    // MARK: - Grouped by Category
    static var groupedByCategory: [ServiceCategory: [Service]] {
        Dictionary(grouping: allServices, by: { $0.category })
    }

    // MARK: - Grouped by Brand
    static var groupedByBrand: [ServiceGroup] {
        let grouped = Dictionary(grouping: allServices, by: { $0.brandName })
        return grouped.map { brandName, services in
            ServiceGroup(
                brandName: brandName,
                services: services.sorted { ($0.typicalCost ?? 0) < ($1.typicalCost ?? 0) },
                category: services.first?.category ?? .other
            )
        }.sorted { $0.brandName < $1.brandName }
    }

    // MARK: - Search Groups
    static func searchGroups(_ query: String) -> [ServiceGroup] {
        guard query.isNotEmpty else { return groupedByBrand }
        let lowercasedQuery = query.lowercased()
        return groupedByBrand.filter { group in
            group.brandName.lowercased().contains(lowercasedQuery) ||
            group.services.contains { $0.name.lowercased().contains(lowercasedQuery) }
        }
    }

    // MARK: - Groups by Category
    static func groups(for category: ServiceCategory?) -> [ServiceGroup] {
        guard let category = category else { return groupedByBrand }
        return groupedByBrand.filter { $0.category == category }
    }

    // MARK: - Search
    static func search(_ query: String) -> [Service] {
        guard query.isNotEmpty else { return allServices }
        let lowercasedQuery = query.lowercased()
        return allServices.filter { service in
            service.name.lowercased().contains(lowercasedQuery) ||
            service.category.displayName.lowercased().contains(lowercasedQuery)
        }
    }

    // MARK: - Find by Name
    static func find(byName name: String) -> Service? {
        allServices.first { $0.name.lowercased() == name.lowercased() }
    }

    // MARK: - Find Cancellation URL (con match flessibile)
    /// Cerca l'URL di cancellazione anche con match parziale (es. "Netflix" trova "Netflix Standard")
    static func findCancellationURL(forService name: String) -> String? {
        // Prima prova match esatto
        if let exactMatch = find(byName: name), let url = exactMatch.cancellationURL {
            return url
        }

        // Poi cerca servizi che iniziano con il nome (es. "Netflix" → "Netflix Standard")
        let lowercasedName = name.lowercased()
        if let partialMatch = allServices.first(where: {
            $0.name.lowercased().hasPrefix(lowercasedName) && $0.cancellationURL != nil
        }) {
            return partialMatch.cancellationURL
        }

        // Infine cerca servizi il cui nome è contenuto nel nome cercato
        if let containsMatch = allServices.first(where: {
            lowercasedName.contains($0.name.lowercased()) && $0.cancellationURL != nil
        }) {
            return containsMatch.cancellationURL
        }

        return nil
    }

    // MARK: - Categories
    static var allCategories: [ServiceCategory] {
        ServiceCategory.allCases
    }

    // MARK: - Services by Category
    static func services(for category: ServiceCategory) -> [Service] {
        allServices.filter { $0.category == category }
    }

    // MARK: - Custom Service
    static func createCustomService(name: String, category: ServiceCategory, typicalCost: Double? = nil) -> Service {
        Service(
            name: name,
            category: category,
            iconName: category.iconName,
            typicalCost: typicalCost,
            cancellationURL: nil
        )
    }

    // MARK: - Region-aware Methods

    /// Servizi disponibili per una regione specifica
    static func services(for regionId: String) -> [Service] {
        allServices.filter { $0.isAvailable(in: regionId) }
    }

    /// Servizi raggruppati per brand, filtrati per regione
    static func groupedByBrand(for regionId: String) -> [ServiceGroup] {
        let regionServices = services(for: regionId)
        let grouped = Dictionary(grouping: regionServices, by: { $0.brandName })
        return grouped.map { brandName, services in
            ServiceGroup(
                brandName: brandName,
                services: services.sorted { ($0.typicalCost ?? 0) < ($1.typicalCost ?? 0) },
                category: services.first?.category ?? .other
            )
        }.sorted { $0.brandName < $1.brandName }
    }

    /// Cerca servizi filtrati per regione
    static func search(_ query: String, in regionId: String) -> [Service] {
        guard query.isNotEmpty else { return services(for: regionId) }
        let lowercasedQuery = query.lowercased()
        return services(for: regionId).filter { service in
            service.name.lowercased().contains(lowercasedQuery) ||
            service.category.displayName.lowercased().contains(lowercasedQuery)
        }
    }

    /// Cerca gruppi di servizi filtrati per regione
    static func searchGroups(_ query: String, in regionId: String) -> [ServiceGroup] {
        guard query.isNotEmpty else { return groupedByBrand(for: regionId) }
        let lowercasedQuery = query.lowercased()
        return groupedByBrand(for: regionId).filter { group in
            group.brandName.lowercased().contains(lowercasedQuery) ||
            group.services.contains { $0.name.lowercased().contains(lowercasedQuery) }
        }
    }

    /// Gruppi per categoria, filtrati per regione
    static func groups(for category: ServiceCategory?, in regionId: String) -> [ServiceGroup] {
        guard let category = category else { return groupedByBrand(for: regionId) }
        return groupedByBrand(for: regionId).filter { $0.category == category }
    }

    /// Trova servizio per ID stabile
    static func find(byServiceId serviceId: String) -> Service? {
        allServices.first { $0.serviceId == serviceId }
    }
}
