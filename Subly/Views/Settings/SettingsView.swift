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
    @AppStorage("userName") private var userName = ""
    @AppStorage("userProfileImageData") private var profileImageData: Data?

    @State private var showingResetAlert = false
    @State private var showingProfileSheet = false
    @State private var showingOnboarding = false
    @State private var showingProUpgrade = false
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

                            // Notifications Section
                            notificationsCard

                            // App Info Section
                            appInfoCard

                            // Data Section
                            dataCard

                            #if DEBUG
                            // Debug Section
                            debugCard
                            #endif
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
                ProUpgradeView()
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

                        Text(String(localized: "Da \(storeManager.monthlyPrice)"))
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
            // Tutorial
            Button {
                showingOnboarding = true
                Haptic.selection()
            } label: {
                SettingsCardRow(
                    icon: "book.fill",
                    iconColor: .appPrimary,
                    title: String(localized: "Rivedi il tutorial"),
                    trailingIcon: "chevron.right"
                )
            }
            .buttonStyle(PlainButtonStyle())

            Divider().padding(.leading, 56)

            // Privacy Policy
            Link(destination: URL(string: "https://zdrilichivan.github.io/subly/privacy-policy.html")!) {
                SettingsCardRow(
                    icon: "hand.raised.fill",
                    iconColor: .blue,
                    title: String(localized: "Privacy Policy"),
                    trailingIcon: "arrow.up.right"
                )
            }

            Divider().padding(.leading, 56)

            // Terms of Service
            Link(destination: URL(string: "https://zdrilichivan.github.io/subly/terms.html")!) {
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

            Divider().padding(.leading, 56)

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

    // MARK: - Debug Card

    #if DEBUG
    private var debugCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "ladybug.fill")
                    .foregroundColor(.orange)
                Text("Debug")
                    .font(Typography.headline)
                    .foregroundColor(.orange)
            }
            .padding(.bottom, Spacing.xxs)

            Toggle(isOn: $storeManager.debugProEnabled) {
                HStack(spacing: Spacing.sm) {
                    IconContainer(
                        systemName: "crown.fill",
                        size: IconContainerSize.sm,
                        color: .yellow,
                        backgroundOpacity: IconBackgroundOpacity.medium
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Abilita Pro")
                            .font(Typography.body)
                        Text("Solo per test, non effettua acquisti")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(.orange)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    #endif

    // MARK: - Pro Section

    private var proSection: some View {
        Section {
            if storeManager.isPro {
                // Utente Pro
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
                .padding(.vertical, Spacing.xxs)
            } else {
                // Utente Free - Card promozionale
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

                        Text(String(localized: "Da \(storeManager.monthlyPrice)"))
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
                    .padding(.vertical, Spacing.xxs)
                }
            }
        } header: {
            Text(String(localized: "Subly Pro"))
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
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
            .padding(.vertical, Spacing.xxs)
        } header: {
            Text(String(localized: "Notifiche"))
        } footer: {
            Text(String(localized: "3 giorni prima del rinnovo ti chiederemo se stai ancora utilizzando il servizio. Se rispondi no, ti aiuteremo a disdire. Riceverai anche promemoria 1 giorno prima e il giorno stesso."))
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        Section {
            // Tutorial
            Button {
                showingOnboarding = true
                Haptic.selection()
            } label: {
                SettingsRow(
                    icon: "book.fill",
                    iconColor: .appPrimary,
                    title: String(localized: "Rivedi il tutorial"),
                    trailingIcon: "chevron.right"
                )
            }

            // Privacy Policy
            Link(destination: URL(string: "https://zdrilichivan.github.io/subly/privacy-policy.html")!) {
                SettingsRow(
                    icon: "hand.raised.fill",
                    iconColor: .blue,
                    title: String(localized: "Privacy Policy"),
                    trailingIcon: "arrow.up.right"
                )
            }

            // Terms of Service
            Link(destination: URL(string: "https://zdrilichivan.github.io/subly/terms.html")!) {
                SettingsRow(
                    icon: "doc.text.fill",
                    iconColor: .purple,
                    title: String(localized: "Termini e Condizioni"),
                    trailingIcon: "arrow.up.right"
                )
            }

            // Supporto
            Link(destination: URL(string: "mailto:info@zdrilichwebstudios.it?subject=Supporto%20Subly")!) {
                SettingsRow(
                    icon: "envelope.fill",
                    iconColor: .green,
                    title: String(localized: "Contatta supporto"),
                    trailingIcon: "arrow.up.right"
                )
            }

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
            .padding(.vertical, Spacing.xxs)

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
            .padding(.vertical, Spacing.xxs)
        } header: {
            Text(String(localized: "Informazioni"))
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section {
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
                .padding(.vertical, Spacing.xxs)
            }
        } header: {
            Text(String(localized: "Dati"))
        } footer: {
            Text(String(localized: "Elimina tutti gli abbonamenti e le impostazioni. L'app verrà riportata allo stato iniziale come appena installata."))
        }
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
