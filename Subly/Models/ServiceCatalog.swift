//
//  ServiceCatalog.swift
//  SublySwift
//
//  Catalogo di 80+ servizi di abbonamento italiani
//

import Foundation
import SwiftUI

// MARK: - Service Model
struct Service: Identifiable, Equatable {
    let id: UUID
    let name: String
    let category: ServiceCategory
    let iconName: String
    let typicalCost: Double?
    let billingCycle: BillingCycle
    let cancellationURL: String?

    init(
        id: UUID = UUID(),
        name: String,
        category: ServiceCategory,
        iconName: String = "",
        typicalCost: Double? = nil,
        billingCycle: BillingCycle = .monthly,
        cancellationURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.iconName = iconName.isEmpty ? category.iconName : iconName
        self.typicalCost = typicalCost
        self.billingCycle = billingCycle
        self.cancellationURL = cancellationURL
    }
}

// MARK: - Service Catalog
struct ServiceCatalog {

    // MARK: - All Services (80+)
    static let allServices: [Service] = [
        // MARK: Streaming Video
        Service(name: "Netflix", category: .streaming, iconName: "play.tv.fill", typicalCost: 12.99, cancellationURL: "https://www.netflix.com/cancelplan"),
        Service(name: "Amazon Prime Video", category: .streaming, iconName: "play.tv.fill", typicalCost: 4.99, cancellationURL: "https://www.amazon.it/gp/video/settings"),
        Service(name: "Disney+", category: .streaming, iconName: "play.tv.fill", typicalCost: 8.99, cancellationURL: "https://www.disneyplus.com/account/subscription"),
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
        Service(name: "Spotify", category: .music, iconName: "music.note", typicalCost: 10.99, cancellationURL: "https://www.spotify.com/it/account/subscription/"),
        Service(name: "Apple Music", category: .music, iconName: "music.note", typicalCost: 10.99, cancellationURL: "https://support.apple.com/it-it/HT202039"),
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
        Service(name: "iCloud+", category: .cloud, iconName: "icloud.fill", typicalCost: 0.99, cancellationURL: "https://support.apple.com/it-it/HT202039"),
        Service(name: "iCloud+ 200GB", category: .cloud, iconName: "icloud.fill", typicalCost: 2.99, cancellationURL: "https://support.apple.com/it-it/HT202039"),
        Service(name: "iCloud+ 2TB", category: .cloud, iconName: "icloud.fill", typicalCost: 9.99, cancellationURL: "https://support.apple.com/it-it/HT202039"),
        Service(name: "Google One 100GB", category: .cloud, iconName: "cloud.fill", typicalCost: 1.99, cancellationURL: "https://one.google.com/settings"),
        Service(name: "Google One 200GB", category: .cloud, iconName: "cloud.fill", typicalCost: 2.99, cancellationURL: "https://one.google.com/settings"),
        Service(name: "Google One 2TB", category: .cloud, iconName: "cloud.fill", typicalCost: 9.99, cancellationURL: "https://one.google.com/settings"),
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
        Service(name: "PlayStation Plus Essential", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 8.99, cancellationURL: "https://www.playstation.com/it-it/support/store/cancel-ps-store-subscription/"),
        Service(name: "PlayStation Plus Extra", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 13.99, cancellationURL: "https://www.playstation.com/it-it/support/store/cancel-ps-store-subscription/"),
        Service(name: "PlayStation Plus Premium", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 16.99, cancellationURL: "https://www.playstation.com/it-it/support/store/cancel-ps-store-subscription/"),
        Service(name: "Xbox Game Pass Core", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 6.99, cancellationURL: "https://account.microsoft.com/services"),
        Service(name: "Xbox Game Pass Standard", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 12.99, cancellationURL: "https://account.microsoft.com/services"),
        Service(name: "Xbox Game Pass Ultimate", category: .gaming, iconName: "gamecontroller.fill", typicalCost: 14.99, cancellationURL: "https://account.microsoft.com/services"),
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
        Service(name: "Amazon Prime", category: .other, iconName: "shippingbox.fill", typicalCost: 4.99, billingCycle: .monthly, cancellationURL: "https://www.amazon.it/gp/primecentral"),
        Service(name: "Deliveroo Plus", category: .other, iconName: "bag.fill", typicalCost: 3.99, cancellationURL: "https://deliveroo.it/account/subscription"),
        Service(name: "Glovo Prime", category: .other, iconName: "bag.fill", typicalCost: 5.99, cancellationURL: "https://glovoapp.com/it/profile/"),
        Service(name: "Just Eat Plus", category: .other, iconName: "bag.fill", typicalCost: 4.99, cancellationURL: "https://www.justeat.it/account/"),
        Service(name: "Satispay", category: .other, iconName: "creditcard.fill", typicalCost: 0),
        Service(name: "Revolut Premium", category: .other, iconName: "creditcard.fill", typicalCost: 7.99, cancellationURL: "https://app.revolut.com/settings/subscription"),
        Service(name: "N26 You", category: .other, iconName: "creditcard.fill", typicalCost: 9.90, cancellationURL: "https://app.n26.com/settings/membership"),
        Service(name: "Enjoy", category: .other, iconName: "car.fill", typicalCost: 0),
        Service(name: "ShareNow", category: .other, iconName: "car.fill", typicalCost: 0, cancellationURL: "https://www.share-now.com/it/it/account/"),
        Service(name: "Altro", category: .other, iconName: "square.grid.2x2.fill", typicalCost: nil),
    ]

    // MARK: - Grouped by Category
    static var groupedByCategory: [ServiceCategory: [Service]] {
        Dictionary(grouping: allServices, by: { $0.category })
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

    // MARK: - Categories
    static var allCategories: [ServiceCategory] {
        ServiceCategory.allCases
    }

    // MARK: - Services by Category
    static func services(for category: ServiceCategory) -> [Service] {
        allServices.filter { $0.category == category }
    }

    // MARK: - Custom Service
    static func createCustomService(name: String, category: ServiceCategory) -> Service {
        Service(
            name: name,
            category: category,
            iconName: category.iconName,
            typicalCost: nil,
            cancellationURL: nil
        )
    }
}
