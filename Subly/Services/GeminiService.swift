//
//  GeminiService.swift
//  Subly
//
//  Servizio semplificato per chiamate API Gemini
//  Usato per generare citazioni e consigli AI
//

import Foundation
import os

// MARK: - Gemini Service
class GeminiService {

    // MARK: - Singleton
    static let shared = GeminiService()

    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ivanzdrilich.Subly", category: "GeminiService")

    // La chiave vive in Secrets.swift (gitignorato), vedi Secrets.swift.example
    let geminiAPIKey = Secrets.geminiAPIKey

    // Modello da usare. gemini-1.5-flash è stato ritirato da Google (risponde 404);
    // il free tier della chiave ha quota attiva solo sui modelli "lite".
    private let model = "gemini-2.5-flash-lite"

    var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
    }

    private init() {}

    // MARK: - Check if API is configured
    var isConfigured: Bool {
        return !geminiAPIKey.isEmpty && geminiAPIKey.hasPrefix("AIza") && geminiAPIKey.count > 30
    }

    // MARK: - API Call
    func callAPI(prompt: String, temperature: Double = 0.7, maxTokens: Int = 512) async throws -> String {
        guard isConfigured else {
            throw GeminiError.notConfigured
        }

        let urlString = "\(baseURL)?key=\(geminiAPIKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Richiesto dalla restrizione "App per iOS" sulla API key in Google Cloud:
        // senza questo header le richieste vengono rifiutate (403)
        if let bundleID = Bundle.main.bundleIdentifier {
            request.setValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": temperature,
                "maxOutputTokens": maxTokens
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            throw GeminiError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: "HTTP \(httpResponse.statusCode)")
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
}

// MARK: - Errors
enum GeminiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError
    case notConfigured
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL API non valido"
        case .invalidResponse:
            return "Risposta non valida dal server"
        case .apiError(let statusCode, let message):
            return "Errore API Gemini (\(statusCode)): \(message)"
        case .parseError:
            return "Errore nel parsing della risposta"
        case .notConfigured:
            return "API key non configurata"
        case .rateLimited:
            return "Limite API raggiunto, riprova più tardi"
        }
    }
}
