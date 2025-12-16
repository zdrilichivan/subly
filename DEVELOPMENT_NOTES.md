# Subly - Note di Sviluppo

## Panoramica App

**Subly** è un'app iOS per la gestione degli abbonamenti con focus sul **minimalismo digitale**. Aiuta gli utenti a:
- Tracciare tutti i loro abbonamenti
- Ricevere notifiche prima dei rinnovi
- Riflettere sulle proprie scelte di consumo
- Cancellare facilmente gli abbonamenti non necessari

---

## Architettura

- **Linguaggio**: Swift / SwiftUI
- **Pattern**: MVVM + Service Layer
- **Persistenza**: CloudKit (iCloud sync)
- **Target iOS**: 17.0+
- **Bundle ID**: `com.ivanzdrilich.SublySwift`

---

## Struttura Progetto

```
Subly/
├── SublyApp.swift                    # Entry point
├── Models/
│   ├── Subscription.swift            # Modello abbonamento
│   ├── ServiceCatalog.swift          # 80+ servizi con URL cancellazione
│   ├── BudgetSettings.swift          # Impostazioni budget
│   └── InsightModels.swift           # Modelli per insight/suggerimenti
├── ViewModels/
│   └── SubscriptionViewModel.swift   # Logica principale
├── Services/
│   ├── CloudKitService.swift         # Sync iCloud
│   ├── NotificationService.swift     # Notifiche push + interattive
│   ├── BudgetService.swift           # Calcoli budget
│   ├── InsightService.swift          # Suggerimenti minimalismo
│   └── StoreService.swift            # In-App Purchase (StoreKit 2)
├── Views/
│   ├── ContentView.swift             # TabView principale
│   ├── Dashboard/
│   │   └── DashboardView.swift       # Home con lista abbonamenti
│   ├── AddSubscription/
│   │   ├── AddSubscriptionView.swift
│   │   └── ServicePickerView.swift
│   ├── Stats/
│   │   └── StatsView.swift           # Statistiche + grafico torta
│   ├── Minimalism/
│   │   └── MinimalismView.swift      # Pagina minimalismo
│   ├── Settings/
│   │   └── SettingsView.swift        # Impostazioni + sezione PRO
│   ├── Subscription/
│   │   ├── SubscriptionDetailView.swift
│   │   └── EditSubscriptionView.swift
│   ├── Paywall/
│   │   └── PaywallView.swift         # Schermata acquisto
│   ├── Onboarding/
│   │   └── OnboardingView.swift      # Tutorial 8 pagine
│   └── Components/
│       ├── StatCard.swift
│       ├── SubscriptionRow.swift
│       ├── BudgetProgressView.swift
│       ├── ServiceLogoView.swift
│       └── InsightCards.swift        # Card carousel suggerimenti
└── Utilities/
    ├── Constants.swift               # Colori, animazioni
    └── Extensions.swift              # Estensioni utili
```

---

## Modello Freemium

### Limiti
- **Gratuito**: fino a 4 abbonamenti
- **PRO** (€0,99 una tantum): abbonamenti illimitati

### Product ID
```
com.ivanzdrilich.subly.unlimited
```

### Implementazione
- `StoreService.swift`: gestisce StoreKit 2
- `PaywallView.swift`: UI acquisto
- `AddSubscriptionView.swift`: mostra paywall se limite raggiunto
- `SettingsView.swift`: sezione PRO con stato e pulsante sblocco
- `DashboardView.swift`: badge PRO nel greeting

### Badge PRO
Visibile in:
- Dashboard (accanto al saluto)
- Impostazioni (accanto al nome utente)

---

## Funzionalità Principali

### 1. Dashboard
- Greeting personalizzato con ora del giorno
- Card totale mensile/annuale
- Lista abbonamenti ordinata per data rinnovo
- Carousel "Cosa potresti fare" (suggerimenti spesa alternativa)
- Card "Ti aiutiamo a cancellare" (espandibile)

### 2. Aggiungi Abbonamento
- Picker con 80+ servizi italiani
- Form: nome, costo, ciclo, data, note
- Preview impatto budget
- Verifica limite freemium

### 3. Statistiche
- Grafico a torta per categoria
- Budget status
- Prossimi rinnovi (7 giorni)

### 4. Minimalismo
- Punteggio minimalismo
- Carousel suggerimenti "Cosa potresti fare"
- Card espandibile aiuto cancellazione

### 5. Impostazioni
- Profilo (nome + foto)
- Sezione PRO (stato, sblocco, ripristino)
- Notifiche
- Budget mensile
- Tutorial (rivedi)
- Reset app

### 6. Notifiche
- 3 giorni, 1 giorno, giorno del rinnovo
- Notifiche interattive "Hai usato [Servizio]?"
  - Azioni: "Sì", "No", "Cancella abbonamento"

### 7. Onboarding
- 8 pagine che spiegano filosofia minimalismo digitale
- Richiesta permessi notifiche
- Input nome utente

---

## Servizi Supportati

80+ servizi italiani con:
- Nome e categoria
- Costo tipico
- URL cancellazione diretta

Categorie:
- Streaming (Netflix, Prime Video, Disney+, etc.)
- Musica (Spotify, Apple Music, etc.)
- Software (Adobe, Microsoft 365, etc.)
- Fitness (Fitbit, Nike, etc.)
- Cloud (iCloud, Google One, Dropbox, etc.)
- News (Corriere, Repubblica, etc.)
- Gaming (PlayStation Plus, Xbox, etc.)
- Telefonia (TIM, Vodafone, etc.)

---

## File Importanti

### Configuration.storekit
File per testing locale IAP (StoreKit Configuration). Da selezionare in:
`Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration`

### PrivacyInfo.xcprivacy
Privacy Manifest richiesto da Apple (2024+). Dichiara uso di UserDefaults.

### Subly.entitlements
Capabilities:
- CloudKit (`iCloud.com.ivanzdrilich.SublySwift`)
- Push Notifications

---

## App Store Connect

### Stato Attuale
- **App**: Inviata per revisione
- **IAP**: Pronta per l'invio (verrà rivista con l'app)

### Informazioni App
- **Nome**: Subly
- **Categoria**: Finanza
- **Prezzo**: Gratis (con IAP)
- **Privacy Policy**: Notion link

### In-App Purchase
- **Nome**: Sblocca Subly
- **ID**: `com.ivanzdrilich.subly.unlimited`
- **Tipo**: Non consumabile
- **Prezzo**: €0,99

---

## Problemi Noti / Da Verificare

### IAP su TestFlight
- Attualmente mostra "nessun acquisto da ripristinare"
- Causa: IAP non ancora elaborato da Apple
- Soluzione: Aspettare approvazione app

### Testing IAP
- Per testare localmente: usare `Configuration.storekit`
- Per testare su device: aspettare approvazione o usare Sandbox account

---

## Prossimi Step (Post-Approvazione)

1. Verificare funzionamento IAP su App Store
2. Chiedere recensioni a amici/famiglia
3. Considerare Apple Search Ads per promozione
4. Monitorare crash/feedback
5. Pianificare nuove funzionalità

---

## Comandi Utili

### Build & Archive
```
Xcode: Product → Archive → Distribute App → App Store Connect
```

### Nuovo Update
1. Modifica codice
2. Aumenta versione in Target → General → Version
3. Archive e upload
4. App Store Connect: nuova versione → seleziona build → invia

### TestFlight
L'app è automaticamente disponibile su TestFlight dopo ogni upload.

---

## Contatti & Link

- **Developer**: Ivan Zdrilich
- **Privacy Policy**: https://www.notion.so/Privacy-Policy-2cbee015438880c88a6bd1115528dbd8
- **App Store Connect**: https://appstoreconnect.apple.com

---

## Storico Modifiche Recenti

### Sessione Corrente
- Implementato modello freemium (StoreService, PaywallView)
- Aggiunto badge PRO in Dashboard e Settings
- Creato Privacy Manifest
- Creato Configuration.storekit per testing
- Inviato app per revisione App Store
- Stile UI: rimossi gradienti, tutto flat iOS style

---

*Ultimo aggiornamento: Dicembre 2024*
