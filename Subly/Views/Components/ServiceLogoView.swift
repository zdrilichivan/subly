//
//  ServiceLogoView.swift
//  SublySwift
//
//  Vista per il logo di un servizio con caricamento da Clearbit
//

import SwiftUI

struct ServiceLogoView: View {
    let serviceName: String
    let category: ServiceCategory
    var size: CGFloat = 48

    var body: some View {
        Group {
            // Prima controlla se esiste un'icona locale negli Assets (anche con match parziale)
            if let localImage = getLocalImage() {
                Image(uiImage: localImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else if let logoURL = getLogoURL() {
                AsyncImage(url: logoURL) { phase in
                    switch phase {
                    case .empty:
                        // Loading placeholder
                        fallbackView
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.5)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
                            .background(
                                RoundedRectangle(cornerRadius: size * 0.2)
                                    .fill(Color.white)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    case .failure:
                        // Fallback se il logo non carica
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Fallback View (icona generica)
    private var fallbackView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(
                    LinearGradient(
                        colors: [category.color.opacity(0.8), category.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(initials)
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    // MARK: - Computed Properties

    private var initials: String {
        let words = serviceName.split(separator: " ")
        if words.count >= 2 {
            let first = words[0].prefix(1)
            let second = words[1].prefix(1)
            return "\(first)\(second)".uppercased()
        } else {
            return String(serviceName.prefix(2)).uppercased()
        }
    }

    // MARK: - Local Image (con match parziale per varianti di piano)

    private func getLocalImage() -> UIImage? {
        // Prima prova il nome esatto
        if let exactMatch = UIImage(named: serviceName) {
            return exactMatch
        }

        // Prova match parziale per varianti di piano (es. "Netflix Premium" → "Netflix")
        let baseNames = serviceBaseNames[serviceName] ?? []
        for baseName in baseNames {
            if let baseImage = UIImage(named: baseName) {
                return baseImage
            }
        }

        return nil
    }

    // Mappa delle varianti ai nomi base per le icone locali
    private var serviceBaseNames: [String: [String]] {
        [
            // Netflix
            "Netflix Standard con pubblicità": ["Netflix"],
            "Netflix Standard": ["Netflix"],
            "Netflix Premium": ["Netflix"],
            // Disney+
            "Disney+ Standard con pubblicità": ["Disney+", "Disney"],
            "Disney+ Standard": ["Disney+", "Disney"],
            "Disney+ Premium": ["Disney+", "Disney"],
            // Spotify
            "Spotify Individual": ["Spotify"],
            "Spotify Duo": ["Spotify"],
            "Spotify Family": ["Spotify"],
            "Spotify Student": ["Spotify"],
            // Apple Music
            "Apple Music Individuale": ["Apple Music"],
            "Apple Music Famiglia": ["Apple Music"],
            "Apple Music Studenti": ["Apple Music"],
            // iCloud
            "iCloud+ 200GB": ["iCloud+", "iCloud"],
            "iCloud+ 2TB": ["iCloud+", "iCloud"],
            // Google One
            "Google One 100GB": ["Google One", "Google"],
            "Google One 200GB": ["Google One", "Google"],
            "Google One 2TB": ["Google One", "Google"],
            // PlayStation
            "PlayStation Plus Essential": ["PlayStation Plus", "PlayStation"],
            "PlayStation Plus Extra": ["PlayStation Plus", "PlayStation"],
            "PlayStation Plus Premium": ["PlayStation Plus", "PlayStation"],
            // Xbox
            "Xbox Game Pass Core": ["Xbox Game Pass", "Xbox"],
            "Xbox Game Pass Standard": ["Xbox Game Pass", "Xbox"],
            "Xbox Game Pass Ultimate": ["Xbox Game Pass", "Xbox"],
        ]
    }

    // MARK: - Logo URL

    private func getLogoURL() -> URL? {
        guard let domain = serviceDomains[serviceName] ?? guessDomain() else {
            return nil
        }
        // Usa Google Favicon service con dimensione massima
        return URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=256")
    }

    private func guessDomain() -> String? {
        // Prova a indovinare il dominio dal nome del servizio
        let cleanName = serviceName
            .lowercased()
            .replacingOccurrences(of: "+", with: "plus")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        return "\(cleanName).com"
    }

    // MARK: - Service Domains Map
    private var serviceDomains: [String: String] {
        [
            // Streaming Video
            "Netflix": "netflix.com",
            "Netflix Standard con pubblicità": "netflix.com",
            "Netflix Standard": "netflix.com",
            "Netflix Premium": "netflix.com",
            "Amazon Prime Video": "primevideo.com",
            "Disney+": "disneyplus.com",
            "Disney+ Standard con pubblicità": "disneyplus.com",
            "Disney+ Standard": "disneyplus.com",
            "Disney+ Premium": "disneyplus.com",
            "NOW TV": "nowtv.it",
            "Sky Go": "sky.it",
            "DAZN": "dazn.com",
            "Apple TV+": "apple.com",
            "Paramount+": "paramountplus.com",
            "Discovery+": "discoveryplus.com",
            "Infinity+": "infinitytv.it",
            "RaiPlay": "raiplay.it",
            "TimVision": "timvision.it",
            "Crunchyroll": "crunchyroll.com",
            "MUBI": "mubi.com",
            "Chili": "chili.com",
            "YouTube Premium": "youtube.com",

            // Musica
            "Spotify": "spotify.com",
            "Spotify Individual": "spotify.com",
            "Spotify Duo": "spotify.com",
            "Spotify Family": "spotify.com",
            "Spotify Student": "spotify.com",
            "Apple Music": "apple.com",
            "Apple Music Individuale": "apple.com",
            "Apple Music Famiglia": "apple.com",
            "Apple Music Studenti": "apple.com",
            "Amazon Music Unlimited": "music.amazon.com",
            "YouTube Music": "music.youtube.com",
            "Deezer": "deezer.com",
            "Tidal": "tidal.com",
            "SoundCloud Go+": "soundcloud.com",
            "Audible": "audible.com",
            "Storytel": "storytel.com",

            // Software
            "Microsoft 365": "microsoft.com",
            "Adobe Creative Cloud": "adobe.com",
            "Adobe Photoshop": "adobe.com",
            "Adobe Lightroom": "adobe.com",
            "Notion": "notion.so",
            "Evernote": "evernote.com",
            "Dropbox": "dropbox.com",
            "1Password": "1password.com",
            "LastPass": "lastpass.com",
            "Dashlane": "dashlane.com",
            "NordVPN": "nordvpn.com",
            "ExpressVPN": "expressvpn.com",
            "Surfshark": "surfshark.com",
            "Canva Pro": "canva.com",
            "Figma": "figma.com",
            "Sketch": "sketch.com",
            "Slack": "slack.com",
            "Zoom": "zoom.us",
            "ChatGPT Plus": "openai.com",
            "Claude Pro": "anthropic.com",
            "Grammarly": "grammarly.com",
            "Todoist": "todoist.com",

            // Fitness
            "Apple Fitness+": "apple.com",
            "Peloton": "onepeloton.com",
            "Nike Training Club": "nike.com",
            "Strava": "strava.com",
            "MyFitnessPal": "myfitnesspal.com",
            "Headspace": "headspace.com",
            "Calm": "calm.com",
            "Freeletics": "freeletics.com",
            "Fitbit Premium": "fitbit.com",
            "SWEAT": "sweat.com",

            // Cloud
            "iCloud+": "apple.com",
            "iCloud+ 200GB": "apple.com",
            "iCloud+ 2TB": "apple.com",
            "Google One 100GB": "google.com",
            "Google One 200GB": "google.com",
            "Google One 2TB": "google.com",
            "OneDrive 100GB": "microsoft.com",
            "pCloud": "pcloud.com",

            // News
            "Corriere della Sera": "corriere.it",
            "La Repubblica": "repubblica.it",
            "Il Sole 24 Ore": "ilsole24ore.com",
            "La Stampa": "lastampa.it",
            "The Economist": "economist.com",
            "Financial Times": "ft.com",
            "Wall Street Journal": "wsj.com",
            "New York Times": "nytimes.com",
            "Medium": "medium.com",
            "Substack": "substack.com",

            // Gaming
            "PlayStation Plus Essential": "playstation.com",
            "PlayStation Plus Extra": "playstation.com",
            "PlayStation Plus Premium": "playstation.com",
            "Xbox Game Pass Core": "xbox.com",
            "Xbox Game Pass Standard": "xbox.com",
            "Xbox Game Pass Ultimate": "xbox.com",
            "Nintendo Switch Online": "nintendo.com",
            "EA Play": "ea.com",
            "Ubisoft+": "ubisoft.com",
            "Apple Arcade": "apple.com",
            "GeForce NOW": "nvidia.com",
            "Twitch Turbo": "twitch.tv",

            // Telefonia
            "TIM Mobile": "tim.it",
            "Vodafone Mobile": "vodafone.it",
            "WindTre Mobile": "windtre.it",
            "Iliad": "iliad.it",
            "Fastweb Mobile": "fastweb.it",
            "PosteMobile": "postemobile.it",
            "ho. Mobile": "ho-mobile.it",
            "Kena Mobile": "kenamobile.it",
            "Very Mobile": "verymobile.it",
            "Spusu": "spusu.it",
            "TIM Fisso": "tim.it",
            "Vodafone Fisso": "vodafone.it",
            "WindTre Fisso": "windtre.it",
            "Fastweb Fisso": "fastweb.it",
            "Sky WiFi": "sky.it",

            // Altro
            "Amazon Prime": "amazon.it",
            "Deliveroo Plus": "deliveroo.it",
            "Glovo Prime": "glovoapp.com",
            "Just Eat Plus": "justeat.it",
            "Revolut Premium": "revolut.com",
            "N26 You": "n26.com",
        ]
    }
}

// MARK: - Service Logo Grid Item
struct ServiceLogoGridItem: View {
    let service: Service
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ServiceLogoView(
                    serviceName: service.name,
                    category: service.category,
                    size: 56
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 3)
                )

                Text(service.name)
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 30)
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        // Single logos
        HStack(spacing: 16) {
            ServiceLogoView(serviceName: "Netflix", category: .streaming)
            ServiceLogoView(serviceName: "Spotify", category: .music)
            ServiceLogoView(serviceName: "Adobe CC", category: .software)
            ServiceLogoView(serviceName: "iCloud+", category: .cloud)
        }

        // Grid items
        HStack(spacing: 16) {
            ServiceLogoGridItem(
                service: Service(name: "Netflix", category: .streaming, typicalCost: 12.99),
                isSelected: true,
                action: {}
            )
            ServiceLogoGridItem(
                service: Service(name: "Spotify Premium", category: .music, typicalCost: 10.99),
                isSelected: false,
                action: {}
            )
        }
    }
    .padding()
}
