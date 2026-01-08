//
//  OfflineEmailParser.swift
//  Subly
//
//  Parser offline per identificare abbonamenti senza AI
//  Usa pattern matching e regex per servizi comuni
//

import Foundation
import os

class OfflineEmailParser {

    // MARK: - Singleton
    static let shared = OfflineEmailParser()

    private let logger = Logger(subsystem: "com.ivanzdrilich.Subly", category: "OfflineParser")

    private init() {}

    // MARK: - Known Services Patterns

    /// Pattern per identificare servizi noti dal mittente o oggetto
    private let knownServices: [(pattern: String, serviceName: String, category: String)] = [
        // Streaming Video
        ("netflix", "Netflix", "streaming"),
        ("disneyplus|disney+|disney plus", "Disney+", "streaming"),
        ("primevideo|prime video|amazon prime", "Amazon Prime Video", "streaming"),
        ("hbomax|hbo max", "HBO Max", "streaming"),
        ("dazn", "DAZN", "streaming"),
        ("nowtv|now tv|sky now", "NOW TV", "streaming"),
        ("crunchyroll", "Crunchyroll", "streaming"),
        ("paramount+|paramountplus", "Paramount+", "streaming"),
        ("apple tv|appletv", "Apple TV+", "streaming"),
        ("youtube premium|youtubepremium", "YouTube Premium", "streaming"),
        ("sky\\.it|sky italia", "Sky Italia", "streaming"),
        ("infinity\\+|infinity plus|mediaset infinity", "Infinity+", "streaming"),
        ("timvision", "TIMVision", "streaming"),

        // Streaming Musica
        ("spotify", "Spotify", "music"),
        ("apple music|applemusic", "Apple Music", "music"),
        ("deezer", "Deezer", "music"),
        ("tidal", "Tidal", "music"),
        ("amazon music", "Amazon Music", "music"),
        ("youtube music", "YouTube Music", "music"),

        // Gaming
        ("playstation.*plus|psn.*plus|ps plus", "PlayStation Plus", "gaming"),
        ("xbox.*game.*pass|gamepass", "Xbox Game Pass", "gaming"),
        ("nintendo.*switch.*online|nintendo online", "Nintendo Switch Online", "gaming"),
        ("ea play|ea access", "EA Play", "gaming"),
        ("ubisoft\\+|ubisoft plus", "Ubisoft+", "gaming"),
        ("geforce now|geforcenow", "GeForce NOW", "gaming"),

        // Cloud Storage
        ("google one|googleone", "Google One", "cloud"),
        ("icloud|apple.*storage", "iCloud+", "cloud"),
        ("dropbox", "Dropbox", "cloud"),
        ("onedrive|microsoft.*storage", "OneDrive", "cloud"),

        // Produttività
        ("microsoft 365|office 365|microsoft365", "Microsoft 365", "productivity"),
        ("adobe.*creative|creative cloud", "Adobe Creative Cloud", "productivity"),
        ("canva", "Canva Pro", "productivity"),
        ("notion", "Notion", "productivity"),
        ("evernote", "Evernote", "productivity"),
        ("1password|onepassword", "1Password", "productivity"),
        ("lastpass", "LastPass", "productivity"),
        ("grammarly", "Grammarly", "productivity"),

        // Fitness
        ("strava", "Strava", "fitness"),
        ("apple fitness|fitness\\+", "Apple Fitness+", "fitness"),
        ("peloton", "Peloton", "fitness"),
        ("nike.*run|nike training", "Nike Run Club", "fitness"),

        // News & Reading
        ("kindle unlimited|kindle.*subscription", "Kindle Unlimited", "reading"),
        ("audible", "Audible", "reading"),
        ("scribd", "Scribd", "reading"),
        ("medium", "Medium", "reading"),
        ("corriere.*digital|corriere della sera", "Corriere della Sera", "news"),
        ("repubblica.*premium|la repubblica", "La Repubblica", "news"),
        ("il sole 24 ore|sole24ore", "Il Sole 24 Ore", "news"),

        // Telefonia Italia
        ("iliad", "Iliad", "telecom"),
        ("tim\\.it|telecom italia", "TIM", "telecom"),
        ("vodafone\\.it|vodafone italia", "Vodafone", "telecom"),
        ("windtre|wind tre", "WindTre", "telecom"),
        ("fastweb", "Fastweb", "telecom"),
        ("ho\\. mobile|ho-mobile", "ho. Mobile", "telecom"),
        ("very mobile|verymobile", "Very Mobile", "telecom"),
        ("kena mobile|kenamobile", "Kena Mobile", "telecom"),
        ("postemobile", "PosteMobile", "telecom"),

        // VPN & Security
        ("nordvpn", "NordVPN", "vpn"),
        ("expressvpn", "ExpressVPN", "vpn"),
        ("surfshark", "Surfshark", "vpn"),
        ("protonvpn|proton vpn", "ProtonVPN", "vpn"),
        ("norton", "Norton", "security"),
        ("mcafee", "McAfee", "security"),
        ("bitdefender", "Bitdefender", "security"),

        // AI Services
        ("openai|chatgpt", "ChatGPT Plus", "ai"),
        ("anthropic|claude", "Claude Pro", "ai"),
        ("midjourney", "Midjourney", "ai"),
        ("github copilot|copilot", "GitHub Copilot", "ai"),

        // Other
        ("linkedin.*premium", "LinkedIn Premium", "other"),
        ("tinder.*plus|tinder.*gold", "Tinder", "other"),
        ("bumble.*premium|bumble.*boost", "Bumble", "other"),
        ("duolingo.*plus|duolingo.*super", "Duolingo Plus", "other"),
        ("headspace", "Headspace", "other"),
        ("calm\\.com|calm app", "Calm", "other"),
    ]

    /// Keyword che indicano un'email di abbonamento
    private let subscriptionKeywords = [
        "abbonamento", "subscription", "rinnovo", "renewal", "fattura", "invoice",
        "ricevuta", "receipt", "pagamento", "payment", "addebito", "charge",
        "conferma ordine", "order confirmation", "piano", "plan", "premium",
        "mensile", "monthly", "annuale", "yearly", "annual"
    ]

    /// Keyword che indicano che NON è un abbonamento
    private let excludeKeywords = [
        "newsletter", "promo", "offerta speciale", "sconto", "coupon",
        "gratis", "free trial", "prova gratuita", "survey", "sondaggio",
        "unsubscribe", "cancella iscrizione", "preferenze email"
    ]

    // MARK: - Price Patterns

    /// Regex per trovare prezzi in vari formati
    private let pricePatterns = [
        "€\\s*(\\d+[,.]\\d{2})",           // €12,99 or €12.99
        "(\\d+[,.]\\d{2})\\s*€",           // 12,99€ or 12.99€
        "(\\d+[,.]\\d{2})\\s*EUR",         // 12.99 EUR
        "EUR\\s*(\\d+[,.]\\d{2})",         // EUR 12.99
        "\\$(\\d+[,.]\\d{2})",             // $12.99
        "(\\d+[,.]\\d{2})\\s*USD",         // 12.99 USD
        "£(\\d+[,.]\\d{2})",               // £12.99
    ]

    // MARK: - Parse Email

    /// Analizza un'email e restituisce un abbonamento se identificato
    func parseEmail(from: String, subject: String, snippet: String, body: String?, date: String) -> ParsedSubscription? {
        let content = "\(from) \(subject) \(snippet) \(body ?? "")".lowercased()

        // 1. Verifica se è un'email di abbonamento
        guard isSubscriptionEmail(content: content, subject: subject) else {
            logger.debug("⏭️ Offline: Skipped - not a subscription email")
            return nil
        }

        // 2. Identifica il servizio
        guard let (serviceName, _) = identifyService(from: from, subject: subject, content: content) else {
            logger.debug("⏭️ Offline: Unknown service - needs AI")
            return nil
        }

        // 3. Estrai prezzo se possibile
        let (price, currency) = extractPrice(from: content)

        // 4. Determina il ciclo di fatturazione
        let billingCycle = determineBillingCycle(from: content)

        logger.info("✅ Offline: Found \(serviceName) - \(price ?? 0) \(currency ?? "EUR") \(billingCycle ?? "unknown")")

        return ParsedSubscription(
            serviceName: serviceName,
            cost: price,
            currency: currency ?? "EUR",
            billingCycle: billingCycle,
            isActive: true,
            confidence: price != nil ? 0.9 : 0.7,
            reason: "Identified offline via pattern matching"
        )
    }

    /// Analizza più email
    func parseEmails(_ emails: [(from: String, subject: String, snippet: String, body: String?, date: String)]) -> (parsed: [ParsedSubscription], needsAI: [(from: String, subject: String, snippet: String, body: String?, date: String)]) {
        var parsed: [ParsedSubscription] = []
        var needsAI: [(from: String, subject: String, snippet: String, body: String?, date: String)] = []

        for email in emails {
            if let subscription = parseEmail(
                from: email.from,
                subject: email.subject,
                snippet: email.snippet,
                body: email.body,
                date: email.date
            ) {
                parsed.append(subscription)
            } else {
                // Verifica se sembra un'email di abbonamento ma non identificata
                let content = "\(email.from) \(email.subject) \(email.snippet)".lowercased()
                if isSubscriptionEmail(content: content, subject: email.subject) {
                    needsAI.append(email)
                }
            }
        }

        return (parsed, needsAI)
    }

    // MARK: - Private Methods

    private func isSubscriptionEmail(content: String, subject: String) -> Bool {
        let lowerContent = content.lowercased()
        let lowerSubject = subject.lowercased()

        // Escludi se contiene keyword di esclusione
        for keyword in excludeKeywords {
            if lowerSubject.contains(keyword) {
                return false
            }
        }

        // Verifica se contiene keyword di abbonamento
        for keyword in subscriptionKeywords {
            if lowerContent.contains(keyword) {
                return true
            }
        }

        // Verifica se è da un servizio noto
        for (pattern, _, _) in knownServices {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowerContent.startIndex..., in: lowerContent)
                if regex.firstMatch(in: lowerContent, range: range) != nil {
                    return true
                }
            }
        }

        return false
    }

    private func identifyService(from: String, subject: String, content: String) -> (name: String, category: String)? {
        let searchText = "\(from) \(subject) \(content)".lowercased()

        for (pattern, serviceName, category) in knownServices {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(searchText.startIndex..., in: searchText)
                if regex.firstMatch(in: searchText, range: range) != nil {
                    return (serviceName, category)
                }
            }
        }

        return nil
    }

    private func extractPrice(from content: String) -> (Double?, String?) {
        for pattern in pricePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(content.startIndex..., in: content)
                if let match = regex.firstMatch(in: content, range: range) {
                    if let priceRange = Range(match.range(at: 1), in: content) {
                        var priceString = String(content[priceRange])
                        priceString = priceString.replacingOccurrences(of: ",", with: ".")

                        if let price = Double(priceString) {
                            // Determina la valuta dal pattern
                            let currency: String
                            if pattern.contains("€") || pattern.contains("EUR") {
                                currency = "EUR"
                            } else if pattern.contains("$") || pattern.contains("USD") {
                                currency = "USD"
                            } else if pattern.contains("£") {
                                currency = "GBP"
                            } else {
                                currency = "EUR"
                            }
                            return (price, currency)
                        }
                    }
                }
            }
        }
        return (nil, nil)
    }

    private func determineBillingCycle(from content: String) -> String? {
        let lowerContent = content.lowercased()

        // Annuale
        if lowerContent.contains("annual") || lowerContent.contains("annuale") ||
           lowerContent.contains("yearly") || lowerContent.contains("/anno") ||
           lowerContent.contains("per year") || lowerContent.contains("all'anno") {
            return "yearly"
        }

        // Settimanale
        if lowerContent.contains("weekly") || lowerContent.contains("settimanale") ||
           lowerContent.contains("/settimana") || lowerContent.contains("per week") {
            return "weekly"
        }

        // Mensile (default per abbonamenti)
        if lowerContent.contains("monthly") || lowerContent.contains("mensile") ||
           lowerContent.contains("/mese") || lowerContent.contains("per month") ||
           lowerContent.contains("al mese") {
            return "monthly"
        }

        return "monthly" // Default
    }
}
