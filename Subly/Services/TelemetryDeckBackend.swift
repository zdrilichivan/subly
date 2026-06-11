//
//  TelemetryDeckBackend.swift
//  Subly
//
//  Backend remoto per AnalyticsService che invia i segnali direttamente
//  all'API di ingestione TelemetryDeck (stesso formato dell'SDK ufficiale,
//  senza dipendenza SPM). I segnali sono fire-and-forget: se il device è
//  offline l'evento viene perso, accettabile per il funnel v1.
//
//  Attivazione: impostare Secrets.telemetryDeckAppID (vedi Secrets.swift).
//

import Foundation
import CryptoKit
import UIKit

struct TelemetryDeckBackend: AnalyticsBackend {

    private static let endpoint = URL(string: "https://nom.telemetrydeck.com/v2/")!

    /// Stesso formato data dell'SDK ufficiale (JSONEncoder.telemetryEncoder)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// Un sessionID per lancio dell'app, come fa l'SDK
    private static let sessionID = UUID().uuidString

    /// Identificatore utente anonimo: SHA-256 dell'identifierForVendor
    /// (o di un UUID persistito come fallback). Mai dati personali.
    private static let hashedClientUser: String = {
        let raw: String
        if let idfv = UIDevice.current.identifierForVendor?.uuidString {
            raw = idfv
        } else {
            let key = "telemetryFallbackUserID"
            if let stored = UserDefaults.standard.string(forKey: key) {
                raw = stored
            } else {
                let generated = UUID().uuidString
                UserDefaults.standard.set(generated, forKey: key)
                raw = generated
            }
        }
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }()

    private struct Signal: Encodable {
        let receivedAt: String
        let appID: String
        let clientUser: String
        let sessionID: String
        let type: String
        let payload: [String: String]
        let isTestMode: String
    }

    /// Mantiene anche il log locale, utile per debug
    private let localLog = LocalLogBackend()

    func send(event: String, properties: [String: String]) {
        localLog.send(event: event, properties: properties)

        guard !Secrets.telemetryDeckAppID.isEmpty else { return }

        // Proprietà comuni a tutti gli eventi
        var payload = properties
        payload["appVersion"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        payload["systemVersion"] = UIDevice.current.systemVersion
        payload["locale"] = Locale.current.identifier
        // Letto da UserDefaults (persistito da StoreManager) per non toccare
        // il singleton @MainActor da un contesto qualsiasi
        payload["isPro"] = UserDefaults.standard.bool(forKey: "isSublyPro") ? "true" : "false"

        #if DEBUG
        let isTestMode = "true"
        #else
        let isTestMode = "false"
        #endif

        let signal = Signal(
            receivedAt: Self.dateFormatter.string(from: Date()),
            appID: Secrets.telemetryDeckAppID,
            clientUser: Self.hashedClientUser,
            sessionID: Self.sessionID,
            type: event,
            payload: payload,
            isTestMode: isTestMode
        )

        guard let body = try? JSONEncoder().encode([signal]) else { return }

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        Task.detached(priority: .utility) {
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
