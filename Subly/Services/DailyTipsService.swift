//
//  DailyTipsService.swift
//  Subly
//
//  Servizio per gestire i consigli finanziari giornalieri
//

import Foundation
import UserNotifications
import Combine

// MARK: - DailyTip Model

struct DailyTip: Identifiable, Codable {
    let id: Int
    let title: String
    let shortTitle: String // Per la card nella home
    let content: String
    let category: TipCategory
    let actionText: String? // Azione suggerita

    enum TipCategory: String, Codable, CaseIterable {
        case saving = "Risparmio"
        case budgeting = "Budget"
        case mindset = "Mindset"
        case challenge = "Sfida"
        case hack = "Life Hack"
        case awareness = "Consapevolezza"

        var icon: String {
            switch self {
            case .saving: return "banknote"
            case .budgeting: return "chart.pie"
            case .mindset: return "brain.head.profile"
            case .challenge: return "flame"
            case .hack: return "lightbulb"
            case .awareness: return "eye"
            }
        }

        var color: String {
            switch self {
            case .saving: return "green"
            case .budgeting: return "blue"
            case .mindset: return "purple"
            case .challenge: return "orange"
            case .hack: return "yellow"
            case .awareness: return "cyan"
            }
        }
    }
}

// MARK: - DailyTipsService

@MainActor
class DailyTipsService: ObservableObject {

    static let shared = DailyTipsService()

    @Published var todaysTip: DailyTip
    @Published var notificationsEnabled = false

    private let tips: [DailyTip] = DailyTipsService.loadTips()

    private init() {
        self.todaysTip = DailyTipsService.loadTips().first!
        self.todaysTip = getTodaysTip()
        checkNotificationStatus()
    }

    // MARK: - Get Today's Tip

    /// Restituisce il consiglio del giorno basato sulla data
    /// Tutti gli utenti vedono lo stesso consiglio nello stesso giorno
    func getTodaysTip() -> DailyTip {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % tips.count
        return tips[index]
    }

    /// Aggiorna il tip (chiamare quando l'app torna in foreground)
    func refreshTodaysTip() {
        todaysTip = getTodaysTip()
    }

    // MARK: - Notifications

    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.notificationsEnabled = granted
            }
            if granted {
                scheduleDailyNotification()
            }
            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            return false
        }
    }

    func scheduleDailyNotification() {
        // Rimuovi notifiche esistenti
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-tip"])

        // Crea il contenuto
        let content = UNMutableNotificationContent()
        content.title = "💡 Il tuo consiglio finanziario"
        content.body = "Scopri come risparmiare oggi. Tocca per leggere!"
        content.sound = .default

        // Schedula alle 9:00 ogni giorno
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-tip", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Daily notification scheduled for 9:00 AM")
            }
        }
    }

    func disableNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-tip"])
        notificationsEnabled = false
    }

    // MARK: - Load Tips

    private static func loadTips() -> [DailyTip] {
        return [
            // RISPARMIO (10)
            DailyTip(
                id: 1,
                title: "La Regola del 50/30/20",
                shortTitle: "Regola 50/30/20",
                content: "Dividi il tuo stipendio: 50% per necessità (affitto, bollette, cibo), 30% per desideri (svago, shopping), 20% per risparmi e debiti. È il metodo più semplice per iniziare a gestire i soldi.",
                category: .budgeting,
                actionText: "Calcola le tue percentuali attuali"
            ),
            DailyTip(
                id: 2,
                title: "Il Costo Reale di Netflix",
                shortTitle: "Netflix: quanto costa davvero?",
                content: "€15.99/mese sembrano poco, ma sono €192/anno. In 10 anni sono quasi €2.000. Chiediti: lo uso abbastanza? Potrei condividere l'account? Esistono alternative gratuite?",
                category: .awareness,
                actionText: "Controlla quante ore guardi al mese"
            ),
            DailyTip(
                id: 3,
                title: "La Regola delle 24 Ore",
                shortTitle: "Aspetta 24 ore",
                content: "Prima di ogni acquisto non essenziale sopra i €30, aspetta 24 ore. Il 70% delle volte scoprirai che non lo volevi davvero. È il modo più efficace per evitare acquisti impulsivi.",
                category: .mindset,
                actionText: "Prova con il prossimo acquisto"
            ),
            DailyTip(
                id: 4,
                title: "Negozia le Tue Bollette",
                shortTitle: "Negozia le bollette",
                content: "Chiama il tuo operatore telefonico o internet e chiedi uno sconto. Dì che stai valutando la concorrenza. Nel 60% dei casi otterrai una riduzione. Bastano 10 minuti per risparmiare €100+ all'anno.",
                category: .hack,
                actionText: "Chiama oggi il tuo operatore"
            ),
            DailyTip(
                id: 5,
                title: "Il Metodo del Barattolo",
                shortTitle: "Metodo del barattolo",
                content: "Ogni sera, metti le monete che hai in tasca in un barattolo. A fine anno avrai accumulato €200-400 senza accorgertene. È risparmio invisibile che funziona.",
                category: .saving,
                actionText: "Trova un barattolo stasera"
            ),
            DailyTip(
                id: 6,
                title: "Annulla gli Abbonamenti Zombie",
                shortTitle: "Abbonamenti zombie",
                content: "Gli abbonamenti 'zombie' sono quelli che paghi ma non usi. La persona media ne ha 2-3 e spreca €300/anno. Controlla i tuoi abbonamenti: se non l'hai usato nell'ultimo mese, cancellalo.",
                category: .awareness,
                actionText: "Trova il tuo abbonamento zombie"
            ),
            DailyTip(
                id: 7,
                title: "Il Caffè al Bar Costa Caro",
                shortTitle: "Il vero costo del caffè",
                content: "Un caffè al bar costa €1.20. Ogni giorno lavorativo sono €26/mese, €312/anno. Una moka costa €20 e il caffè in polvere €0.10 a tazza. Risparmio: €280/anno.",
                category: .awareness,
                actionText: "Calcola quanto spendi in caffè"
            ),
            DailyTip(
                id: 8,
                title: "Usa la Lista della Spesa",
                shortTitle: "Mai senza lista",
                content: "Chi fa la spesa senza lista spende in media il 23% in più. Scrivi cosa ti serve PRIMA di entrare nel supermercato e attieniti rigorosamente alla lista.",
                category: .hack,
                actionText: "Prepara la lista per la prossima spesa"
            ),
            DailyTip(
                id: 9,
                title: "Il Pagamento Automatico dei Risparmi",
                shortTitle: "Risparmio automatico",
                content: "Imposta un bonifico automatico il giorno dello stipendio: anche solo €50/mese verso un conto risparmio. Non vedrai quei soldi e non ti mancheranno. In 5 anni avrai €3.000+.",
                category: .saving,
                actionText: "Imposta il bonifico automatico"
            ),
            DailyTip(
                id: 10,
                title: "Confronta Prima di Rinnovare",
                shortTitle: "Confronta sempre",
                content: "Prima che scada un'assicurazione o un contratto, confronta SEMPRE con la concorrenza. Le aziende offrono i prezzi migliori ai nuovi clienti, non a quelli fedeli.",
                category: .hack,
                actionText: "Segna la scadenza del prossimo rinnovo"
            ),

            // SFIDE (10)
            DailyTip(
                id: 11,
                title: "Sfida: Weekend Senza Spese",
                shortTitle: "Weekend a €0",
                content: "Prova a passare un intero weekend senza spendere nulla. Cucina con quello che hai, fai attività gratuite (passeggiata, parco, film a casa). Scoprirai che il divertimento non costa.",
                category: .challenge,
                actionText: "Programma il tuo weekend gratis"
            ),
            DailyTip(
                id: 12,
                title: "Sfida: 7 Giorni Senza Amazon",
                shortTitle: "7 giorni senza Amazon",
                content: "Per una settimana, non comprare nulla online. Metti gli articoli nel carrello ma non completare l'acquisto. A fine settimana, guarda quanti ne vuoi ancora davvero.",
                category: .challenge,
                actionText: "Inizia oggi la sfida"
            ),
            DailyTip(
                id: 13,
                title: "Sfida: Porta il Pranzo al Lavoro",
                shortTitle: "Pranzo da casa",
                content: "Per 5 giorni, porta il pranzo da casa invece di comprarlo. Un pranzo fuori costa €8-12, uno da casa €2-3. Risparmio settimanale: €30-45. Mensile: €120-180.",
                category: .challenge,
                actionText: "Prepara il pranzo per domani"
            ),
            DailyTip(
                id: 14,
                title: "Sfida: Niente Caffè Fuori per 3 Giorni",
                shortTitle: "3 giorni senza caffè fuori",
                content: "Per 3 giorni, fai il caffè a casa o in ufficio. Sembra poco, ma se diventa abitudine risparmi €300/anno. Bonus: il caffè fatto bene a casa è spesso più buono.",
                category: .challenge,
                actionText: "Accetta la sfida"
            ),
            DailyTip(
                id: 15,
                title: "Sfida: Decluttering = Guadagno",
                shortTitle: "Vendi quello che non usi",
                content: "Oggi trova 5 oggetti che non usi da 6+ mesi e mettili in vendita su Vinted o Subito. Quello che per te è inutile, per altri è un tesoro. Media guadagnata: €50-200.",
                category: .challenge,
                actionText: "Trova 5 oggetti da vendere"
            ),
            DailyTip(
                id: 16,
                title: "Sfida: Giornata Cash-Only",
                shortTitle: "Solo contanti oggi",
                content: "Oggi usa solo contanti. Quando vedi fisicamente i soldi uscire dal portafoglio, spendi in media il 12-18% in meno. Il dolore del pagamento diventa reale.",
                category: .challenge,
                actionText: "Preleva il budget di oggi"
            ),
            DailyTip(
                id: 17,
                title: "Sfida: Settimana Senza Delivery",
                shortTitle: "7 giorni senza delivery",
                content: "Per una settimana, niente Glovo, Deliveroo o JustEat. Un ordine medio costa €18-25 (cibo + consegna + mancia). Cucina a casa: risparmio €50-100 in una settimana.",
                category: .challenge,
                actionText: "Pianifica i pasti della settimana"
            ),
            DailyTip(
                id: 18,
                title: "Sfida: Trova 3 Abbonamenti da Tagliare",
                shortTitle: "Taglia 3 abbonamenti",
                content: "Guarda tutti i tuoi abbonamenti e trovane 3 che puoi cancellare o mettere in pausa. Non devi per forza cancellarli per sempre: anche solo 3 mesi di pausa ti fanno risparmiare.",
                category: .challenge,
                actionText: "Rivedi i tuoi abbonamenti ora"
            ),
            DailyTip(
                id: 19,
                title: "Sfida: Un Mese di Spese Tracciate",
                shortTitle: "Traccia tutto per 30 giorni",
                content: "Per 30 giorni, scrivi OGNI spesa che fai. Anche il caffè da €1. A fine mese avrai una mappa chiara di dove vanno i tuoi soldi. La consapevolezza è il primo passo.",
                category: .challenge,
                actionText: "Inizia a tracciare da oggi"
            ),
            DailyTip(
                id: 20,
                title: "Sfida: Sostituisci un Abbonamento con Free",
                shortTitle: "Trova l'alternativa gratuita",
                content: "Scegli un abbonamento e cerca un'alternativa gratuita per 2 settimane. Spotify → YouTube Music Free. Netflix → Biblioteca digitale. Palestra → Allenamento a casa.",
                category: .challenge,
                actionText: "Scegli quale provare"
            ),

            // MINDSET (10)
            DailyTip(
                id: 21,
                title: "I Soldi Sono Tempo",
                shortTitle: "Soldi = Tempo di vita",
                content: "Se guadagni €10/ora netti, un acquisto da €50 ti costa 5 ore di vita. Prima di comprare, chiediti: 'Vale X ore del mio tempo?' Cambia prospettiva, cambia comportamento.",
                category: .mindset,
                actionText: "Calcola il tuo valore orario"
            ),
            DailyTip(
                id: 22,
                title: "La Felicità Non Si Compra",
                shortTitle: "Felicità ≠ Acquisti",
                content: "Gli studi dimostrano che dopo i bisogni base, più soldi non aumentano la felicità. Le esperienze con le persone care valgono più di qualsiasi oggetto. Investi in relazioni, non in cose.",
                category: .mindset,
                actionText: "Pianifica un'esperienza con chi ami"
            ),
            DailyTip(
                id: 23,
                title: "Il Costo Nascosto dello Stress Finanziario",
                shortTitle: "Lo stress costa caro",
                content: "Lo stress finanziario causa problemi di salute, relazioni rovinate e decisioni sbagliate. Ogni euro risparmiato oggi è tranquillità domani. Il risparmio è self-care.",
                category: .mindset,
                actionText: "Crea un fondo emergenza"
            ),
            DailyTip(
                id: 24,
                title: "Smetti di Confrontarti",
                shortTitle: "Stop confronti social",
                content: "Su Instagram tutti sembrano ricchi. La realtà: l'80% vive sopra le proprie possibilità. Non confrontare il tuo dietro le quinte con il loro highlight reel. Vivi secondo i tuoi mezzi.",
                category: .mindset,
                actionText: "Smetti di seguire chi ti fa sentire povero"
            ),
            DailyTip(
                id: 25,
                title: "Paga Te Stesso Prima",
                shortTitle: "Prima paghi te stesso",
                content: "Appena arriva lo stipendio, prima di pagare bollette o comprare qualsiasi cosa, metti da parte il 10-20% per te. I risparmi non sono quello che avanza, sono la priorità.",
                category: .mindset,
                actionText: "Imposta il risparmio automatico"
            ),
            DailyTip(
                id: 26,
                title: "La Gratificazione Ritardata",
                shortTitle: "Saper aspettare paga",
                content: "Chi sa aspettare per avere qualcosa di meglio ha più successo finanziario. Ogni volta che resisti a un acquisto impulsivo, stai allenando un muscolo che ti renderà ricco.",
                category: .mindset,
                actionText: "Rimanda un acquisto di una settimana"
            ),
            DailyTip(
                id: 27,
                title: "Gli Oggetti Ti Possiedono",
                shortTitle: "Meno cose, più libertà",
                content: "Ogni oggetto richiede spazio, manutenzione, attenzione. Più possiedi, più sei posseduto. Il minimalismo non è povertà, è libertà. Meno cose = meno stress.",
                category: .mindset,
                actionText: "Libera un cassetto oggi"
            ),
            DailyTip(
                id: 28,
                title: "Il Potere del 'No'",
                shortTitle: "Impara a dire No",
                content: "Ogni 'sì' a una spesa è un 'no' ai tuoi obiettivi finanziari. Impara a dire no: alle uscite costose, agli acquisti inutili, alle pressioni sociali. Il 'no' è il tuo superpotere finanziario.",
                category: .mindset,
                actionText: "Dì un 'no' oggi"
            ),
            DailyTip(
                id: 29,
                title: "Definisci il Tuo 'Abbastanza'",
                shortTitle: "Quanto è abbastanza?",
                content: "La società ti dice che non è mai abbastanza. Ma tu hai definito il TUO abbastanza? Di quanto hai bisogno per essere sereno? Definiscilo, e smetti di rincorrere sempre di più.",
                category: .mindset,
                actionText: "Scrivi il tuo numero"
            ),
            DailyTip(
                id: 30,
                title: "I Ricchi Comprano Asset",
                shortTitle: "Asset vs Passività",
                content: "I poveri comprano cose che perdono valore (auto, vestiti, gadget). I ricchi comprano cose che generano valore (investimenti, formazione, strumenti di lavoro). Su cosa spendi i tuoi soldi?",
                category: .mindset,
                actionText: "Classifica le tue ultime 5 spese"
            ),

            // LIFE HACKS (10)
            DailyTip(
                id: 31,
                title: "Le App di Cashback",
                shortTitle: "Cashback sugli acquisti",
                content: "App come Satispay, Stocard o le carte con cashback ti restituiscono l'1-5% su ogni acquisto. Su €500/mese di spese, sono €60-300/anno senza fare nulla di diverso.",
                category: .hack,
                actionText: "Scarica un'app cashback"
            ),
            DailyTip(
                id: 32,
                title: "Compra Usato di Qualità",
                shortTitle: "Usato > Nuovo economico",
                content: "Un iPhone ricondizionato costa il 30-40% in meno e funziona perfettamente. Vinted, Subito, BackMarket: l'usato di qualità è il segreto dei risparmiatori intelligenti.",
                category: .hack,
                actionText: "Cerca il prossimo acquisto usato"
            ),
            DailyTip(
                id: 33,
                title: "La Biblioteca è Gratis",
                shortTitle: "Biblioteca > Kindle Unlimited",
                content: "La tessera della biblioteca è gratuita. Libri, ebook, audiolibri, DVD, riviste: tutto gratis. Perché pagare Kindle Unlimited o Audible quando la biblioteca offre lo stesso?",
                category: .hack,
                actionText: "Fai la tessera della biblioteca"
            ),
            DailyTip(
                id: 34,
                title: "Condividi gli Abbonamenti",
                shortTitle: "Abbonamenti condivisi",
                content: "Spotify Family, Netflix, Disney+: dividi con amici o parenti. Un Netflix da €18/mese diviso in 4 costa €4.50 a testa. Risparmio: €160/anno solo su questo.",
                category: .hack,
                actionText: "Proponi una condivisione"
            ),
            DailyTip(
                id: 35,
                title: "Fai la Spesa a Stomaco Pieno",
                shortTitle: "Mai fare la spesa affamato",
                content: "Gli studi dimostrano che fare la spesa affamati aumenta gli acquisti del 15-20%. Mangia prima di andare al supermercato. Il tuo portafoglio ti ringrazierà.",
                category: .hack,
                actionText: "Programma la spesa dopo pranzo"
            ),
            DailyTip(
                id: 36,
                title: "Usa i Coupon Digitali",
                shortTitle: "Coupon e sconti app",
                content: "Le app dei supermercati (Esselunga, Coop, Lidl) offrono coupon esclusivi. 10 minuti a settimana per scaricarli possono farti risparmiare €20-40/mese.",
                category: .hack,
                actionText: "Scarica l'app del tuo supermercato"
            ),
            DailyTip(
                id: 37,
                title: "Il Trucco del Termostato",
                shortTitle: "1 grado = 7% risparmio",
                content: "Abbassare il riscaldamento di 1°C riduce la bolletta del 7%. Da 21°C a 20°C non senti la differenza, ma il portafoglio sì. €50-100/anno risparmiati.",
                category: .hack,
                actionText: "Abbassa il termostato di 1 grado"
            ),
            DailyTip(
                id: 38,
                title: "Confronta i Prezzi Online",
                shortTitle: "Mai comprare al primo prezzo",
                content: "Prima di ogni acquisto online, cerca su Trovaprezzi o Google Shopping. Lo stesso prodotto può costare il 20-40% in meno su un altro sito. 2 minuti = €20+ risparmiati.",
                category: .hack,
                actionText: "Confronta il prossimo acquisto"
            ),
            DailyTip(
                id: 39,
                title: "Annulla e Riabbonati",
                shortTitle: "Il trucco della cancellazione",
                content: "Quando cancelli un abbonamento, spesso ti offrono sconti per restare (30-50% off). Prova a cancellare i tuoi abbonamenti: potresti ottenere prezzi migliori.",
                category: .hack,
                actionText: "Prova a cancellare un abbonamento"
            ),
            DailyTip(
                id: 40,
                title: "I Generici Sono Uguali",
                shortTitle: "Marca bianca = stessa qualità",
                content: "I farmaci generici, i prodotti a marchio del supermercato: spesso sono identici ai brand costosi. Stessi ingredienti, stessa fabbrica, prezzo 30-50% inferiore.",
                category: .hack,
                actionText: "Prova un prodotto generico"
            ),

            // CONSAPEVOLEZZA (10)
            DailyTip(
                id: 41,
                title: "Il Lifestyle Creep",
                shortTitle: "Attenzione al lifestyle creep",
                content: "Quando guadagni di più, spendi di più. È il 'lifestyle creep'. L'aumento di stipendio finisce in una macchina più bella, non in risparmi. Aumenta i risparmi, non lo stile di vita.",
                category: .awareness,
                actionText: "Risparmia il 50% del prossimo aumento"
            ),
            DailyTip(
                id: 42,
                title: "Le Micro-Transazioni Ti Dissanguano",
                shortTitle: "Piccole spese, grandi perdite",
                content: "€2 qui, €5 là. Le piccole spese sembrano innocue ma sommandole fanno €100-300/mese. Traccia TUTTO per un mese: rimarrai scioccato da dove vanno i tuoi soldi.",
                category: .awareness,
                actionText: "Traccia le spese sotto €10"
            ),
            DailyTip(
                id: 43,
                title: "Il Costo della Comodità",
                shortTitle: "La comodità ha un prezzo",
                content: "Delivery invece di cucinare. Taxi invece di mezzi. Amazon invece di negozi. La comodità costa il 20-50% in più. Chiediti: quanto vale davvero questo comfort?",
                category: .awareness,
                actionText: "Scegli l'opzione scomoda oggi"
            ),
            DailyTip(
                id: 44,
                title: "Gli Abbonamenti Annuali Costano Meno",
                shortTitle: "Annuale > Mensile",
                content: "Netflix, Spotify, palestra: l'abbonamento annuale costa il 15-30% in meno del mensile. Se sei sicuro di usarlo, paga annualmente e risparmia.",
                category: .awareness,
                actionText: "Converti un mensile in annuale"
            ),
            DailyTip(
                id: 45,
                title: "Il Martedì è il Giorno Migliore",
                shortTitle: "Voli? Compra di martedì",
                content: "I voli costano meno se prenotati il martedì pomeriggio. I prezzi sono più alti nel weekend quando tutti cercano. Stesso volo, giorno diverso, €50-200 di differenza.",
                category: .awareness,
                actionText: "Cerca voli il martedì"
            ),
            DailyTip(
                id: 46,
                title: "Il Black Friday È Spesso una Truffa",
                shortTitle: "Black Friday: attenzione",
                content: "Il 60% delle offerte Black Friday non sono vere offerte: i prezzi vengono alzati prima e poi 'scontati'. Usa CamelCamelCamel per vedere la storia dei prezzi su Amazon.",
                category: .awareness,
                actionText: "Installa un tracker di prezzi"
            ),
            DailyTip(
                id: 47,
                title: "Stai Pagando per Non Usarlo",
                shortTitle: "Paghi la palestra che non usi",
                content: "L'80% degli iscritti in palestra non ci va regolarmente. €40/mese per 12 mesi = €480/anno per... sensi di colpa. Sii onesto: la usi davvero?",
                category: .awareness,
                actionText: "Conta quante volte sei andato questo mese"
            ),
            DailyTip(
                id: 48,
                title: "I 'Saldi' Sono Marketing",
                shortTitle: "Saldi = trucco psicologico",
                content: "Vedere '-50%' attiva il cervello come una droga. Ma stai risparmiando solo se avresti comprato comunque quell'oggetto a prezzo pieno. Altrimenti stai spendendo, non risparmiando.",
                category: .awareness,
                actionText: "Prima del saldo, chiediti: lo comprerei a prezzo pieno?"
            ),
            DailyTip(
                id: 49,
                title: "L'Energia della Sera Costa Meno",
                shortTitle: "Lavatrice di notte",
                content: "Se hai una tariffa bioraria, fare lavatrice e lavastoviglie dopo le 19 o nei weekend costa il 20-30% in meno. Stesso risultato, meno soldi.",
                category: .awareness,
                actionText: "Imposta la lavatrice per stasera"
            ),
            DailyTip(
                id: 50,
                title: "Ogni Oggetto Ha un Costo Nascosto",
                shortTitle: "Il costo nascosto degli oggetti",
                content: "Comprare è solo l'inizio. Ogni oggetto richiede spazio (affitto), manutenzione (tempo), assicurazione, e prima o poi smaltimento. Il vero costo è sempre più alto del prezzo.",
                category: .awareness,
                actionText: "Considera il costo totale del prossimo acquisto"
            )
        ]
    }
}
