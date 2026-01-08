//
//  DailyTipsView.swift
//  Subly
//
//  Vista principale del Daily Money Coach con consigli finanziari giornalieri
//

import SwiftUI

struct DailyTipsView: View {
    @StateObject private var tipsService = DailyTipsService.shared
    @ObservedObject private var storeManager = StoreManager.shared
    @State private var showingNotificationAlert = false
    @State private var animateCard = false
    @State private var showingActionDetail = false

    var body: some View {
        // Mostra la promo per utenti free, il contenuto completo per Pro
        if !storeManager.isPro {
            CoachPromoView()
        } else {
            coachContent
        }
    }

    // MARK: - Coach Content (Pro only)

    private var coachContent: some View {
        NavigationStack {
            ScrollView {
                ZStack(alignment: .top) {
                    // Gradient che scrolla con i contenuti
                    LinearGradient(
                        colors: [
                            Color(red: 0.35, green: 0.40, blue: 0.65),
                            Color(red: 0.12, green: 0.14, blue: 0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 380)
                    .frame(maxWidth: .infinity)
                    .offset(y: -220)

                    VStack(spacing: 24) {
                        // Page Header
                        pageHeaderSection

                        // Header
                        headerSection

                        // Card del consiglio del giorno
                        todaysTipCard

                        // Toggle notifiche
                        notificationSection

                        // Categoria del giorno
                        categorySection

                        // Citazione motivazionale
                        quoteSection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
            .onAppear {
                tipsService.refreshTodaysTip()
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    animateCard = true
                }
            }
        }
    }

    // MARK: - Page Header Section

    private var pageHeaderSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formattedDate)
                .font(Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)

            Text("Money Coach AI")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Spacing.sm)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: Date()).uppercased()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            Text(String(localized: "Il tuo consiglio del giorno"))
                .font(.title2)
                .fontWeight(.bold)

            Text(String(localized: "Ogni giorno un nuovo consiglio per gestire meglio i tuoi soldi"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Today's Tip Card

    private var todaysTipCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category badge
            HStack {
                Label(tipsService.todaysTip.category.localizedName, systemImage: tipsService.todaysTip.category.icon)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(categoryColor.opacity(0.15))
                    )

                Spacer()

                // Day indicator
                Text(String(localized: "Giorno \(dayOfYear)"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Title
            Text(tipsService.todaysTip.title)
                .font(.title3)
                .fontWeight(.bold)

            // Content
            Text(tipsService.todaysTip.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)

            // Action
            if let actionText = tipsService.todaysTip.actionText {
                Text("\(actionText).")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .padding(.top, 8)
                    .onTapGesture {
                        showingActionDetail = true
                    }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .scaleEffect(animateCard ? 1 : 0.95)
        .opacity(animateCard ? 1 : 0)
        .sheet(isPresented: $showingActionDetail) {
            ActionDetailSheet(tip: tipsService.todaysTip)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Promemoria giornaliero"))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(String(localized: "Ricevi un consiglio ogni mattina alle 9:00"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { tipsService.notificationsEnabled },
                    set: { newValue in
                        if newValue {
                            Task {
                                await tipsService.requestNotificationPermission()
                            }
                        } else {
                            tipsService.disableNotifications()
                        }
                    }
                ))
                .labelsHidden()
                .tint(.green)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundColor(.green)

                Text(String(localized: "Categorie di consigli"))
                    .font(.headline)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(DailyTip.TipCategory.allCases, id: \.self) { category in
                    categoryCard(category)
                }
            }
        }
    }

    private func categoryCard(_ category: DailyTip.TipCategory) -> some View {
        HStack(spacing: 10) {
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundColor(color(for: category))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color(for: category).opacity(0.12))
                )

            Text(category.localizedName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Quote Section

    private var quoteSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.title)
                .foregroundColor(.secondary.opacity(0.5))

            Text(String(localized: "Non è quanto guadagni, ma quanto risparmi."))
                .font(.body)
                .italic()
                .multilineTextAlignment(.center)

            Text(String(localized: "— Warren Buffett"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Helpers

    private var dayOfYear: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    }

    private var categoryColor: Color {
        color(for: tipsService.todaysTip.category)
    }

    private func color(for category: DailyTip.TipCategory) -> Color {
        switch category {
        case .saving: return .green
        case .budgeting: return .blue
        case .mindset: return .purple
        case .challenge: return .orange
        case .hack: return .yellow
        case .awareness: return .cyan
        }
    }
}

// MARK: - Action Detail Sheet

struct ActionDetailSheet: View {
    let tip: DailyTip
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 70, height: 70)

                            Image(systemName: tip.category.icon)
                                .font(.system(size: 30))
                                .foregroundColor(.green)
                        }

                        Text(String(localized: "Come mettere in pratica"))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Action reminder
                    if let actionText = tip.actionText {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.green)
                            Text(actionText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                    }

                    // Guide section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(String(localized: "Guida pratica"))
                            .font(.headline)

                        ForEach(actionGuideItems, id: \.title) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Text(item.emoji)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Text(item.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                        }
                    }

                    // Questions to ask
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "Domande da porti"))
                            .font(.headline)

                        ForEach(questionsToAsk, id: \.self) { question in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.subheadline)

                                Text(question)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Chiudi")) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Guide Items based on category

    private var actionGuideItems: [ActionGuideItem] {
        switch tip.category {
        case .awareness:
            return [
                ActionGuideItem(emoji: "1️⃣", title: String(localized: "Controlla i tuoi estratti conto"), description: String(localized: "Scarica l'ultimo mese e evidenzia ogni abbonamento ricorrente.")),
                ActionGuideItem(emoji: "2️⃣", title: String(localized: "Crea una lista"), description: String(localized: "Scrivi tutti gli abbonamenti attivi con il loro costo mensile.")),
                ActionGuideItem(emoji: "3️⃣", title: String(localized: "Valuta l'utilizzo"), description: String(localized: "Per ogni abbonamento, chiediti: l'ho usato nell'ultima settimana?"))
            ]
        case .saving:
            return [
                ActionGuideItem(emoji: "1️⃣", title: String(localized: "Identifica l'obiettivo"), description: String(localized: "Decidi quanto vuoi risparmiare questo mese.")),
                ActionGuideItem(emoji: "2️⃣", title: String(localized: "Automatizza"), description: String(localized: "Imposta un bonifico automatico verso un conto risparmio.")),
                ActionGuideItem(emoji: "3️⃣", title: String(localized: "Monitora"), description: String(localized: "Controlla i progressi ogni settimana."))
            ]
        case .budgeting:
            return [
                ActionGuideItem(emoji: "1️⃣", title: String(localized: "Calcola le entrate"), description: String(localized: "Somma tutti i tuoi guadagni mensili netti.")),
                ActionGuideItem(emoji: "2️⃣", title: String(localized: "Elenca le spese fisse"), description: String(localized: "Affitto, bollette, abbonamenti, assicurazioni.")),
                ActionGuideItem(emoji: "3️⃣", title: String(localized: "Definisci i limiti"), description: String(localized: "Assegna un budget per ogni categoria di spesa."))
            ]
        case .challenge:
            return [
                ActionGuideItem(emoji: "1️⃣", title: String(localized: "Accetta la sfida"), description: String(localized: "Decidi di iniziare oggi, non domani.")),
                ActionGuideItem(emoji: "2️⃣", title: String(localized: "Prepara l'ambiente"), description: String(localized: "Rimuovi le tentazioni che potrebbero farti fallire.")),
                ActionGuideItem(emoji: "3️⃣", title: String(localized: "Traccia i progressi"), description: String(localized: "Segna ogni giorno completato con successo."))
            ]
        case .hack:
            return [
                ActionGuideItem(emoji: "1️⃣", title: String(localized: "Prova subito"), description: String(localized: "Non rimandare: i migliori risultati vengono dall'azione immediata.")),
                ActionGuideItem(emoji: "2️⃣", title: String(localized: "Misura il risparmio"), description: String(localized: "Calcola quanto hai risparmiato con questo trucco.")),
                ActionGuideItem(emoji: "3️⃣", title: String(localized: "Rendi abituale"), description: String(localized: "Integra questo hack nella tua routine quotidiana."))
            ]
        case .mindset:
            return [
                ActionGuideItem(emoji: "1️⃣", title: String(localized: "Rifletti"), description: String(localized: "Prenditi 5 minuti per pensare a questo concetto.")),
                ActionGuideItem(emoji: "2️⃣", title: String(localized: "Scrivi"), description: String(localized: "Annota come questo si applica alla tua situazione.")),
                ActionGuideItem(emoji: "3️⃣", title: String(localized: "Agisci"), description: String(localized: "Identifica un'azione concreta da fare oggi."))
            ]
        }
    }

    private var questionsToAsk: [String] {
        switch tip.category {
        case .awareness:
            return [
                String(localized: "Ho usato questo servizio nell'ultimo mese?"),
                String(localized: "Potrei vivere senza per 30 giorni?"),
                String(localized: "Esiste un'alternativa gratuita?"),
                String(localized: "Il costo giustifica il valore che ricevo?")
            ]
        case .saving:
            return [
                String(localized: "Quanto posso realisticamente mettere da parte?"),
                String(localized: "Quali spese posso ridurre facilmente?"),
                String(localized: "Ho un fondo di emergenza?"),
                String(localized: "Sto risparmiando per un obiettivo specifico?")
            ]
        case .budgeting:
            return [
                String(localized: "So esattamente dove vanno i miei soldi?"),
                String(localized: "Rispetto il budget che mi sono dato?"),
                String(localized: "Quali categorie superano sempre il limite?"),
                String(localized: "Il mio budget è realistico?")
            ]
        case .challenge:
            return [
                String(localized: "Sono pronto a impegnarmi per questa sfida?"),
                String(localized: "Cosa potrebbe farmi mollare?"),
                String(localized: "Come mi sentirò quando avrò completato?"),
                String(localized: "Posso coinvolgere qualcuno per motivarmi?")
            ]
        case .hack:
            return [
                String(localized: "Questo trucco funziona per la mia situazione?"),
                String(localized: "Quanto tempo richiede implementarlo?"),
                String(localized: "Qual è il potenziale risparmio annuale?"),
                String(localized: "Ci sono controindicazioni?")
            ]
        case .mindset:
            return [
                String(localized: "Questo principio risuona con me?"),
                String(localized: "Come posso applicarlo alla mia vita?"),
                String(localized: "Quali abitudini devo cambiare?"),
                String(localized: "Chi conosco che incarna questo valore?")
            ]
        }
    }
}

struct ActionGuideItem {
    let emoji: String
    let title: String
    let description: String
}

#Preview {
    DailyTipsView()
}
