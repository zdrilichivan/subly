//
//  WisdomQuoteService.swift
//  Subly
//
//  Servizio per citazioni di saggezza finanziaria giornaliere
//  Usa Gemini AI per generare nuove citazioni
//

import Foundation
import SwiftUI
import Combine
import os

struct WisdomQuote: Codable {
    let text: String
    let author: String
    let date: Date
}

@MainActor
class WisdomQuoteService: ObservableObject {

    // MARK: - Singleton
    static let shared = WisdomQuoteService()

    // MARK: - Published Properties
    @Published var todaysQuote: WisdomQuote
    @Published var isLoading = false

    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.ivanzdrilich.Subly", category: "WisdomQuote")
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cachedWisdomQuote"
    private let cachedLanguageKey = "cachedWisdomQuoteLanguage"

    // Gemini API (usa la stessa config di GeminiParserService)
    private var geminiService: GeminiParserService { GeminiParserService.shared }

    // Citazioni statiche di fallback (localizzate)
    private var fallbackQuotes: [WisdomQuote] {
        [
            WisdomQuote(text: String(localized: "Non è quanto guadagni, ma quanto risparmi."), author: "Warren Buffett", date: Date()),
            WisdomQuote(text: String(localized: "Il denaro è un buon servo ma un cattivo padrone."), author: "Francis Bacon", date: Date()),
            WisdomQuote(text: String(localized: "La ricchezza consiste non nell'avere grandi possedimenti, ma nel avere pochi bisogni."), author: String(localized: "Epitteto"), date: Date()),
            WisdomQuote(text: String(localized: "Ogni risparmio è un guadagno."), author: String(localized: "Proverbio italiano"), date: Date()),
            WisdomQuote(text: String(localized: "Chi non risparmia quando ha, non avrà quando vuole."), author: String(localized: "Proverbio danese"), date: Date()),
            WisdomQuote(text: String(localized: "Il tempo è denaro."), author: "Benjamin Franklin", date: Date()),
            WisdomQuote(text: String(localized: "Un euro risparmiato è un euro guadagnato."), author: String(localized: "Proverbio popolare"), date: Date()),
            WisdomQuote(text: String(localized: "Non comprare ciò che non ti serve, o venderai ciò che ti serve."), author: "Benjamin Franklin", date: Date()),
            WisdomQuote(text: String(localized: "La vera ricchezza è la libertà dal desiderio."), author: "Seneca", date: Date()),
            WisdomQuote(text: String(localized: "Investi in te stesso. È l'investimento che rende di più."), author: "Warren Buffett", date: Date()),
            WisdomQuote(text: String(localized: "I soldi non fanno la felicità, ma la loro mancanza fa l'infelicità."), author: String(localized: "Proverbio"), date: Date()),
            WisdomQuote(text: String(localized: "Prima paga te stesso."), author: "George S. Clason", date: Date()),
            WisdomQuote(text: String(localized: "La strada verso la ricchezza dipende da due parole: lavoro e risparmio."), author: "Benjamin Franklin", date: Date()),
            WisdomQuote(text: String(localized: "Chi vuole essere ricco in un giorno, sarà impiccato in un anno."), author: "Leonardo da Vinci", date: Date()),
            WisdomQuote(text: String(localized: "Il segreto della ricchezza è semplice: spendi meno di quanto guadagni."), author: "Thomas J. Stanley", date: Date()),
        ]
    }

    // MARK: - Init
    private init() {
        // Inizializza con citazione di default (localizzata)
        self.todaysQuote = WisdomQuote(
            text: String(localized: "Non è quanto guadagni, ma quanto risparmi."),
            author: "Warren Buffett",
            date: Date()
        )

        // Carica citazione cached se disponibile
        if let cached = loadCachedQuote(), Calendar.current.isDateInToday(cached.date) {
            self.todaysQuote = cached
            logger.info("📖 Quote: Loaded cached quote for today")
        } else {
            // Usa fallback basato sul giorno
            self.todaysQuote = getRandomFallbackQuote()
            logger.info("📖 Quote: Using fallback, will try AI generation")
        }
    }

    // MARK: - Public Methods

    /// Ricarica la citazione del giorno (genera nuova se necessario)
    func refreshQuote() async {
        // Se già abbiamo una citazione di oggi, non rigenerare
        if Calendar.current.isDateInToday(todaysQuote.date) {
            // Controlla se è una citazione AI o fallback
            if !fallbackQuotes.contains(where: { $0.text == todaysQuote.text }) {
                logger.debug("📖 Quote: Already have AI quote for today")
                return
            }
        }

        // Prova a generare con Gemini
        await generateQuoteWithGemini()
    }

    // MARK: - Private Methods

    private func generateQuoteWithGemini() async {
        guard GeminiParserService.shared.isConfigured else {
            logger.info("📖 Quote: Gemini not configured, using fallback")
            let fallback = getRandomFallbackQuote()
            todaysQuote = fallback
            saveQuoteToCache(fallback)
            return
        }

        isLoading = true

        // Rileva la lingua del dispositivo
        let languageCode = Locale.current.language.languageCode?.identifier ?? "it"
        let languageName: String
        switch languageCode {
        case "en": languageName = "ENGLISH"
        case "es": languageName = "SPANISH"
        default: languageName = "ITALIAN"
        }

        let prompt = """
        Generate ONE motivational quote about money, savings, or financial management.

        RULES:
        - The quote must be in \(languageName)
        - Must be short (max 15 words)
        - Can be a real quote from a famous person OR a proverb
        - Must inspire saving or financial wisdom

        Reply ONLY with this JSON format:
        {"text": "The quote here", "author": "Author Name"}

        Examples of style:
        - "Savings is the mother of wealth." — Proverb
        - "It's never too late to start saving." — Anonymous
        """

        do {
            let response = try await callGeminiAPI(prompt: prompt)
            if let quote = parseQuoteResponse(response) {
                todaysQuote = quote
                saveQuoteToCache(quote)
                logger.info("✅ Quote: Generated new AI quote")
            } else {
                let fallback = getRandomFallbackQuote()
                todaysQuote = fallback
                saveQuoteToCache(fallback)
            }
        } catch {
            logger.error("❌ Quote: Gemini failed - \(error.localizedDescription)")
            let fallback = getRandomFallbackQuote()
            todaysQuote = fallback
            saveQuoteToCache(fallback)
        }

        isLoading = false
    }

    private func callGeminiAPI(prompt: String) async throws -> String {
        let urlString = "\(geminiService.baseURL)?key=\(geminiService.geminiAPIKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.9,  // Più creatività per le citazioni
                "maxOutputTokens": 256
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GeminiError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }

        return text
    }

    private func parseQuoteResponse(_ response: String) -> WisdomQuote? {
        // Pulisci la risposta
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // Trova JSON
        guard let startIndex = cleaned.firstIndex(of: "{"),
              let endIndex = cleaned.lastIndex(of: "}") else {
            return nil
        }

        let jsonString = String(cleaned[startIndex...endIndex])

        guard let data = jsonString.data(using: .utf8) else { return nil }

        do {
            let parsed = try JSONDecoder().decode(QuoteAPIResponse.self, from: data)
            return WisdomQuote(
                text: parsed.text,
                author: parsed.author,
                date: Date()
            )
        } catch {
            logger.error("❌ Quote: Parse failed - \(error.localizedDescription)")
            return nil
        }
    }

    private func getRandomFallbackQuote() -> WisdomQuote {
        // Usa il giorno dell'anno per selezionare una citazione consistente
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % fallbackQuotes.count
        var quote = fallbackQuotes[index]
        // Aggiorna la data
        quote = WisdomQuote(text: quote.text, author: quote.author, date: Date())
        return quote
    }

    // MARK: - Cache

    private var currentLanguage: String {
        Locale.current.language.languageCode?.identifier ?? "it"
    }

    private func loadCachedQuote() -> WisdomQuote? {
        // Invalida cache se la lingua è cambiata
        let cachedLanguage = userDefaults.string(forKey: cachedLanguageKey)
        if cachedLanguage != currentLanguage {
            userDefaults.removeObject(forKey: cacheKey)
            logger.info("📖 Quote: Cache invalidated due to language change")
            return nil
        }

        guard let data = userDefaults.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(WisdomQuote.self, from: data)
    }

    private func saveQuoteToCache(_ quote: WisdomQuote) {
        if let data = try? JSONEncoder().encode(quote) {
            userDefaults.set(data, forKey: cacheKey)
            userDefaults.set(currentLanguage, forKey: cachedLanguageKey)
        }
    }
}

// MARK: - API Response Model
private struct QuoteAPIResponse: Codable {
    let text: String
    let author: String
}
