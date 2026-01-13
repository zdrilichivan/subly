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
    @StateObject private var regionService = RegionService.shared
    @AppStorage("userName") private var userName = ""
    @AppStorage("userProfileImageData") private var profileImageData: Data?

    @State private var showingResetAlert = false
    @State private var showingProfileSheet = false
    @State private var showingProUpgrade = false
    @State private var showingRegionPicker = false
    @State private var showingNotificationTimePicker = false
    @State private var selectedNotificationHour: Int = 17
    @ObservedObject private var storeManager = StoreManager.shared
    @State private var nameInput = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    // MARK: - Computed Properties

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var termsURL: URL {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        switch languageCode {
        case "it":
            return URL(string: "https://zdrilichivan.github.io/subly/terms.html")!
        case "es":
            return URL(string: "https://zdrilichivan.github.io/subly/terms_es.html")!
        default:
            return URL(string: "https://zdrilichivan.github.io/subly/terms_en.html")!
        }
    }

    private var privacyURL: URL {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        switch languageCode {
        case "it":
            return URL(string: "https://zdrilichivan.github.io/subly/privacy-policy.html")!
        case "es":
            return URL(string: "https://zdrilichivan.github.io/subly/privacy-policy-es.html")!
        default:
            return URL(string: "https://zdrilichivan.github.io/subly/privacy-policy-en.html")!
        }
    }

    var body: some View {
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

                    VStack(spacing: Spacing.md) {
                        // Custom Header
                        headerSection

                        // Content as cards
                        VStack(spacing: Spacing.md) {
                            // Profile Section
                            profileCard

                            // Pro Section
                            proCard

                            // Region Section
                            regionCard

                            // Notifications Section
                            notificationsCard

                            // Legal & Support Section
                            legalSupportCard

                            // App Info Section
                            appInfoCard

                            // Data Section
                            dataCard
                        }
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
            .sheet(isPresented: $showingProfileSheet) {
                profileEditSheet
            }
            .sheet(isPresented: $showingProUpgrade) {
                PaywallOnboardingView()
            }
            .alert("Ripristina app", isPresented: $showingResetAlert) {
                Button("Annulla", role: .cancel) { }
                Button("Ripristina", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("Tutti gli abbonamenti e le impostazioni verranno eliminati. L'app tornerà come appena installata.\n\nQuesta azione non può essere annullata.")
            }
            .sheet(isPresented: $showingRegionPicker) {
                RegionPickerView(selectedRegion: regionService.currentRegion) { region in
                    regionService.setRegion(region)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formattedDate)
                .font(Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)

            Text(String(localized: "Impostazioni"))
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

    // MARK: - Profile Card

    private var profileCard: some View {
        Button {
            nameInput = userName
            selectedImageData = profileImageData
            showingProfileSheet = true
            Haptic.selection()
        } label: {
            HStack(spacing: Spacing.md) {
                // Avatar
                Group {
                    if let imageData = profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
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
                                .frame(width: 56, height: 56)

                            Text(userName.isEmpty ? "?" : String(userName.prefix(1)).uppercased())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(userName.isEmpty ? String(localized: "Aggiungi profilo") : userName)
                        .font(Typography.headline)
                        .foregroundColor(.primary)

                    if storeManager.isPro {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "checkmark.icloud.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text(String(localized: "Sincronizzato con iCloud"))
                                .foregroundColor(.secondary)
                        }
                        .font(Typography.caption)
                    } else {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "iphone")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(localized: "Salvato localmente"))
                                .foregroundColor(.secondary)
                        }
                        .font(Typography.caption)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Keep original for List compatibility
    private var profileSection: some View {
        Section {
            Button {
                nameInput = userName
                selectedImageData = profileImageData
                showingProfileSheet = true
                Haptic.selection()
            } label: {
                HStack(spacing: Spacing.md) {
                    // Avatar
                    Group {
                        if let imageData = profileImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
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
                                    .frame(width: 56, height: 56)

                                Text(userName.isEmpty ? "?" : String(userName.prefix(1)).uppercased())
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(userName.isEmpty ? "Aggiungi profilo" : userName)
                            .font(Typography.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "checkmark.icloud.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("Sincronizzato con iCloud")
                                .foregroundColor(.secondary)
                        }
                        .font(Typography.caption)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.vertical, Spacing.xs)
            }
        }
    }

    // MARK: - Pro Card

    private var proCard: some View {
        VStack(spacing: 0) {
            if storeManager.isPro {
                HStack(spacing: Spacing.md) {
                    GradientIconContainer(
                        systemName: "crown.fill",
                        size: IconContainerSize.md,
                        gradientColors: [.yellow, .orange]
                    )

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(String(localized: "Subly Pro"))
                            .font(Typography.headline)

                        Text(String(localized: "Tutte le funzionalità sbloccate"))
                            .font(Typography.subheadline)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                .padding(Spacing.md)
            } else {
                Button {
                    showingProUpgrade = true
                    Haptic.impact(.light)
                } label: {
                    HStack(spacing: Spacing.md) {
                        GradientIconContainer(
                            systemName: "crown.fill",
                            size: IconContainerSize.md,
                            gradientColors: [.yellow, .orange]
                        )

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(String(localized: "Passa a Subly Pro"))
                                .font(Typography.headline)
                                .foregroundColor(.primary)

                            Text(String(localized: "Abbonamenti illimitati, coach, widget"))
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(String(localized: "Da \(storeManager.weeklyPrice)"))
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(Color.appPrimary)
                            )
                    }
                    .padding(Spacing.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Notifications Card

    private var notificationsCard: some View {
        VStack(spacing: 0) {
            // Main notification row
            HStack(spacing: Spacing.md) {
                IconContainer(
                    systemName: "bell.fill",
                    size: IconContainerSize.md,
                    color: .red,
                    backgroundOpacity: IconBackgroundOpacity.medium
                )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(String(localized: "Notifiche"))
                        .font(Typography.headline)

                    if notificationService.isAuthorized {
                        Text(String(localized: "Attive • \(notificationService.pendingNotificationsCount) programmate"))
                            .font(Typography.caption)
                            .foregroundColor(.green)
                    } else {
                        Text(String(localized: "Non attive"))
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if !notificationService.isAuthorized {
                    Button {
                        requestNotifications()
                        Haptic.impact(.light)
                    } label: {
                        Text(String(localized: "Attiva"))
                            .font(Typography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(Color.appPrimary)
                            )
                    }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(Spacing.md)

            // Notification time picker (Pro only)
            if notificationService.isAuthorized {
                Divider().padding(.leading, 56)

                Button {
                    if storeManager.isPro {
                        selectedNotificationHour = notificationService.notificationHour
                        showingNotificationTimePicker = true
                        Haptic.selection()
                    } else {
                        showingProUpgrade = true
                        Haptic.impact(.light)
                    }
                } label: {
                    HStack(spacing: Spacing.md) {
                        IconContainer(
                            systemName: "clock.fill",
                            size: IconContainerSize.sm,
                            color: .orange,
                            backgroundOpacity: IconBackgroundOpacity.medium
                        )

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(String(localized: "Orario notifiche"))
                                .font(Typography.body)
                                .foregroundColor(.primary)

                            if storeManager.isPro {
                                Text(formattedNotificationTime)
                                    .font(Typography.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text(String(localized: "Pro"))
                                        .font(Typography.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }

                        Spacer()

                        if storeManager.isPro {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(.tertiaryLabel))
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(Spacing.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
        .sheet(isPresented: $showingNotificationTimePicker) {
            notificationTimePickerSheet
        }
    }

    private var formattedNotificationTime: String {
        let hour = notificationService.notificationHour
        return String(format: "%02d:00", hour)
    }

    private var notificationTimePickerSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Text(String(localized: "Scegli l'orario in cui vuoi ricevere i promemoria sui rinnovi."))
                    .font(Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                Picker(String(localized: "Orario"), selection: $selectedNotificationHour) {
                    ForEach(8..<23, id: \.self) { hour in
                        Text(String(format: "%02d:00", hour))
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)

                Spacer()

                Button {
                    notificationService.setNotificationHour(selectedNotificationHour)
                    showingNotificationTimePicker = false
                    Haptic.notification(.success)
                    // Rischedula notifiche con nuovo orario
                    Task {
                        await viewModel.refreshNotifications()
                    }
                } label: {
                    Text(String(localized: "Conferma"))
                        .font(Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.appPrimary)
                        )
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .navigationTitle(String(localized: "Orario notifiche"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Annulla")) {
                        showingNotificationTimePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Region Card

    private var regionCard: some View {
        Button {
            if storeManager.isPro {
                showingRegionPicker = true
                Haptic.selection()
            } else {
                showingProUpgrade = true
                Haptic.impact(.light)
            }
        } label: {
            HStack(spacing: Spacing.md) {
                // Flag emoji
                Text(regionService.currentRegion.flagEmoji)
                    .font(.system(size: 32))
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color(.systemGray6))
                    )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(String(localized: "Regione e valuta"))
                        .font(Typography.headline)
                        .foregroundColor(.primary)

                    if storeManager.isPro {
                        Text("\(regionService.currentRegion.localizedName) • \(regionService.currentRegion.currency)")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(String(localized: "Pro"))
                                .font(Typography.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()

                if storeManager.isPro {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.tertiaryLabel))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Legal & Support Card

    private var legalSupportCard: some View {
        VStack(spacing: 0) {
            // Privacy Policy
            Link(destination: privacyURL) {
                SettingsCardRow(
                    icon: "hand.raised.fill",
                    iconColor: .blue,
                    title: String(localized: "Privacy Policy"),
                    trailingIcon: "arrow.up.right"
                )
            }

            Divider().padding(.leading, 56)

            // Terms of Service
            Link(destination: termsURL) {
                SettingsCardRow(
                    icon: "doc.text.fill",
                    iconColor: .purple,
                    title: String(localized: "Termini e Condizioni"),
                    trailingIcon: "arrow.up.right"
                )
            }

            Divider().padding(.leading, 56)

            // Supporto
            Link(destination: URL(string: "mailto:info@zdrilichwebstudios.it?subject=Supporto%20Subly")!) {
                SettingsCardRow(
                    icon: "envelope.fill",
                    iconColor: .green,
                    title: String(localized: "Contatta supporto"),
                    trailingIcon: "arrow.up.right"
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - App Info Card

    private var appInfoCard: some View {
        VStack(spacing: 0) {
            // Versione
            HStack(spacing: Spacing.md) {
                IconContainer(
                    systemName: "info.circle.fill",
                    size: IconContainerSize.sm,
                    color: .gray,
                    backgroundOpacity: IconBackgroundOpacity.medium
                )

                Text(String(localized: "Versione"))
                    .font(Typography.body)

                Spacer()

                Text(appVersion)
                    .font(Typography.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.md)

            Divider().padding(.leading, 56)

            // Sviluppatore
            HStack(spacing: Spacing.md) {
                IconContainer(
                    systemName: "person.fill",
                    size: IconContainerSize.sm,
                    color: .gray,
                    backgroundOpacity: IconBackgroundOpacity.medium
                )

                Text(String(localized: "Sviluppatore"))
                    .font(Typography.body)

                Spacer()

                Text("Ivan Zdrilich")
                    .font(Typography.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Data Card

    private var dataCard: some View {
        Button {
            showingResetAlert = true
            Haptic.impact(.light)
        } label: {
            HStack(spacing: Spacing.md) {
                IconContainer(
                    systemName: "arrow.counterclockwise",
                    size: IconContainerSize.sm,
                    color: .red,
                    backgroundOpacity: IconBackgroundOpacity.medium
                )

                Text(String(localized: "Ripristina app"))
                    .font(Typography.body)
                    .foregroundColor(.red)

                Spacer()
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
            gradientColors: [.green, .mint],
            title: "Benvenuto in Subly",
            description: "Riprendi il controllo dei tuoi abbonamenti. Vivi con meno, vivi meglio."
        ),
        OnboardingPage(
            icon: "plus.circle.fill",
            iconColor: .appPrimary,
            gradientColors: [.appPrimary, .appSecondary],
            title: "Aggiungi i tuoi abbonamenti",
            description: "Oltre 100 servizi disponibili. Scopri quanto spendi ogni mese e ogni anno in un colpo d'occhio."
        ),
        OnboardingPage(
            icon: "mail.and.text.magnifyingglass",
            iconColor: .blue,
            gradientColors: [.blue, .purple],
            title: "Scansione Email con AI",
            description: "Collega Gmail e lascia che l'intelligenza artificiale trovi automaticamente tutti gli abbonamenti nascosti nelle tue ricevute."
        ),
        OnboardingPage(
            icon: "sparkles",
            iconColor: .orange,
            gradientColors: [.orange, .yellow],
            title: "Scopri alternative migliori",
            description: "Ti mostreremo cosa potresti fare con quei soldi: viaggi, cene, esperienze. Ne vale davvero la pena?"
        ),
        OnboardingPage(
            icon: "hand.raised.fill",
            iconColor: .red,
            gradientColors: [.red, .pink],
            title: "Disdici in un tap",
            description: "Link diretto alla pagina di cancellazione per ogni servizio. Disdire non è mai stato così semplice."
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            iconColor: .purple,
            gradientColors: [.purple, .indigo],
            title: "Notifiche intelligenti",
            description: "Ti avvisiamo 3 giorni prima del rinnovo chiedendoti se usi ancora il servizio. Tu decidi, noi ti aiutiamo."
        ),
        OnboardingPage(
            icon: "icloud.fill",
            iconColor: .cyan,
            gradientColors: [.cyan, .blue],
            title: "Sincronizzato su iCloud",
            description: "I tuoi dati sono al sicuro e sempre sincronizzati su tutti i tuoi dispositivi Apple."
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
        VStack(spacing: 40) {
            Spacer()

            // Icon con gradient
            ZStack {
                // Cerchio esterno sfumato
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradientColors.isEmpty ? [page.iconColor.opacity(0.3), page.iconColor.opacity(0.1)] : page.gradientColors.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                // Cerchio interno
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradientColors.isEmpty ? [page.iconColor] : page.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: (page.gradientColors.first ?? page.iconColor).opacity(0.4), radius: 20, x: 0, y: 10)

                Image(systemName: page.icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var trailingIcon: String = "chevron.right"

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconContainer(
                systemName: icon,
                size: IconContainerSize.sm,
                color: iconColor,
                backgroundOpacity: IconBackgroundOpacity.medium
            )

            Text(title)
                .font(Typography.body)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: trailingIcon)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Settings Card Row Component (for ScrollView layout)

struct SettingsCardRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var trailingIcon: String = "chevron.right"

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconContainer(
                systemName: icon,
                size: IconContainerSize.sm,
                color: iconColor,
                backgroundOpacity: IconBackgroundOpacity.medium
            )

            Text(title)
                .font(Typography.body)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: trailingIcon)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(Spacing.md)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SubscriptionViewModel())
}
