//
//  UpdateCheckService.swift
//  Subly
//
//  Controlla sull'App Store (iTunes Lookup, API pubblica, niente backend)
//  se esiste una versione più recente: da questa release in poi possiamo
//  invitare gli utenti ad aggiornare con un banner gentile in dashboard.
//  Al massimo un controllo al giorno, banner dismissibile per versione.
//

import Foundation
import Combine

@MainActor
final class UpdateCheckService: ObservableObject {

    static let shared = UpdateCheckService()

    @Published private(set) var availableVersion: String?
    @Published private(set) var storeURL: URL?

    private let defaults = UserDefaults.standard
    private init() {}

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    /// Banner da mostrare: c'è una versione nuova e l'utente non l'ha ignorata
    var shouldShowBanner: Bool {
        guard let available = availableVersion else { return false }
        return defaults.string(forKey: "dismissedUpdateVersion") != available
    }

    func dismissBanner() {
        if let available = availableVersion {
            defaults.set(available, forKey: "dismissedUpdateVersion")
        }
        availableVersion = nil
    }

    /// Controlla al massimo una volta al giorno
    func checkIfNeeded() async {
        let lastCheck = defaults.object(forKey: "lastUpdateCheck") as? Date ?? .distantPast
        guard !Calendar.current.isDateInToday(lastCheck) else { return }
        defaults.set(Date(), forKey: "lastUpdateCheck")

        guard let bundleID = Bundle.main.bundleIdentifier,
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first,
                  let storeVersion = first["version"] as? String else { return }

            if Self.isVersion(storeVersion, newerThan: currentVersion) {
                availableVersion = storeVersion
                if let track = first["trackViewUrl"] as? String {
                    storeURL = URL(string: track)
                }
            }
        } catch {
            // Silenzio: il controllo aggiornamenti non deve mai disturbare
        }
    }

    /// Confronto numerico per componenti ("1.10.0" > "1.9.2")
    static func isVersion(_ lhs: String, newerThan rhs: String) -> Bool {
        let l = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let r = rhs.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(l.count, r.count) {
            let a = i < l.count ? l[i] : 0
            let b = i < r.count ? r[i] : 0
            if a != b { return a > b }
        }
        return false
    }
}
