//
//  AdManager.swift
//  Subly
//
//  Gestione pubblicità Google AdMob - Solo Interstitial
//

import Foundation
import GoogleMobileAds
import UIKit
import Combine

@MainActor
class AdManager: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = AdManager()

    // MARK: - Ad Unit IDs (TEST IDs - sostituire con quelli reali in produzione)
    // Interstitial Test ID: ca-app-pub-3940256099942544/4411468910

    #if DEBUG
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    #else
    // PRODUZIONE: ID reale AdMob
    private let interstitialAdUnitID = "ca-app-pub-7270829805879314/1032787089"
    #endif

    // MARK: - Properties
    private var interstitialAd: InterstitialAd?
    @Published var isInterstitialReady = false

    // Completion handler per navigazione dopo dismiss
    private var onAdDismissed: (() -> Void)?

    // Tracking ads mostrate per sessione (reset all'avvio app)
    private var shownAdForStats = false
    private var shownAdForCoach = false

    // MARK: - Init
    private override init() {
        super.init()
        setupForegroundObserver()
    }

    // MARK: - Initialize SDK e precarica ad
    static func configure() {
        MobileAds.shared.start { status in
            print("📱 AdMob SDK initialized")
            // Precarica l'interstitial appena l'SDK è pronto
            Task { @MainActor in
                AdManager.shared.loadInterstitialAd()
            }
        }
    }

    // MARK: - Foreground Observer (reset ads quando l'app torna attiva)
    private func setupForegroundObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.resetSessionAds()
            }
        }
    }

    /// Resetta i flag delle ads per la nuova sessione
    private func resetSessionAds() {
        print("📱 App returned to foreground - resetting session ads")
        shownAdForStats = false
        shownAdForCoach = false
    }

    // MARK: - Interstitial Ad

    /// Precarica l'interstitial per averlo pronto
    func loadInterstitialAd() {
        let request = Request()

        InterstitialAd.load(with: interstitialAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Failed to load interstitial ad: \(error.localizedDescription)")
                Task { @MainActor in
                    self.isInterstitialReady = false
                }
                return
            }

            print("✅ Interstitial ad loaded and ready")
            Task { @MainActor in
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
                self.isInterstitialReady = true
            }
        }
    }

    /// Mostra interstitial prima di navigare a una pagina
    /// - Parameters:
    ///   - viewController: Il view controller da cui presentare l'ad
    ///   - completion: Chiamato quando l'ad viene chiuso (o subito se non disponibile)
    func showInterstitial(from viewController: UIViewController, completion: @escaping () -> Void) {
        guard isInterstitialReady, let ad = interstitialAd else {
            print("⚠️ Interstitial not ready, proceeding without ad")
            completion()
            loadInterstitialAd() // Ricarica per la prossima volta
            return
        }

        // Salva il completion per chiamarlo dopo il dismiss
        self.onAdDismissed = completion

        // Mostra l'ad
        ad.present(from: viewController)
    }

    /// Mostra interstitial senza callback (fire and forget)
    func showInterstitial(from viewController: UIViewController) {
        showInterstitial(from: viewController) { }
    }

    // MARK: - Session-based Ad Control

    enum AdLocation {
        case stats
        case coach
    }

    /// Controlla se l'ad è già stata mostrata per questa pagina nella sessione
    func hasShownAd(for location: AdLocation) -> Bool {
        switch location {
        case .stats: return shownAdForStats
        case .coach: return shownAdForCoach
        }
    }

    /// Mostra interstitial con delay, solo se non già mostrata per questa pagina
    /// - Parameters:
    ///   - location: La pagina che richiede l'ad
    ///   - delay: Delay in secondi prima di mostrare l'ad
    func showInterstitialOncePerSession(for location: AdLocation, delay: TimeInterval = 2.0) {
        // Se già mostrata per questa pagina, skip
        guard !hasShownAd(for: location) else {
            print("📱 Ad already shown for \(location) this session - skipping")
            return
        }

        // Segna come mostrata
        switch location {
        case .stats: shownAdForStats = true
        case .coach: shownAdForCoach = true
        }

        // Mostra con delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            guard let viewController = UIApplication.shared.currentViewController else {
                print("⚠️ No view controller available for ad")
                return
            }

            self.showInterstitial(from: viewController)
        }
    }
}

// MARK: - FullScreenContentDelegate
extension AdManager: FullScreenContentDelegate {

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            print("📱 Interstitial dismissed - proceeding with navigation")
            self.isInterstitialReady = false

            // Chiama il completion per procedere con la navigazione
            self.onAdDismissed?()
            self.onAdDismissed = nil

            // Ricarica per la prossima volta
            self.loadInterstitialAd()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("❌ Interstitial failed to present: \(error.localizedDescription)")
            self.isInterstitialReady = false

            // Procedi comunque con la navigazione
            self.onAdDismissed?()
            self.onAdDismissed = nil

            // Ricarica per la prossima volta
            self.loadInterstitialAd()
        }
    }

    nonisolated func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Interstitial presenting")
    }
}

// MARK: - Helper per ottenere il ViewController corrente
extension UIApplication {
    var currentViewController: UIViewController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }

        var currentVC = rootViewController
        while let presentedVC = currentVC.presentedViewController {
            currentVC = presentedVC
        }
        return currentVC
    }
}
