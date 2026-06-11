//
//  MilestoneTracker.swift
//  Subly
//
//  Soglie di abbonamenti tracciati alle quali proporre Pro (una sola volta).
//  Usa la stessa chiave UserDefaults ("shownMilestones") già impiegata
//  in passato, così le milestone già mostrate restano consumate.
//

import Foundation

enum MilestoneTracker {

    static let milestones = [3, 5, 10]
    private static let storageKey = "shownMilestones"

    private static var shown: Set<Int> {
        get {
            guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
            return (try? JSONDecoder().decode(Set<Int>.self, from: data)) ?? []
        }
        set {
            UserDefaults.standard.set((try? JSONEncoder().encode(newValue)) ?? Data(), forKey: storageKey)
        }
    }

    /// Ritorna la milestone più alta raggiunta e non ancora mostrata,
    /// marcandola come consumata. nil per utenti Pro o se nessuna soglia scatta.
    /// `>=` invece di `==`: il conteggio può saltare una soglia
    /// (es. abbonamenti aggiunti in blocco durante l'onboarding).
    static func checkAndMarkMilestone(count: Int, isPro: Bool) -> Int? {
        guard !isPro else { return nil }
        guard let milestone = milestones.last(where: { count >= $0 && !shown.contains($0) }) else {
            return nil
        }
        var updated = shown
        updated.insert(milestone)
        shown = updated
        return milestone
    }
}
