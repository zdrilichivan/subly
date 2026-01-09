# Subly - Contesto per Claude

## Panoramica

**Subly** è un'app iOS per la gestione degli abbonamenti personali con AI integrata. L'app aiuta gli utenti a tracciare, gestire e ottimizzare le proprie spese ricorrenti.

## Stack Tecnologico

- **Linguaggio**: Swift 5.9+ / SwiftUI
- **Pattern**: MVVM + Service Layer
- **Persistenza**: CloudKit (iCloud sync)
- **Target iOS**: 17.0+
- **Bundle ID**: `com.ivanzdrilich.SublySwift`

## Modello di Business

### Abbonamento Pro (Subscription)
- **Piano Settimanale**: €2,99/settimana
- **Piano Annuale**: €39,99/anno (risparmio ~74%)
- **Prova gratuita**: 3 giorni (sempre inclusa)
- **Limite Free**: 3 abbonamenti

### Product IDs (StoreKit 2)
```
com.ivanzdrilich.Subly.pro.weekly
com.ivanzdrilich.Subly.pro.annual
```

### Subscription Group
- **Nome**: Subly Pro
- **ID**: subly_pro_group

## App Store Metadata

### Titoli
| Lingua | Titolo |
|--------|--------|
| IT | Abbonamenti - Subly |
| EN | Subscriptions - Subly |
| ES | Suscripciones - Subly |

### Sottotitoli (max 30 caratteri)
| Lingua | Sottotitolo |
|--------|-------------|
| IT | Traccia, risparmia, cancella |
| EN | Track, save, cancel |
| ES | Rastrea, ahorra, cancela |

### Keywords (max 100 caratteri)
| Lingua | Keywords |
|--------|----------|
| IT | abbonamenti,gestione spese,tracker,risparmio,rinnovo,netflix,spotify,scadenze,budget,spese fisse |
| EN | subscriptions,subscription tracker,manage,expenses,budget,netflix,spotify,renewal,recurring,cancel |
| ES | suscripciones,gestión gastos,tracker,ahorro,renovación,netflix,spotify,presupuesto,gastos fijos,app |

### Localizzazioni Prodotti IAP

**Piano Settimanale (com.ivanzdrilich.Subly.pro.weekly)**
| Lingua | Display Name | Description |
|--------|--------------|-------------|
| IT | Subly Pro Settimanale | Tutte le funzionalità Pro |
| EN | Subly Pro Weekly | All Pro features |
| ES | Subly Pro Semanal | Todas las funciones Pro |

**Piano Annuale (com.ivanzdrilich.Subly.pro.annual)**
| Lingua | Display Name | Description |
|--------|--------------|-------------|
| IT | Subly Pro Annuale | Risparmia il 74% con il piano annuale |
| EN | Subly Pro Annual | Save 74% with annual plan |
| ES | Subly Pro Anual | Ahorra un 74% con el plan anual |

## Funzionalità Principali

### 1. Dashboard
- Greeting personalizzato (ora del giorno + nome)
- Card spesa mensile/annuale
- Lista abbonamenti ordinata per rinnovo
- Carousel "Cosa potresti fare" (insight spesa)

### 2. Scansione Email AI (Pro)
- Scansione Gmail per trovare abbonamenti nascosti
- Parser AI con Gemini (GeminiParserService)
- Fallback offline (OfflineEmailParser)
- OAuth2 per autenticazione Google

### 3. Money Coach AI (Pro)
- Consigli giornalieri personalizzati
- Quote motivazionali (WisdomQuoteService)
- Sfide settimanali di risparmio

### 4. Statistiche
- Grafico a torta per categoria
- Trend spesa mensile
- Prossimi rinnovi

### 5. Notifiche Smart
- 3 giorni, 1 giorno, giorno del rinnovo
- Notifiche interattive "Stai usando [Servizio]?"

## Struttura Chiave

```
Subly/
├── Models/
│   ├── Subscription.swift
│   ├── ServiceCatalog.swift      # 80+ servizi con URL cancellazione
│   └── DetectedSubscription.swift
├── Services/
│   ├── StoreManager.swift        # StoreKit 2 + stato Pro
│   ├── GeminiParserService.swift # AI parser per email
│   ├── OfflineEmailParser.swift  # Fallback parser
│   ├── GmailScannerService.swift # OAuth + fetch email
│   ├── WisdomQuoteService.swift  # Quote giornaliere
│   ├── CloudKitService.swift     # iCloud sync
│   └── NotificationService.swift
├── Views/
│   ├── Dashboard/DashboardView.swift
│   ├── EmailScan/EmailScanView.swift
│   ├── DailyTips/DailyTipsView.swift
│   ├── Paywall/PaywallOnboardingView.swift  # Paywall Apple-compliant
│   ├── Onboarding/OnboardingView.swift      # 5 pagine AI-focused
│   └── Settings/SettingsView.swift
└── docs/                         # Landing page e legal
    ├── index.html (IT)
    ├── index_en.html (EN)
    ├── index_es.html (ES)
    ├── privacy-policy.html
    ├── privacy-policy-en.html
    ├── privacy-policy-es.html
    ├── terms.html
    ├── terms_en.html
    └── terms_es.html
```

## Convenzioni Codice

- **Localizzazione**: `String(localized: "chiave")` per tutte le stringhe UI
- **Haptics**: `Haptic.impact(.light)`, `Haptic.selection()`, `Haptic.notification(.success)`
- **Spacing**: Usa costanti da `Spacing.xs`, `Spacing.sm`, `Spacing.md`, `Spacing.lg`
- **Typography**: `Typography.headline`, `Typography.body`, `Typography.caption`
- **CornerRadius**: `CornerRadius.sm`, `CornerRadius.md`, `CornerRadius.lg`
- **Colori brand**: `.appPrimary` (viola), `.appSecondary` (indaco)

## Apple Compliance

### Paywall Requirements (Guideline 3.1.2)
- Disclosure text con prezzo e rinnovo automatico
- Link separati a Terms e Privacy Policy
- Prova gratuita sempre inclusa (3 giorni)
- Prezzo chiaramente indicato nelle card
- Pulsante "Inizia la prova gratuita"

### Link Legal
- Terms IT: `https://zdrilichivan.github.io/subly/terms.html`
- Terms EN: `https://zdrilichivan.github.io/subly/terms_en.html`
- Terms ES: `https://zdrilichivan.github.io/subly/terms_es.html`
- Privacy IT: `https://zdrilichivan.github.io/subly/privacy-policy.html`
- Privacy EN: `https://zdrilichivan.github.io/subly/privacy-policy-en.html`
- Privacy ES: `https://zdrilichivan.github.io/subly/privacy-policy-es.html`

### Da aggiungere in App Store Connect
- Privacy Policy URL nel campo dedicato
- Terms nella descrizione app:
```
Termini e Condizioni: https://zdrilichivan.github.io/subly/terms.html
Privacy Policy: https://zdrilichivan.github.io/subly/privacy-policy.html
```

## Note Importanti

- **Repository pubblica**: Non pushare file sensibili (API keys, etc.)
- **Gemini API**: Chiave in GeminiParserService (non committare)
- **StoreKit testing**: Usa `StoreKitConfig.storekit` per test locali
- **Debug Pro rimosso**: Non c'è più toggle debug per attivare Pro

## Lingue Supportate

- Italiano (principale)
- Inglese
- Spagnolo

---

*Ultimo aggiornamento: Gennaio 2026*
