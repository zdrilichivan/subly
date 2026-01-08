//
//  GmailScannerService.swift
//  Subly
//
//  Servizio per scansione email Gmail e rilevamento abbonamenti
//

import Foundation
import SwiftUI
import Combine
import GoogleSignIn
import os

// MARK: - Gmail Message Model
struct GmailMessage: Identifiable {
    let id: String
    let from: String
    let subject: String
    let snippet: String
    let date: Date?
    let body: String?
}

// MARK: - Gmail Scanner Service
@MainActor
class GmailScannerService: ObservableObject {

    // MARK: - Singleton
    static let shared = GmailScannerService()

    // MARK: - Published Properties
    @Published var isSignedIn: Bool = false
    @Published var isScanning: Bool = false
    @Published var foundSubscriptions: [DetectedSubscription] = []
    @Published var scanProgress: Double = 0
    @Published var userEmail: String?
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.ivanzdrilich.Subly", category: "GmailScanner")
    private let gmailScope = "https://www.googleapis.com/auth/gmail.readonly"
    private var accessToken: String?

    // Domini email da cercare per abbonamenti
    private let subscriptionDomains = [
        "netflix.com", "spotify.com", "apple.com", "amazon",
        "disney", "hulu.com", "hbo", "primevideo",
        "adobe.com", "microsoft.com", "google.com", "dropbox.com",
        "notion.so", "figma.com", "slack.com", "zoom.us",
        "playstation.com", "xbox.com", "nintendo",
        "gympass", "headspace.com", "calm.com",
        "dazn", "nowtv", "sky.it", "tim.it",
        "vodafone", "wind", "iliad", "fastweb",
        "crunchyroll", "paramount", "discovery",
        "audible", "storytel", "youtube", "tidal", "deezer"
    ]

    // MARK: - Init
    private init() {
        checkPreviousSignIn()
    }

    // MARK: - OAuth Methods

    /// Controlla se c'è una sessione precedente
    func checkPreviousSignIn() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            self.isSignedIn = true
            self.userEmail = user.profile?.email
            self.accessToken = user.accessToken.tokenString
            logger.info("✅ Gmail: Restored previous sign-in for \(user.profile?.email ?? "unknown")")
        }
    }

    /// Gestisce utente ripristinato all'avvio app
    func handleRestoredUser(_ user: GIDGoogleUser) {
        Task { @MainActor in
            self.isSignedIn = true
            self.userEmail = user.profile?.email
            self.accessToken = user.accessToken.tokenString
        }
    }

    /// Avvia il flusso di login Google
    func signIn(presenting viewController: UIViewController) async throws {
        logger.info("📧 Gmail: Starting sign-in flow")

        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(
                withPresenting: viewController,
                hint: nil,
                additionalScopes: [gmailScope]
            ) { [weak self] result, error in
                guard let self = self else { return }

                if let error = error {
                    self.logger.error("❌ Gmail: Sign-in failed - \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let user = result?.user else {
                    continuation.resume(throwing: GmailScannerError.noUser)
                    return
                }

                Task { @MainActor in
                    self.isSignedIn = true
                    self.userEmail = user.profile?.email
                    self.accessToken = user.accessToken.tokenString
                    self.logger.info("✅ Gmail: Signed in as \(user.profile?.email ?? "unknown")")
                    continuation.resume()
                }
            }
        }
    }

    /// Disconnette l'account Gmail
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        userEmail = nil
        accessToken = nil
        foundSubscriptions = []
        logger.info("📧 Gmail: Signed out")
    }

    /// Ottiene il Client ID da Info.plist
    private func getClientID() -> String {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            logger.error("❌ Gmail: GIDClientID not found in Info.plist")
            return ""
        }
        return clientID
    }

    // MARK: - Email Scanning

    /// Scansiona email DEMO per testare il parsing di Claude (senza Gmail)
    func scanDemoEmails() async throws -> [DetectedSubscription] {
        logger.info("🧪 Demo: Starting demo email scan with Claude Sonnet")
        isScanning = true
        scanProgress = 0
        foundSubscriptions = []
        errorMessage = nil

        // 20 Email simulate realistiche per testare Claude
        let demoEmails: [(from: String, subject: String, snippet: String, body: String?, date: String)] = [
            // STREAMING
            (
                from: "Netflix <info@mailer.netflix.com>",
                subject: "Conferma di pagamento Netflix",
                snippet: "Il tuo pagamento è stato elaborato con successo",
                body: """
                Conferma di pagamento

                Abbiamo addebitato €15,99 per il tuo abbonamento Netflix Standard.
                Piano: Standard (1080p, 2 schermi)
                Prossimo rinnovo: 10/01/2026
                """,
                date: "10/12/2025"
            ),
            (
                from: "Disney+ <disneyplus@mail.disneyplus.com>",
                subject: "Ricevuta Disney+",
                snippet: "Grazie per il tuo abbonamento Disney+",
                body: """
                Ricevuta pagamento

                Disney+ Premium (4K, 4 dispositivi)
                Importo: €11,99/mese
                Data rinnovo: 22/01/2026

                Buona visione!
                """,
                date: "22/12/2025"
            ),
            (
                from: "Prime Video <pv-noreply@amazon.it>",
                subject: "Conferma abbonamento Prime Video",
                snippet: "Il tuo abbonamento Prime Video Channels",
                body: """
                Hai attivato un nuovo canale Prime Video.

                Canale: Infinity+ su Prime Video
                Costo: €7,99/mese
                Rinnovo automatico mensile

                Gestisci su amazon.it/channels
                """,
                date: "18/12/2025"
            ),
            (
                from: "Crunchyroll <noreply@crunchyroll.com>",
                subject: "Crunchyroll Premium - Ricevuta",
                snippet: "Thanks for being a Crunchyroll Premium member",
                body: """
                Your Crunchyroll Premium subscription

                Plan: Mega Fan
                Price: €6,99/month
                Next billing: January 5, 2026

                Enjoy unlimited anime!
                """,
                date: "05/12/2025"
            ),
            (
                from: "Paramount+ <noreply@paramountplus.com>",
                subject: "Paramount+ Ricevuta mensile",
                snippet: "Ecco la tua ricevuta Paramount+",
                body: """
                Paramount+ Essential
                Abbonamento mensile: €4,99
                Prossimo addebito: 28/01/2026
                """,
                date: "28/12/2025"
            ),

            // MUSICA
            (
                from: "Spotify <no-reply@spotify.com>",
                subject: "La tua ricevuta Spotify",
                snippet: "Ricevuta pagamento abbonamento Premium",
                body: """
                Piano: Spotify Premium Family
                Importo: €17,99/mese
                Prossimo addebito: 20/01/2026
                """,
                date: "20/12/2025"
            ),
            (
                from: "Apple <no_reply@email.apple.com>",
                subject: "Ricevuta Apple",
                snippet: "La tua ricevuta da Apple",
                body: """
                Ricevuta Apple

                Apple Music (Famiglia)
                €16,99/mese

                Data fatturazione: 15/12/2025
                Prossimo rinnovo: 15/01/2026
                """,
                date: "15/12/2025"
            ),
            (
                from: "YouTube <noreply@youtube.com>",
                subject: "Ricevuta YouTube Premium",
                snippet: "Grazie per l'abbonamento a YouTube Premium",
                body: """
                YouTube Premium Family

                Prezzo: €25,99/mese
                Include: YouTube Music Premium
                Prossimo addebito: 03/01/2026

                Goditi YouTube senza pubblicità!
                """,
                date: "03/12/2025"
            ),
            (
                from: "Tidal <noreply@tidal.com>",
                subject: "TIDAL HiFi Plus - Payment receipt",
                snippet: "Your TIDAL subscription payment",
                body: """
                TIDAL HiFi Plus

                Monthly subscription: €10,99
                Next billing date: January 12, 2026

                Enjoy lossless audio quality!
                """,
                date: "12/12/2025"
            ),

            // GAMING
            (
                from: "PlayStation <reply@txn-email.playstation.com>",
                subject: "Ricevuta PlayStation Store",
                snippet: "Grazie per l'acquisto",
                body: """
                PlayStation Plus Extra - 12 mesi
                Prezzo: €99,99/anno
                Rinnovo: 05/12/2026
                """,
                date: "05/12/2025"
            ),
            (
                from: "Xbox <xboxsupport@microsoft.com>",
                subject: "Xbox Game Pass Ultimate - Ricevuta",
                snippet: "Ricevuta abbonamento Game Pass",
                body: """
                Xbox Game Pass Ultimate

                Abbonamento mensile: €14,99
                Include: Xbox Live Gold + EA Play
                Prossimo rinnovo: 08/01/2026
                """,
                date: "08/12/2025"
            ),
            (
                from: "Nintendo <no-reply@nintendo.com>",
                subject: "Nintendo Switch Online - Conferma",
                snippet: "Il tuo abbonamento Nintendo Switch Online",
                body: """
                Nintendo Switch Online + Pacchetto Aggiuntivo

                Abbonamento familiare annuale
                Prezzo: €69,99/anno
                Scadenza: 20/09/2026
                """,
                date: "20/12/2025"
            ),

            // SOFTWARE & PRODUTTIVITÀ
            (
                from: "Canva <billing@canva.com>",
                subject: "Your Canva Pro receipt",
                snippet: "Thanks for subscribing to Canva Pro",
                body: """
                Canva Pro

                Subscription: Annual
                Price: €109,99/year
                Next renewal: December 1, 2026

                Create amazing designs!
                """,
                date: "01/12/2025"
            ),
            (
                from: "Adobe <mail@mail.adobe.com>",
                subject: "Ricevuta Adobe Creative Cloud",
                snippet: "Ecco la tua ricevuta Adobe",
                body: """
                Adobe Creative Cloud - Tutte le app

                Piano: Annuale (pagamento mensile)
                Costo: €62,99/mese
                Include: Photoshop, Illustrator, Premiere Pro, ecc.

                Prossimo addebito: 25/01/2026
                """,
                date: "25/12/2025"
            ),
            (
                from: "Microsoft <msa@communication.microsoft.com>",
                subject: "Microsoft 365 - Conferma rinnovo",
                snippet: "Il tuo abbonamento Microsoft 365",
                body: """
                Microsoft 365 Family

                Abbonamento annuale: €99,00/anno
                Utenti: fino a 6 persone
                Include: Word, Excel, PowerPoint, 1TB OneDrive

                Rinnovo automatico: 10/11/2026
                """,
                date: "10/12/2025"
            ),
            (
                from: "Notion <team@mail.notion.so>",
                subject: "Notion Plus - Invoice",
                snippet: "Your Notion subscription invoice",
                body: """
                Notion Plus

                Monthly plan: $10.00/month
                Billed to: Visa ****4242
                Next billing: January 15, 2026
                """,
                date: "15/12/2025"
            ),
            (
                from: "Dropbox <no-reply@dropbox.com>",
                subject: "Dropbox Plus - Ricevuta",
                snippet: "Grazie per il tuo abbonamento Dropbox",
                body: """
                Dropbox Plus (2 TB)

                Piano annuale: €119,88/anno
                Spazio: 2.000 GB
                Rinnovo: 03/12/2026
                """,
                date: "03/12/2025"
            ),
            (
                from: "OpenAI <noreply@openai.com>",
                subject: "ChatGPT Plus - Payment Receipt",
                snippet: "Thank you for subscribing to ChatGPT Plus",
                body: """
                ChatGPT Plus Subscription

                Monthly fee: $20.00
                Features: GPT-4, Priority access
                Next billing: January 18, 2026
                """,
                date: "18/12/2025"
            ),
            (
                from: "Google Play <googleplay-noreply@google.com>",
                subject: "Ricevuta Google One",
                snippet: "Grazie per il tuo acquisto Google One",
                body: """
                Google One AI Pro (2 TB)
                Prezzo: €21,99/mese
                Rinnovo: 15/01/2026
                """,
                date: "28/12/2025"
            ),

            // SPAM/NEWSLETTER (da escludere)
            (
                from: "newsletter@corrieredellosport.it",
                subject: "Offerta speciale per te!",
                snippet: "Scopri le nostre offerte esclusive...",
                body: """
                Ciao lettore!
                Questa settimana abbiamo offerte speciali!
                Clicca qui per saperne di più.
                """,
                date: "30/12/2025"
            )
        ]

        scanProgress = 0.3
        logger.info("🤖 Gemini AI: Analyzing \(demoEmails.count) demo emails...")

        do {
            let parsedResults = try await GeminiParserService.shared.parseEmails(demoEmails)

            scanProgress = 0.9
            logger.info("🤖 Gemini: Found \(parsedResults.count) subscriptions in demo")

            // Converti risultati in DetectedSubscription
            var detectedSubscriptions: [DetectedSubscription] = []
            var seenServices: Set<String> = []

            for parsed in parsedResults {
                let serviceKey = parsed.serviceName.lowercased()
                if seenServices.contains(serviceKey) { continue }
                seenServices.insert(serviceKey)

                // Matching: primo approccio con fix per parole corte (min 4 char)
                let matchedService = ServiceCatalog.allServices.first {
                    let catalogName = $0.name.lowercased()
                    let firstWord = catalogName.split(separator: " ").first?.description ?? ""
                    // Richiedi almeno 4 caratteri per escludere "la"(2), "now"(3), "sky"(3)
                    // ma includere "dazn"(4), "hulu"(4), ecc.
                    return catalogName.contains(serviceKey) ||
                           (firstWord.count >= 4 && serviceKey.contains(firstWord))
                }

                let cycle: BillingCycle = {
                    switch parsed.billingCycle?.lowercased() {
                    case "monthly": return .monthly
                    case "yearly", "annual": return .yearly
                    case "weekly": return .weekly
                    default: return .monthly
                    }
                }()

                let detected = DetectedSubscription(
                    serviceName: parsed.serviceName,
                    detectedCost: parsed.cost,
                    detectedCycle: cycle,
                    sourceEmail: parsed.reason ?? "Demo",
                    emailDate: Date(),
                    confidence: parsed.confidence,
                    matchedService: matchedService,
                    isSelected: parsed.confidence >= 0.7
                )
                detectedSubscriptions.append(detected)
            }

            foundSubscriptions = detectedSubscriptions
            isScanning = false
            scanProgress = 1.0

            logger.info("✅ Demo: Scan complete. Found \(detectedSubscriptions.count) subscriptions")
            return detectedSubscriptions

        } catch {
            isScanning = false
            errorMessage = error.localizedDescription
            logger.error("❌ Demo: Scan failed - \(error.localizedDescription)")
            throw error
        }
    }

    /// Scansiona le email per trovare abbonamenti usando Claude AI
    func scanEmails() async throws -> [DetectedSubscription] {
        guard isSignedIn, accessToken != nil else {
            throw GmailScannerError.notSignedIn
        }

        logger.info("📧 Gmail: Starting AI-powered email scan")
        isScanning = true
        scanProgress = 0
        foundSubscriptions = []
        errorMessage = nil

        do {
            // Refresh token se necessario
            try await refreshTokenIfNeeded()

            // Costruisci query per email di abbonamento (ultimi 3 mesi)
            let query = buildSearchQuery()
            logger.debug("📧 Gmail: Search query: \(query)")

            // Cerca email
            let messageIds = try await searchEmails(query: query)
            logger.info("📧 Gmail: Found \(messageIds.count) potential subscription emails")

            if messageIds.isEmpty {
                isScanning = false
                return []
            }

            // Scarica le email (max 30 per efficienza con AI)
            let messagesToFetch = Array(messageIds.prefix(30))
            var emails: [(from: String, subject: String, snippet: String, body: String?, date: String)] = []

            scanProgress = 0.1
            logger.info("📧 Gmail: Fetching email details with full body...")

            for (index, messageId) in messagesToFetch.enumerated() {
                scanProgress = 0.1 + (Double(index + 1) / Double(messagesToFetch.count)) * 0.3

                if let message = try? await fetchMessage(id: messageId) {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM/yyyy"
                    let dateString = message.date.map { dateFormatter.string(from: $0) } ?? "Sconosciuta"

                    emails.append((
                        from: message.from,
                        subject: message.subject,
                        snippet: message.snippet,
                        body: message.body,
                        date: dateString
                    ))
                }
            }

            // Usa Claude Sonnet AI per analizzare le email con body completo
            scanProgress = 0.5
            logger.info("🤖 Gemini AI: Analyzing \(emails.count) emails with full body...")

            let parsedResults = try await GeminiParserService.shared.parseEmails(emails)

            scanProgress = 0.9
            logger.info("🤖 Gemini: Found \(parsedResults.count) subscriptions")

            // Converti risultati in DetectedSubscription
            var detectedSubscriptions: [DetectedSubscription] = []
            var seenServices: Set<String> = []

            for parsed in parsedResults {
                // Evita duplicati
                let serviceKey = parsed.serviceName.lowercased()
                if seenServices.contains(serviceKey) {
                    continue
                }
                seenServices.insert(serviceKey)

                // Trova servizio nel catalogo
                // Matching: primo approccio con fix per parole corte (min 4 char)
                let matchedService = ServiceCatalog.allServices.first {
                    let catalogName = $0.name.lowercased()
                    let firstWord = catalogName.split(separator: " ").first?.description ?? ""
                    // Richiedi almeno 4 caratteri per escludere "la"(2), "now"(3), "sky"(3)
                    // ma includere "dazn"(4), "hulu"(4), ecc.
                    return catalogName.contains(serviceKey) ||
                           (firstWord.count >= 4 && serviceKey.contains(firstWord))
                }

                // Converti billingCycle
                let cycle: BillingCycle = {
                    switch parsed.billingCycle?.lowercased() {
                    case "monthly": return .monthly
                    case "yearly", "annual": return .yearly
                    case "weekly": return .weekly
                    default: return .monthly
                    }
                }()

                let detected = DetectedSubscription(
                    serviceName: parsed.serviceName,
                    detectedCost: parsed.cost,
                    detectedCycle: cycle,
                    sourceEmail: parsed.reason ?? "",
                    emailDate: Date(),
                    confidence: parsed.confidence,
                    matchedService: matchedService,
                    isSelected: parsed.confidence >= 0.7
                )

                detectedSubscriptions.append(detected)
            }

            foundSubscriptions = detectedSubscriptions
            isScanning = false
            scanProgress = 1.0

            logger.info("✅ Gmail: AI scan complete. Found \(detectedSubscriptions.count) active subscriptions")
            return detectedSubscriptions

        } catch {
            isScanning = false
            errorMessage = error.localizedDescription
            logger.error("❌ Gmail: Scan failed - \(error.localizedDescription)")
            throw error
        }
    }

    /// Refresh del token se scaduto
    private func refreshTokenIfNeeded() async throws {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailScannerError.notSignedIn
        }

        return try await withCheckedThrowingContinuation { continuation in
            user.refreshTokensIfNeeded { user, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                Task { @MainActor in
                    self.accessToken = user?.accessToken.tokenString
                    continuation.resume()
                }
            }
        }
    }

    /// Costruisce la query di ricerca Gmail
    private func buildSearchQuery() -> String {
        // Cerca email degli ultimi 3 mesi con parole chiave abbonamento
        let domainQuery = subscriptionDomains.map { "from:\($0)" }.joined(separator: " OR ")
        let subjectKeywords = "subject:(ricevuta OR receipt OR invoice OR fattura OR abbonamento OR subscription OR rinnovo OR renewal OR pagamento OR payment OR conferma OR confirmation)"

        return "(\(domainQuery)) \(subjectKeywords) newer_than:3m"
    }

    /// Cerca email con Gmail API
    private func searchEmails(query: String) async throws -> [String] {
        guard let token = accessToken else {
            throw GmailScannerError.notSignedIn
        }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=\(encodedQuery)&maxResults=100"

        guard let url = URL(string: urlString) else {
            throw GmailScannerError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailScannerError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw GmailScannerError.unauthorized
        }

        guard httpResponse.statusCode == 200 else {
            throw GmailScannerError.apiError(statusCode: httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let messages = json?["messages"] as? [[String: Any]] ?? []

        return messages.compactMap { $0["id"] as? String }
    }

    /// Scarica i dettagli di un messaggio
    private func fetchMessage(id: String) async throws -> GmailMessage {
        guard let token = accessToken else {
            throw GmailScannerError.notSignedIn
        }

        let urlString = "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(id)?format=full"

        guard let url = URL(string: urlString) else {
            throw GmailScannerError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Estrai headers
        let payload = json?["payload"] as? [String: Any]
        let headers = payload?["headers"] as? [[String: Any]] ?? []

        var from = ""
        var subject = ""
        var dateString = ""

        for header in headers {
            let name = header["name"] as? String ?? ""
            let value = header["value"] as? String ?? ""

            switch name.lowercased() {
            case "from":
                from = value
            case "subject":
                subject = value
            case "date":
                dateString = value
            default:
                break
            }
        }

        let snippet = json?["snippet"] as? String ?? ""

        // Estrai body (se presente)
        var body: String?
        if let parts = payload?["parts"] as? [[String: Any]] {
            for part in parts {
                if let mimeType = part["mimeType"] as? String,
                   mimeType == "text/plain",
                   let bodyData = part["body"] as? [String: Any],
                   let data = bodyData["data"] as? String {
                    body = decodeBase64URL(data)
                    break
                }
            }
        } else if let bodyData = payload?["body"] as? [String: Any],
                  let data = bodyData["data"] as? String {
            body = decodeBase64URL(data)
        }

        let date = parseEmailDate(dateString)

        return GmailMessage(
            id: id,
            from: from,
            subject: subject,
            snippet: snippet,
            date: date,
            body: body
        )
    }

    /// Decodifica Base64 URL-safe
    private func decodeBase64URL(_ string: String) -> String? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Padding
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Parse data email
    private func parseEmailDate(_ dateString: String) -> Date? {
        let formatters = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss z"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")

            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    // MARK: - Email Parsing

    /// Analizza un'email per estrarre informazioni sull'abbonamento
    private func parseSubscription(from email: GmailMessage) -> DetectedSubscription? {
        let domain = extractDomain(from: email.from)
        let textToSearch = "\(email.subject) \(email.snippet) \(email.body ?? "")"

        // Cerca servizio nel catalogo
        let matchedService = findMatchingService(domain: domain, text: textToSearch)

        // Estrai costo
        let detectedCost = extractCost(from: textToSearch)

        // Estrai ciclo di fatturazione
        let detectedCycle = extractBillingCycle(from: textToSearch)

        // Calcola confidence
        var confidence = 0.3 // Base

        if matchedService != nil {
            confidence += 0.4
        }

        if detectedCost != nil {
            confidence += 0.2
        }

        if detectedCycle != nil {
            confidence += 0.1
        }

        // Nome servizio
        let serviceName = matchedService?.name ?? extractServiceName(from: email.from, subject: email.subject)

        guard !serviceName.isEmpty else { return nil }

        return DetectedSubscription(
            serviceName: serviceName,
            detectedCost: detectedCost ?? matchedService?.typicalCost,
            detectedCycle: detectedCycle ?? matchedService?.billingCycle,
            sourceEmail: email.from,
            emailDate: email.date,
            confidence: confidence,
            matchedService: matchedService,
            isSelected: confidence >= 0.5
        )
    }

    /// Estrai dominio dall'indirizzo email
    private func extractDomain(from email: String) -> String {
        // Formato: "Name <email@domain.com>" o "email@domain.com"
        let pattern = "@([a-zA-Z0-9.-]+)"

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: email, range: NSRange(email.startIndex..., in: email)),
              let range = Range(match.range(at: 1), in: email) else {
            return ""
        }

        return String(email[range]).lowercased()
    }

    /// Cerca servizio corrispondente nel catalogo
    private func findMatchingService(domain: String, text: String) -> Service? {
        let lowercaseDomain = domain.lowercased()
        let lowercaseText = text.lowercased()

        // Mappatura domini → servizi
        let domainMappings: [String: String] = [
            "netflix.com": "Netflix",
            "spotify.com": "Spotify",
            "apple.com": "Apple",
            "amazon": "Amazon",
            "disneyplus.com": "Disney+",
            "disney.com": "Disney+",
            "dazn.com": "DAZN",
            "adobe.com": "Adobe",
            "microsoft.com": "Microsoft",
            "dropbox.com": "Dropbox",
            "notion.so": "Notion",
            "youtube.com": "YouTube",
            "google.com": "Google",
            "crunchyroll.com": "Crunchyroll",
            "audible": "Audible",
            "storytel": "Storytel",
            "tidal.com": "Tidal",
            "deezer.com": "Deezer",
            "nowtv.it": "NOW TV",
            "sky.it": "Sky",
            "primevideo": "Amazon Prime Video",
            "hbomax": "HBO Max",
            "paramount": "Paramount+"
        ]

        // Cerca prima per dominio
        for (domainKey, serviceName) in domainMappings {
            if lowercaseDomain.contains(domainKey) {
                if let service = ServiceCatalog.allServices.first(where: {
                    $0.name.lowercased().contains(serviceName.lowercased())
                }) {
                    return service
                }
            }
        }

        // Cerca nel testo per nome servizio
        for service in ServiceCatalog.allServices {
            let nameWords = service.name.lowercased().split(separator: " ")
            for word in nameWords where word.count > 3 {
                if lowercaseText.contains(word) {
                    return service
                }
            }
        }

        return nil
    }

    /// Estrai costo dal testo
    private func extractCost(from text: String) -> Double? {
        // Pattern per importi in Euro o Dollari
        let patterns = [
            "€\\s*([0-9]+[.,][0-9]{2})",
            "([0-9]+[.,][0-9]{2})\\s*€",
            "EUR\\s*([0-9]+[.,][0-9]{2})",
            "\\$\\s*([0-9]+[.,][0-9]{2})",
            "([0-9]+[.,][0-9]{2})\\s*USD"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range(at: 1), in: text) else {
                continue
            }

            let amountString = String(text[range])
                .replacingOccurrences(of: ",", with: ".")

            if let amount = Double(amountString), amount > 0 && amount < 500 {
                return amount
            }
        }

        return nil
    }

    /// Estrai ciclo di fatturazione dal testo
    private func extractBillingCycle(from text: String) -> BillingCycle? {
        let lowercaseText = text.lowercased()

        let monthlyKeywords = ["mensile", "monthly", "al mese", "per month", "/mese", "/month", "trimestrale", "quarterly", "ogni 3 mesi"]
        let yearlyKeywords = ["annuale", "yearly", "annual", "all'anno", "per year", "/anno", "/year"]
        let weeklyKeywords = ["settimanale", "weekly", "alla settimana", "per week"]

        for keyword in yearlyKeywords {
            if lowercaseText.contains(keyword) { return .yearly }
        }

        for keyword in monthlyKeywords {
            if lowercaseText.contains(keyword) { return .monthly }
        }

        for keyword in weeklyKeywords {
            if lowercaseText.contains(keyword) { return .weekly }
        }

        return nil
    }

    /// Estrai nome servizio dal mittente
    private func extractServiceName(from email: String, subject: String) -> String {
        // Prova a estrarre dal nome visualizzato dell'email
        if let nameMatch = email.range(of: "^[^<]+", options: .regularExpression) {
            let name = String(email[nameMatch]).trimmingCharacters(in: .whitespaces)
            if !name.isEmpty && name.count < 50 {
                return name
            }
        }

        // Usa il dominio come fallback
        let domain = extractDomain(from: email)
        if let dotIndex = domain.firstIndex(of: ".") {
            return domain[..<dotIndex].capitalized
        }

        return domain.capitalized
    }
}

// MARK: - Errors
enum GmailScannerError: LocalizedError {
    case notSignedIn
    case noUser
    case invalidURL
    case invalidResponse
    case unauthorized
    case apiError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return String(localized: "Devi prima collegare il tuo account Gmail")
        case .noUser:
            return String(localized: "Impossibile ottenere le informazioni utente")
        case .invalidURL:
            return String(localized: "URL non valido")
        case .invalidResponse:
            return String(localized: "Risposta non valida dal server")
        case .unauthorized:
            return String(localized: "Sessione scaduta. Riconnetti Gmail")
        case .apiError(let statusCode):
            return String(localized: "Errore API Gmail (codice: \(statusCode))")
        }
    }
}
