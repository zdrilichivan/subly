//
//  GeminiParserService.swift
//  Subly
//
//  Servizio per parsing email con Gemini AI (economico)
//  Usato come fallback quando il parser offline non riconosce il servizio
//

import Foundation
import os

// MARK: - Parsed Subscription Result
struct ParsedSubscription: Codable {
    let serviceName: String
    let cost: Double?
    let currency: String?
    let billingCycle: String?
    let isActive: Bool
    let confidence: Double
    let reason: String?
}

// MARK: - Gemini Parser Service
class GeminiParserService {

    // MARK: - Singleton
    static let shared = GeminiParserService()

    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ivanzdrilich.Subly", category: "GeminiParser")

    // TODO: Sostituire con la tua API key da https://aistudio.google.com/apikey
    let geminiAPIKey = "YOUR_GEMINI_API_KEY"
    let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent"

    private init() {}

    // MARK: - Check if API is configured
    var isConfigured: Bool {
        return geminiAPIKey != "YOUR_GEMINI_API_KEY" && !geminiAPIKey.isEmpty
    }

    // MARK: - Parse Emails

    /// Analizza email che il parser offline non ha riconosciuto
    func parseEmails(_ emails: [(from: String, subject: String, snippet: String, body: String?, date: String)]) async throws -> [ParsedSubscription] {
        guard isConfigured else {
            logger.warning("⚠️ Gemini: API key not configured")
            return []
        }

        guard !emails.isEmpty else { return [] }

        var results: [ParsedSubscription] = []

        // Processa in batch di 10 (Gemini è veloce ed economico)
        let batchSize = 10
        for i in stride(from: 0, to: emails.count, by: batchSize) {
            let batch = Array(emails[i..<min(i + batchSize, emails.count)])
            let prompt = buildPrompt(emails: batch)

            do {
                let response = try await callGeminiAPI(prompt: prompt)
                let parsed = parseResponse(response)
                results.append(contentsOf: parsed)
            } catch {
                logger.error("❌ Gemini: Batch parse failed - \(error.localizedDescription)")
            }
        }

        return results
    }

    // MARK: - Build Prompt

    private func buildPrompt(emails: [(from: String, subject: String, snippet: String, body: String?, date: String)]) -> String {
        var emailList = ""
        for (index, email) in emails.enumerated() {
            let content = email.body?.prefix(1000) ?? email.snippet.prefix(500)
            emailList += """

            --- EMAIL \(index + 1) ---
            Da: \(email.from)
            Oggetto: \(email.subject)
            Data: \(email.date)
            Contenuto: \(content)

            """
        }

        return """
        Analizza queste email per identificare abbonamenti a pagamento ricorrenti.

        \(emailList)

        REGOLE:
        1. Estrai SOLO abbonamenti REALI con pagamento ricorrente
        2. Usa il nome ESATTO del servizio come scritto nell'email
        3. NON inventare prezzi - se non visibile, usa null
        4. Escludi: newsletter, promo, acquisti singoli

        Rispondi SOLO con JSON array valido:
        [{"serviceName": "Nome", "cost": 9.99, "currency": "EUR", "billingCycle": "monthly", "isActive": true, "confidence": 0.9, "reason": "Motivo"}]

        Se nessun abbonamento trovato: []
        """
    }

    // MARK: - API Call

    private func callGeminiAPI(prompt: String) async throws -> String {
        let urlString = "\(baseURL)?key=\(geminiAPIKey)"
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
                "temperature": 0.1,
                "maxOutputTokens": 2048
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        logger.debug("📤 Gemini: Sending request...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("❌ Gemini API error \(httpResponse.statusCode): \(errorBody)")
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // Parse Gemini response structure
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }

        logger.info("📥 Gemini response received")
        return text
    }

    // MARK: - Parse Response

    private func parseResponse(_ response: String) -> [ParsedSubscription] {
        let cleanedResponse = extractJSON(from: response)

        guard let data = cleanedResponse.data(using: .utf8) else {
            logger.error("❌ Gemini: Failed to convert response to data")
            return []
        }

        do {
            let results = try JSONDecoder().decode([ParsedSubscription].self, from: data)
            return results.filter { !$0.serviceName.isEmpty && $0.serviceName != "null" && $0.isActive }
        } catch {
            // Try parsing as single object
            do {
                let single = try JSONDecoder().decode(ParsedSubscription.self, from: data)
                if !single.serviceName.isEmpty && single.serviceName != "null" && single.isActive {
                    return [single]
                }
            } catch {
                logger.error("❌ Gemini: Failed to decode response - \(error.localizedDescription)")
            }
            return []
        }
    }

    private func extractJSON(from text: String) -> String {
        // Remove markdown code blocks if present
        var cleaned = text
        if cleaned.contains("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        } else if cleaned.contains("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // Find JSON array or object
        if let startArray = cleaned.firstIndex(of: "["),
           let endArray = cleaned.lastIndex(of: "]") {
            return String(cleaned[startArray...endArray])
        }

        if let startObj = cleaned.firstIndex(of: "{"),
           let endObj = cleaned.lastIndex(of: "}") {
            return String(cleaned[startObj...endObj])
        }

        return cleaned
    }
}

// MARK: - Errors
enum GeminiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL API non valido"
        case .invalidResponse:
            return "Risposta non valida"
        case .apiError(let code, let message):
            return "Errore API Gemini (\(code)): \(message)"
        case .parseError:
            return "Errore nel parsing della risposta"
        case .notConfigured:
            return "API key Gemini non configurata"
        }
    }
}
