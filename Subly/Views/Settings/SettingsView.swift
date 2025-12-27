//
//  SettingsView.swift
//  SublySwift
//
//  Vista impostazioni dell'app
//

import SwiftUI
import PhotosUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var budgetService = BudgetService.shared
    @AppStorage("userName") private var userName = ""
    @AppStorage("userProfileImageData") private var profileImageData: Data?

    @State private var showingBudgetSheet = false
    @State private var showingResetAlert = false
    @State private var showingProfileSheet = false
    @State private var showingOnboarding = false
    @State private var budgetLimitText = ""
    @State private var nameInput = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    // MARK: - Computed Properties

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                profileSection

                // Notifications Section
                notificationsSection

                // Budget Section
                budgetSection

                // App Info Section
                appInfoSection

                // Data Section
                dataSection
            }
            .navigationTitle("Impostazioni")
            .sheet(isPresented: $showingBudgetSheet) {
                budgetEditSheet
            }
            .sheet(isPresented: $showingProfileSheet) {
                profileEditSheet
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingPreviewView(isPresented: $showingOnboarding)
            }
            .alert("Ripristina app", isPresented: $showingResetAlert) {
                Button("Annulla", role: .cancel) { }
                Button("Ripristina", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("Tutti gli abbonamenti e le impostazioni verranno eliminati. L'app tornerà come appena installata.\n\nQuesta azione non può essere annullata.")
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            Button {
                nameInput = userName
                selectedImageData = profileImageData
                showingProfileSheet = true
            } label: {
                HStack(spacing: 14) {
                    // Avatar
                    Group {
                        if let imageData = profileImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.appPrimary, .appSecondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)

                                Text(userName.isEmpty ? "?" : String(userName.prefix(1)).uppercased())
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(userName.isEmpty ? "Aggiungi profilo" : userName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.icloud.fill")
                                .font(.caption2)
                            Text("Sincronizzato con iCloud")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            HStack {
                Label("Notifiche", systemImage: "bell.fill")

                Spacer()

                if notificationService.isAuthorized {
                    Text("Attive")
                        .foregroundColor(.green)
                } else {
                    Button("Attiva") {
                        requestNotifications()
                    }
                    .foregroundColor(.appPrimary)
                }
            }

            if notificationService.isAuthorized {
                HStack {
                    Text("Notifiche programmate")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(notificationService.pendingNotificationsCount)")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Notifiche")
        } footer: {
            Text("3 giorni prima del rinnovo ti chiederemo se stai ancora utilizzando il servizio. Se rispondi no, ti aiuteremo a disdire. Riceverai anche promemoria 1 giorno prima e il giorno stesso.")
        }
    }

    // MARK: - Budget Section

    private var budgetSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { budgetService.settings.isEnabled },
                set: { budgetService.enableBudget($0) }
            )) {
                Label("Budget mensile", systemImage: "chart.pie.fill")
            }

            if budgetService.settings.isEnabled {
                Button {
                    budgetLimitText = budgetService.settings.monthlyLimit.map { String(format: "%.2f", $0) } ?? ""
                    showingBudgetSheet = true
                } label: {
                    HStack {
                        Text("Limite mensile")
                        Spacer()
                        Text(budgetService.settings.monthlyLimit?.currencyFormatted ?? "Non impostato")
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("Soglia alert")
                    Spacer()
                    Text(budgetService.settings.notifyAtPercentage.percentageFormatted)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Budget")
        } footer: {
            if budgetService.settings.isEnabled {
                Text("Riceverai un alert quando raggiungi la soglia impostata.")
            }
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        Section {
            Button {
                showingOnboarding = true
            } label: {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(.appPrimary)
                    Text("Rivedi il tutorial")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            // Privacy Policy
            Link(destination: URL(string: "https://oxidized-wildebeest-640.notion.site/Privacy-Policy-2cbee015438880c88a6bd1115528dbd8")!) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.appPrimary)
                    Text("Privacy Policy")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            // Terms of Service
            Link(destination: URL(string: "https://oxidized-wildebeest-640.notion.site/TERMINI-E-CONDIZIONI-D-USO-Subly-2cdee015438880558071e0cbb23f3d68")!) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.appPrimary)
                    Text("Termini e Condizioni")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            // Supporto
            Link(destination: URL(string: "mailto:info@zdrilichwebstudios.it?subject=Supporto%20Subly")!) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.appPrimary)
                    Text("Contatta supporto")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            HStack {
                Text("Versione")
                Spacer()
                Text(appVersion)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Sviluppatore")
                Spacer()
                Text("Ivan Zdrilich")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Informazioni")
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showingResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Ripristina app")
                    Spacer()
                }
            }
        } header: {
            Text("Dati")
        } footer: {
            Text("Elimina tutti gli abbonamenti e le impostazioni. L'app verrà riportata allo stato iniziale come appena installata.")
        }
    }

    // MARK: - Budget Edit Sheet

    private var budgetEditSheet: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("€")
                            .foregroundColor(.secondary)

                        TextField("0,00", text: $budgetLimitText)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Limite mensile")
                }

                Section {
                    Picker("Soglia alert", selection: Binding(
                        get: { budgetService.settings.notifyAtPercentage },
                        set: { budgetService.updateNotifyPercentage($0) }
                    )) {
                        Text("50%").tag(50.0)
                        Text("60%").tag(60.0)
                        Text("70%").tag(70.0)
                        Text("80%").tag(80.0)
                        Text("90%").tag(90.0)
                    }
                } header: {
                    Text("Alert")
                } footer: {
                    Text("Riceverai una notifica quando la spesa raggiunge questa percentuale del budget.")
                }
            }
            .navigationTitle("Imposta budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        showingBudgetSheet = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveBudget()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Profile Edit Sheet

    private var profileEditSheet: some View {
        NavigationStack {
            Form {
                // Photo Section
                Section {
                    HStack {
                        Spacer()

                        VStack(spacing: 12) {
                            // Current/Selected photo
                            Group {
                                if let imageData = selectedImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.appPrimary, .appSecondary],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 100, height: 100)

                                        Text(nameInput.isEmpty ? "?" : String(nameInput.prefix(1)).uppercased())
                                            .font(.system(size: 40, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )

                            // Photo picker button
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Text(selectedImageData == nil ? "Aggiungi foto" : "Cambia foto")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.appPrimary)
                            }
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        // Compress image
                                        if let uiImage = UIImage(data: data),
                                           let compressed = uiImage.jpegData(compressionQuality: 0.5) {
                                            selectedImageData = compressed
                                        }
                                    }
                                }
                            }

                            // Remove photo button
                            if selectedImageData != nil {
                                Button {
                                    selectedImageData = nil
                                    selectedPhotoItem = nil
                                } label: {
                                    Text("Rimuovi foto")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.vertical, 8)

                        Spacer()
                    }
                }

                // Name Section
                Section {
                    TextField("Il tuo nome", text: $nameInput)
                        .font(.body)
                } header: {
                    Text("Nome")
                } footer: {
                    Text("Il tuo nome verrà usato per personalizzare i saluti.")
                }
            }
            .navigationTitle("Modifica profilo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        showingProfileSheet = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(nameInput.trimmed.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Actions

    private func requestNotifications() {
        Task {
            _ = await notificationService.requestAuthorization()
        }
    }

    private func saveBudget() {
        let value = Double(budgetLimitText.replacingOccurrences(of: ",", with: "."))
        budgetService.updateBudgetLimit(value)
        showingBudgetSheet = false
        Haptic.notification(.success)
    }

    private func saveProfile() {
        userName = nameInput.trimmed
        profileImageData = selectedImageData
        showingProfileSheet = false
        Haptic.notification(.success)
    }

    private func resetAllData() {
        Task {
            await viewModel.resetAllData()
            Haptic.notification(.success)
        }
    }
}

// MARK: - Onboarding Preview View (for reviewing tutorial)

struct OnboardingPreviewView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "leaf.fill",
            iconColor: .green,
            title: "Benvenuto in Subly",
            description: "L'app che ti aiuta a riprendere il controllo dei tuoi abbonamenti e a vivere con meno, ma meglio."
        ),
        OnboardingPage(
            icon: "creditcard.fill",
            iconColor: .blue,
            title: "Traccia i tuoi abbonamenti",
            description: "Aggiungi tutti i tuoi abbonamenti da oltre 80 servizi. Saprai sempre quanto spendi ogni mese e ogni anno."
        ),
        OnboardingPage(
            icon: "lightbulb.fill",
            iconColor: .green,
            title: "Scopri cosa potresti fare",
            description: "Ti mostreremo cosa potresti fare con i soldi che spendi: viaggi, cene, esperienze. Vale la pena continuare a pagare?"
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            iconColor: .purple,
            title: "Ripensa alle tue scelte",
            description: "Domande provocatorie e suggerimenti personalizzati per aiutarti a capire di quali abbonamenti hai davvero bisogno."
        ),
        OnboardingPage(
            icon: "hand.raised.fill",
            iconColor: .blue,
            title: "Ti aiutiamo a cancellare",
            description: "Per ogni servizio troverai il link diretto alla pagina di cancellazione. Disdire non è mai stato così facile."
        ),
        OnboardingPage(
            icon: "bell.fill",
            iconColor: .red,
            title: "Mai più rinnovi a sorpresa",
            description: "Notifiche intelligenti 3 giorni, 1 giorno e il giorno stesso del rinnovo. Decidi tu se continuare."
        ),
        OnboardingPage(
            icon: "icloud.fill",
            iconColor: .cyan,
            title: "Sempre sincronizzato",
            description: "I tuoi dati sono al sicuro su iCloud e sincronizzati su tutti i tuoi dispositivi Apple."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(for: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.appPrimary : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.vertical, 20)

            // Button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    isPresented = false
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Continua" : "Chiudi")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func pageView(for page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(page.iconColor)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SubscriptionViewModel())
}
