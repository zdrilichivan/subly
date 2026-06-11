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

        var localizedName: String {
            switch self {
            case .saving: return String(localized: "Risparmio")
            case .budgeting: return String(localized: "Budget")
            case .mindset: return String(localized: "Mindset")
            case .challenge: return String(localized: "Sfida")
            case .hack: return String(localized: "Life Hack")
            case .awareness: return String(localized: "Consapevolezza")
            }
        }

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

    /// Sfide settimanali (usate da PersonalCoachService per la rotazione)
    var challengeTips: [DailyTip] {
        tips.filter { $0.category == .challenge }
    }

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
        content.title = String(localized: "💡 Il tuo consiglio finanziario")
        content.body = String(localized: "Scopri come risparmiare oggi. Tocca per leggere!")
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
                title: String(localized: "La Regola del 50/30/20"),
                shortTitle: String(localized: "Regola 50/30/20"),
                content: String(localized: "Dividi il tuo stipendio: 50% per necessità (affitto, bollette, cibo), 30% per desideri (svago, shopping), 20% per risparmi e debiti. È il metodo più semplice per iniziare a gestire i soldi."),
                category: .budgeting,
                actionText: String(localized: "Calcola le tue percentuali attuali")
            ),
            DailyTip(
                id: 2,
                title: String(localized: "Il Costo Reale di Netflix"),
                shortTitle: String(localized: "Netflix: quanto costa davvero?"),
                content: String(localized: "€15.99/mese sembrano poco, ma sono €192/anno. In 10 anni sono quasi €2.000. Chiediti: lo uso abbastanza? Potrei condividere l'account? Esistono alternative gratuite?"),
                category: .awareness,
                actionText: String(localized: "Controlla quante ore guardi al mese")
            ),
            DailyTip(
                id: 3,
                title: String(localized: "La Regola delle 24 Ore"),
                shortTitle: String(localized: "Aspetta 24 ore"),
                content: String(localized: "Prima di ogni acquisto non essenziale sopra i €30, aspetta 24 ore. Il 70% delle volte scoprirai che non lo volevi davvero. È il modo più efficace per evitare acquisti impulsivi."),
                category: .mindset,
                actionText: String(localized: "Prova con il prossimo acquisto")
            ),
            DailyTip(
                id: 4,
                title: String(localized: "Negozia le Tue Bollette"),
                shortTitle: String(localized: "Negozia le bollette"),
                content: String(localized: "Chiama il tuo operatore telefonico o internet e chiedi uno sconto. Dì che stai valutando la concorrenza. Nel 60% dei casi otterrai una riduzione. Bastano 10 minuti per risparmiare €100+ all'anno."),
                category: .hack,
                actionText: String(localized: "Chiama oggi il tuo operatore")
            ),
            DailyTip(
                id: 5,
                title: String(localized: "Il Metodo del Barattolo"),
                shortTitle: String(localized: "Metodo del barattolo"),
                content: String(localized: "Ogni sera, metti le monete che hai in tasca in un barattolo. A fine anno avrai accumulato €200-400 senza accorgertene. È risparmio invisibile che funziona."),
                category: .saving,
                actionText: String(localized: "Trova un barattolo stasera")
            ),
            DailyTip(
                id: 6,
                title: String(localized: "Annulla gli Abbonamenti Zombie"),
                shortTitle: String(localized: "Abbonamenti zombie"),
                content: String(localized: "Gli abbonamenti 'zombie' sono quelli che paghi ma non usi. La persona media ne ha 2-3 e spreca €300/anno. Controlla i tuoi abbonamenti: se non l'hai usato nell'ultimo mese, cancellalo."),
                category: .awareness,
                actionText: String(localized: "Trova il tuo abbonamento zombie")
            ),
            DailyTip(
                id: 7,
                title: String(localized: "Il Caffè al Bar Costa Caro"),
                shortTitle: String(localized: "Il vero costo del caffè"),
                content: String(localized: "Un caffè al bar costa €1.20. Ogni giorno lavorativo sono €26/mese, €312/anno. Una moka costa €20 e il caffè in polvere €0.10 a tazza. Risparmio: €280/anno."),
                category: .awareness,
                actionText: String(localized: "Calcola quanto spendi in caffè")
            ),
            DailyTip(
                id: 8,
                title: String(localized: "Usa la Lista della Spesa"),
                shortTitle: String(localized: "Mai senza lista"),
                content: String(localized: "Chi fa la spesa senza lista spende in media il 23% in più. Scrivi cosa ti serve PRIMA di entrare nel supermercato e attieniti rigorosamente alla lista."),
                category: .hack,
                actionText: String(localized: "Prepara la lista per la prossima spesa")
            ),
            DailyTip(
                id: 9,
                title: String(localized: "Il Pagamento Automatico dei Risparmi"),
                shortTitle: String(localized: "Risparmio automatico"),
                content: String(localized: "Imposta un bonifico automatico il giorno dello stipendio: anche solo €50/mese verso un conto risparmio. Non vedrai quei soldi e non ti mancheranno. In 5 anni avrai €3.000+."),
                category: .saving,
                actionText: String(localized: "Imposta il bonifico automatico")
            ),
            DailyTip(
                id: 10,
                title: String(localized: "Confronta Prima di Rinnovare"),
                shortTitle: String(localized: "Confronta sempre"),
                content: String(localized: "Prima che scada un'assicurazione o un contratto, confronta SEMPRE con la concorrenza. Le aziende offrono i prezzi migliori ai nuovi clienti, non a quelli fedeli."),
                category: .hack,
                actionText: String(localized: "Segna la scadenza del prossimo rinnovo")
            ),

            // SFIDE (10)
            DailyTip(
                id: 11,
                title: String(localized: "Sfida: Weekend Senza Spese"),
                shortTitle: String(localized: "Weekend a €0"),
                content: String(localized: "Prova a passare un intero weekend senza spendere nulla. Cucina con quello che hai, fai attività gratuite (passeggiata, parco, film a casa). Scoprirai che il divertimento non costa."),
                category: .challenge,
                actionText: String(localized: "Programma il tuo weekend gratis")
            ),
            DailyTip(
                id: 12,
                title: String(localized: "Sfida: 7 Giorni Senza Amazon"),
                shortTitle: String(localized: "7 giorni senza Amazon"),
                content: String(localized: "Per una settimana, non comprare nulla online. Metti gli articoli nel carrello ma non completare l'acquisto. A fine settimana, guarda quanti ne vuoi ancora davvero."),
                category: .challenge,
                actionText: String(localized: "Inizia oggi la sfida")
            ),
            DailyTip(
                id: 13,
                title: String(localized: "Sfida: Porta il Pranzo al Lavoro"),
                shortTitle: String(localized: "Pranzo da casa"),
                content: String(localized: "Per 5 giorni, porta il pranzo da casa invece di comprarlo. Un pranzo fuori costa €8-12, uno da casa €2-3. Risparmio settimanale: €30-45. Mensile: €120-180."),
                category: .challenge,
                actionText: String(localized: "Prepara il pranzo per domani")
            ),
            DailyTip(
                id: 14,
                title: String(localized: "Sfida: Niente Caffè Fuori per 3 Giorni"),
                shortTitle: String(localized: "3 giorni senza caffè fuori"),
                content: String(localized: "Per 3 giorni, fai il caffè a casa o in ufficio. Sembra poco, ma se diventa abitudine risparmi €300/anno. Bonus: il caffè fatto bene a casa è spesso più buono."),
                category: .challenge,
                actionText: String(localized: "Accetta la sfida")
            ),
            DailyTip(
                id: 15,
                title: String(localized: "Sfida: Decluttering = Guadagno"),
                shortTitle: String(localized: "Vendi quello che non usi"),
                content: String(localized: "Oggi trova 5 oggetti che non usi da 6+ mesi e mettili in vendita su Vinted o Subito. Quello che per te è inutile, per altri è un tesoro. Media guadagnata: €50-200."),
                category: .challenge,
                actionText: String(localized: "Trova 5 oggetti da vendere")
            ),
            DailyTip(
                id: 16,
                title: String(localized: "Sfida: Giornata Cash-Only"),
                shortTitle: String(localized: "Solo contanti oggi"),
                content: String(localized: "Oggi usa solo contanti. Quando vedi fisicamente i soldi uscire dal portafoglio, spendi in media il 12-18% in meno. Il dolore del pagamento diventa reale."),
                category: .challenge,
                actionText: String(localized: "Preleva il budget di oggi")
            ),
            DailyTip(
                id: 17,
                title: String(localized: "Sfida: Settimana Senza Delivery"),
                shortTitle: String(localized: "7 giorni senza delivery"),
                content: String(localized: "Per una settimana, niente Glovo, Deliveroo o JustEat. Un ordine medio costa €18-25 (cibo + consegna + mancia). Cucina a casa: risparmio €50-100 in una settimana."),
                category: .challenge,
                actionText: String(localized: "Pianifica i pasti della settimana")
            ),
            DailyTip(
                id: 18,
                title: String(localized: "Sfida: Trova 3 Abbonamenti da Tagliare"),
                shortTitle: String(localized: "Taglia 3 abbonamenti"),
                content: String(localized: "Guarda tutti i tuoi abbonamenti e trovane 3 che puoi cancellare o mettere in pausa. Non devi per forza cancellarli per sempre: anche solo 3 mesi di pausa ti fanno risparmiare."),
                category: .challenge,
                actionText: String(localized: "Rivedi i tuoi abbonamenti ora")
            ),
            DailyTip(
                id: 19,
                title: String(localized: "Sfida: Un Mese di Spese Tracciate"),
                shortTitle: String(localized: "Traccia tutto per 30 giorni"),
                content: String(localized: "Per 30 giorni, scrivi OGNI spesa che fai. Anche il caffè da €1. A fine mese avrai una mappa chiara di dove vanno i tuoi soldi. La consapevolezza è il primo passo."),
                category: .challenge,
                actionText: String(localized: "Inizia a tracciare da oggi")
            ),
            DailyTip(
                id: 20,
                title: String(localized: "Sfida: Sostituisci un Abbonamento con Free"),
                shortTitle: String(localized: "Trova l'alternativa gratuita"),
                content: String(localized: "Scegli un abbonamento e cerca un'alternativa gratuita per 2 settimane. Spotify → YouTube Music Free. Netflix → Biblioteca digitale. Palestra → Allenamento a casa."),
                category: .challenge,
                actionText: String(localized: "Scegli quale provare")
            ),

            // MINDSET (10)
            DailyTip(
                id: 21,
                title: String(localized: "I Soldi Sono Tempo"),
                shortTitle: String(localized: "Soldi = Tempo di vita"),
                content: String(localized: "Se guadagni €10/ora netti, un acquisto da €50 ti costa 5 ore di vita. Prima di comprare, chiediti: 'Vale X ore del mio tempo?' Cambia prospettiva, cambia comportamento."),
                category: .mindset,
                actionText: String(localized: "Calcola il tuo valore orario")
            ),
            DailyTip(
                id: 22,
                title: String(localized: "La Felicità Non Si Compra"),
                shortTitle: String(localized: "Felicità ≠ Acquisti"),
                content: String(localized: "Gli studi dimostrano che dopo i bisogni base, più soldi non aumentano la felicità. Le esperienze con le persone care valgono più di qualsiasi oggetto. Investi in relazioni, non in cose."),
                category: .mindset,
                actionText: String(localized: "Pianifica un'esperienza con chi ami")
            ),
            DailyTip(
                id: 23,
                title: String(localized: "Il Costo Nascosto dello Stress Finanziario"),
                shortTitle: String(localized: "Lo stress costa caro"),
                content: String(localized: "Lo stress finanziario causa problemi di salute, relazioni rovinate e decisioni sbagliate. Ogni euro risparmiato oggi è tranquillità domani. Il risparmio è self-care."),
                category: .mindset,
                actionText: String(localized: "Crea un fondo emergenza")
            ),
            DailyTip(
                id: 24,
                title: String(localized: "Smetti di Confrontarti"),
                shortTitle: String(localized: "Stop confronti social"),
                content: String(localized: "Su Instagram tutti sembrano ricchi. La realtà: l'80% vive sopra le proprie possibilità. Non confrontare il tuo dietro le quinte con il loro highlight reel. Vivi secondo i tuoi mezzi."),
                category: .mindset,
                actionText: String(localized: "Smetti di seguire chi ti fa sentire povero")
            ),
            DailyTip(
                id: 25,
                title: String(localized: "Paga Te Stesso Prima"),
                shortTitle: String(localized: "Prima paghi te stesso"),
                content: String(localized: "Appena arriva lo stipendio, prima di pagare bollette o comprare qualsiasi cosa, metti da parte il 10-20% per te. I risparmi non sono quello che avanza, sono la priorità."),
                category: .mindset,
                actionText: String(localized: "Imposta il risparmio automatico")
            ),
            DailyTip(
                id: 26,
                title: String(localized: "La Gratificazione Ritardata"),
                shortTitle: String(localized: "Saper aspettare paga"),
                content: String(localized: "Chi sa aspettare per avere qualcosa di meglio ha più successo finanziario. Ogni volta che resisti a un acquisto impulsivo, stai allenando un muscolo che ti renderà ricco."),
                category: .mindset,
                actionText: String(localized: "Rimanda un acquisto di una settimana")
            ),
            DailyTip(
                id: 27,
                title: String(localized: "Gli Oggetti Ti Possiedono"),
                shortTitle: String(localized: "Meno cose, più libertà"),
                content: String(localized: "Ogni oggetto richiede spazio, manutenzione, attenzione. Più possiedi, più sei posseduto. Il minimalismo non è povertà, è libertà. Meno cose = meno stress."),
                category: .mindset,
                actionText: String(localized: "Libera un cassetto oggi")
            ),
            DailyTip(
                id: 28,
                title: String(localized: "Il Potere del 'No'"),
                shortTitle: String(localized: "Impara a dire No"),
                content: String(localized: "Ogni 'sì' a una spesa è un 'no' ai tuoi obiettivi finanziari. Impara a dire no: alle uscite costose, agli acquisti inutili, alle pressioni sociali. Il 'no' è il tuo superpotere finanziario."),
                category: .mindset,
                actionText: String(localized: "Dì un 'no' oggi")
            ),
            DailyTip(
                id: 29,
                title: String(localized: "Definisci il Tuo 'Abbastanza'"),
                shortTitle: String(localized: "Quanto è abbastanza?"),
                content: String(localized: "La società ti dice che non è mai abbastanza. Ma tu hai definito il TUO abbastanza? Di quanto hai bisogno per essere sereno? Definiscilo, e smetti di rincorrere sempre di più."),
                category: .mindset,
                actionText: String(localized: "Scrivi il tuo numero")
            ),
            DailyTip(
                id: 30,
                title: String(localized: "I Ricchi Comprano Asset"),
                shortTitle: String(localized: "Asset vs Passività"),
                content: String(localized: "I poveri comprano cose che perdono valore (auto, vestiti, gadget). I ricchi comprano cose che generano valore (investimenti, formazione, strumenti di lavoro). Su cosa spendi i tuoi soldi?"),
                category: .mindset,
                actionText: String(localized: "Classifica le tue ultime 5 spese")
            ),

            // LIFE HACKS (10)
            DailyTip(
                id: 31,
                title: String(localized: "Le App di Cashback"),
                shortTitle: String(localized: "Cashback sugli acquisti"),
                content: String(localized: "App come Satispay, Stocard o le carte con cashback ti restituiscono l'1-5% su ogni acquisto. Su €500/mese di spese, sono €60-300/anno senza fare nulla di diverso."),
                category: .hack,
                actionText: String(localized: "Scarica un'app cashback")
            ),
            DailyTip(
                id: 32,
                title: String(localized: "Compra Usato di Qualità"),
                shortTitle: String(localized: "Usato > Nuovo economico"),
                content: String(localized: "Un iPhone ricondizionato costa il 30-40% in meno e funziona perfettamente. Vinted, Subito, BackMarket: l'usato di qualità è il segreto dei risparmiatori intelligenti."),
                category: .hack,
                actionText: String(localized: "Cerca il prossimo acquisto usato")
            ),
            DailyTip(
                id: 33,
                title: String(localized: "La Biblioteca è Gratis"),
                shortTitle: String(localized: "Biblioteca > Kindle Unlimited"),
                content: String(localized: "La tessera della biblioteca è gratuita. Libri, ebook, audiolibri, DVD, riviste: tutto gratis. Perché pagare Kindle Unlimited o Audible quando la biblioteca offre lo stesso?"),
                category: .hack,
                actionText: String(localized: "Fai la tessera della biblioteca")
            ),
            DailyTip(
                id: 34,
                title: String(localized: "Condividi gli Abbonamenti"),
                shortTitle: String(localized: "Abbonamenti condivisi"),
                content: String(localized: "Spotify Family, Netflix, Disney+: dividi con amici o parenti. Un Netflix da €18/mese diviso in 4 costa €4.50 a testa. Risparmio: €160/anno solo su questo."),
                category: .hack,
                actionText: String(localized: "Proponi una condivisione")
            ),
            DailyTip(
                id: 35,
                title: String(localized: "Fai la Spesa a Stomaco Pieno"),
                shortTitle: String(localized: "Mai fare la spesa affamato"),
                content: String(localized: "Gli studi dimostrano che fare la spesa affamati aumenta gli acquisti del 15-20%. Mangia prima di andare al supermercato. Il tuo portafoglio ti ringrazierà."),
                category: .hack,
                actionText: String(localized: "Programma la spesa dopo pranzo")
            ),
            DailyTip(
                id: 36,
                title: String(localized: "Usa i Coupon Digitali"),
                shortTitle: String(localized: "Coupon e sconti app"),
                content: String(localized: "Le app dei supermercati (Esselunga, Coop, Lidl) offrono coupon esclusivi. 10 minuti a settimana per scaricarli possono farti risparmiare €20-40/mese."),
                category: .hack,
                actionText: String(localized: "Scarica l'app del tuo supermercato")
            ),
            DailyTip(
                id: 37,
                title: String(localized: "Il Trucco del Termostato"),
                shortTitle: String(localized: "1 grado = 7% risparmio"),
                content: String(localized: "Abbassare il riscaldamento di 1°C riduce la bolletta del 7%. Da 21°C a 20°C non senti la differenza, ma il portafoglio sì. €50-100/anno risparmiati."),
                category: .hack,
                actionText: String(localized: "Abbassa il termostato di 1 grado")
            ),
            DailyTip(
                id: 38,
                title: String(localized: "Confronta i Prezzi Online"),
                shortTitle: String(localized: "Mai comprare al primo prezzo"),
                content: String(localized: "Prima di ogni acquisto online, cerca su Trovaprezzi o Google Shopping. Lo stesso prodotto può costare il 20-40% in meno su un altro sito. 2 minuti = €20+ risparmiati."),
                category: .hack,
                actionText: String(localized: "Confronta il prossimo acquisto")
            ),
            DailyTip(
                id: 39,
                title: String(localized: "Annulla e Riabbonati"),
                shortTitle: String(localized: "Il trucco della cancellazione"),
                content: String(localized: "Quando cancelli un abbonamento, spesso ti offrono sconti per restare (30-50% off). Prova a cancellare i tuoi abbonamenti: potresti ottenere prezzi migliori."),
                category: .hack,
                actionText: String(localized: "Prova a cancellare un abbonamento")
            ),
            DailyTip(
                id: 40,
                title: String(localized: "I Generici Sono Uguali"),
                shortTitle: String(localized: "Marca bianca = stessa qualità"),
                content: String(localized: "I farmaci generici, i prodotti a marchio del supermercato: spesso sono identici ai brand costosi. Stessi ingredienti, stessa fabbrica, prezzo 30-50% inferiore."),
                category: .hack,
                actionText: String(localized: "Prova un prodotto generico")
            ),

            // CONSAPEVOLEZZA (10)
            DailyTip(
                id: 41,
                title: String(localized: "Il Lifestyle Creep"),
                shortTitle: String(localized: "Attenzione al lifestyle creep"),
                content: String(localized: "Quando guadagni di più, spendi di più. È il 'lifestyle creep'. L'aumento di stipendio finisce in una macchina più bella, non in risparmi. Aumenta i risparmi, non lo stile di vita."),
                category: .awareness,
                actionText: String(localized: "Risparmia il 50% del prossimo aumento")
            ),
            DailyTip(
                id: 42,
                title: String(localized: "Le Micro-Transazioni Ti Dissanguano"),
                shortTitle: String(localized: "Piccole spese, grandi perdite"),
                content: String(localized: "€2 qui, €5 là. Le piccole spese sembrano innocue ma sommandole fanno €100-300/mese. Traccia TUTTO per un mese: rimarrai scioccato da dove vanno i tuoi soldi."),
                category: .awareness,
                actionText: String(localized: "Traccia le spese sotto €10")
            ),
            DailyTip(
                id: 43,
                title: String(localized: "Il Costo della Comodità"),
                shortTitle: String(localized: "La comodità ha un prezzo"),
                content: String(localized: "Delivery invece di cucinare. Taxi invece di mezzi. Amazon invece di negozi. La comodità costa il 20-50% in più. Chiediti: quanto vale davvero questo comfort?"),
                category: .awareness,
                actionText: String(localized: "Scegli l'opzione scomoda oggi")
            ),
            DailyTip(
                id: 44,
                title: String(localized: "Gli Abbonamenti Annuali Costano Meno"),
                shortTitle: String(localized: "Annuale > Mensile"),
                content: String(localized: "Netflix, Spotify, palestra: l'abbonamento annuale costa il 15-30% in meno del mensile. Se sei sicuro di usarlo, paga annualmente e risparmia."),
                category: .awareness,
                actionText: String(localized: "Converti un mensile in annuale")
            ),
            DailyTip(
                id: 45,
                title: String(localized: "Il Martedì è il Giorno Migliore"),
                shortTitle: String(localized: "Voli? Compra di martedì"),
                content: String(localized: "I voli costano meno se prenotati il martedì pomeriggio. I prezzi sono più alti nel weekend quando tutti cercano. Stesso volo, giorno diverso, €50-200 di differenza."),
                category: .awareness,
                actionText: String(localized: "Cerca voli il martedì")
            ),
            DailyTip(
                id: 46,
                title: String(localized: "Il Black Friday È Spesso una Truffa"),
                shortTitle: String(localized: "Black Friday: attenzione"),
                content: String(localized: "Il 60% delle offerte Black Friday non sono vere offerte: i prezzi vengono alzati prima e poi 'scontati'. Usa CamelCamelCamel per vedere la storia dei prezzi su Amazon."),
                category: .awareness,
                actionText: String(localized: "Installa un tracker di prezzi")
            ),
            DailyTip(
                id: 47,
                title: String(localized: "Stai Pagando per Non Usarlo"),
                shortTitle: String(localized: "Paghi la palestra che non usi"),
                content: String(localized: "L'80% degli iscritti in palestra non ci va regolarmente. €40/mese per 12 mesi = €480/anno per... sensi di colpa. Sii onesto: la usi davvero?"),
                category: .awareness,
                actionText: String(localized: "Conta quante volte sei andato questo mese")
            ),
            DailyTip(
                id: 48,
                title: String(localized: "I 'Saldi' Sono Marketing"),
                shortTitle: String(localized: "Saldi = trucco psicologico"),
                content: String(localized: "Vedere '-50%' attiva il cervello come una droga. Ma stai risparmiando solo se avresti comprato comunque quell'oggetto a prezzo pieno. Altrimenti stai spendendo, non risparmiando."),
                category: .awareness,
                actionText: String(localized: "Prima del saldo, chiediti: lo comprerei a prezzo pieno?")
            ),
            DailyTip(
                id: 49,
                title: String(localized: "L'Energia della Sera Costa Meno"),
                shortTitle: String(localized: "Lavatrice di notte"),
                content: String(localized: "Se hai una tariffa bioraria, fare lavatrice e lavastoviglie dopo le 19 o nei weekend costa il 20-30% in meno. Stesso risultato, meno soldi."),
                category: .awareness,
                actionText: String(localized: "Imposta la lavatrice per stasera")
            ),
            DailyTip(
                id: 50,
                title: String(localized: "Ogni Oggetto Ha un Costo Nascosto"),
                shortTitle: String(localized: "Il costo nascosto degli oggetti"),
                content: String(localized: "Comprare è solo l'inizio. Ogni oggetto richiede spazio (affitto), manutenzione (tempo), assicurazione, e prima o poi smaltimento. Il vero costo è sempre più alto del prezzo."),
                category: .awareness,
                actionText: String(localized: "Considera il costo totale del prossimo acquisto")
            )
        ]
    }
}
