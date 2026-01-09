//
//  AddSubscriptionView.swift
//  SublySwift
//
//  Vista per aggiungere un nuovo abbonamento
//

import SwiftUI

struct AddSubscriptionView: View {
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager.shared

    // Servizio iniziale (passato dal picker)
    var initialService: Service?

    // Milestone tracking
    @AppStorage("shownMilestones") private var shownMilestonesData: Data = Data()
    private let milestones = [3, 5, 10]

    // Form State
    @State private var selectedService: Service?
    @State private var cost = ""
    @State private var billingCycle: BillingCycle = .monthly
    @State private var category: ServiceCategory = .other
    @State private var isShared = false
    @State private var sharedWithCount: Int = 2

    // UI State
    @State private var showingServicePicker = false
    @State private var isSaving = false
    @State private var showingSuccessAlert = false
    @State private var showingMilestonePromo = false
    @State private var currentMilestone: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                // Service Selection
                serviceSection

                // Cost & Billing
                costSection

                // Sharing
                sharingSection
            }
            .navigationTitle("Traccia Abbonamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveSubscription()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || isSaving)
                }
            }
            .sheet(isPresented: $showingServicePicker) {
                ServicePickerView(selectedService: $selectedService, category: $category, billingCycle: $billingCycle)
            }
            .alert("Abbonamento tracciato", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("L'abbonamento è ora tracciato. Ti chiederemo periodicamente se lo stai ancora utilizzando.")
            }
            .sheet(isPresented: $showingMilestonePromo) {
                MilestonePromotionView(subscriptionCount: currentMilestone) {
                    dismiss()
                }
            }
            .onAppear {
                // Se c'è un servizio iniziale, pre-selezionalo
                if let initial = initialService, selectedService == nil {
                    selectedService = initial
                    category = initial.category
                    if let typicalCost = initial.typicalCost {
                        cost = String(format: "%.2f", typicalCost)
                    }
                }
            }
            .onChange(of: selectedService) { _, newService in
                if let service = newService {
                    if let typicalCost = service.typicalCost {
                        cost = String(format: "%.2f", typicalCost)
                    }
                    category = service.category
                }
            }
        }
    }

    // MARK: - Sections

    private var serviceSection: some View {
        Section {
            Button {
                showingServicePicker = true
            } label: {
                HStack {
                    if let service = selectedService {
                        ServiceLogoView(
                            serviceName: service.name,
                            category: service.category,
                            size: 40
                        )

                        Text(service.name)
                            .foregroundColor(.primary)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.appPrimary)

                        Text("Seleziona servizio")
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

        } header: {
            Text("Servizio")
        } footer: {
            Text("Seleziona un abbonamento che già possiedi per tracciarlo.")
        }
    }

    private var costSection: some View {
        Section {
            HStack {
                Text("€")
                    .foregroundColor(.secondary)

                TextField("0,00", text: $cost)
                    .keyboardType(.decimalPad)
            }

            Picker("Frequenza", selection: $billingCycle) {
                ForEach(BillingCycle.allCases, id: \.self) { cycle in
                    Text(cycle.displayName).tag(cycle)
                }
            }
        } header: {
            Text("Costo")
        }
    }

    private var sharingSection: some View {
        Section {
            Toggle(isOn: $isShared) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Condiviso con altri")
                            .font(.subheadline)
                        if isShared {
                            Text("La tua quota: \(perPersonCost)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .tint(.green)

            if isShared {
                Stepper(value: $sharedWithCount, in: 2...10) {
                    HStack {
                        Text("Numero persone")
                        Spacer()
                        Text("\(sharedWithCount)")
                            .fontWeight(.semibold)
                            .foregroundColor(.appPrimary)
                    }
                }
            }
        } header: {
            Text("Condivisione")
        } footer: {
            if isShared {
                Text("Il costo verrà diviso tra \(sharedWithCount) persone. Potrai inviare richieste di pagamento agli amici.")
            }
        }
    }

    private var perPersonCost: String {
        guard let costValue = Double(cost.replacingOccurrences(of: ",", with: ".")) else {
            return "€0,00"
        }
        let perPerson = costValue / Double(sharedWithCount)
        return perPerson.currencyFormatted
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        selectedService != nil &&
        !cost.isEmpty &&
        Double(cost.replacingOccurrences(of: ",", with: ".")) != nil &&
        Double(cost.replacingOccurrences(of: ",", with: "."))! > 0
    }

    // MARK: - Actions

    private func saveSubscription() {
        guard let service = selectedService,
              let costValue = Double(cost.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        isSaving = true

        let subscription = Subscription(
            serviceName: service.name,
            cost: costValue,
            billingCycle: billingCycle,
            nextBillingDate: Date(),
            category: category,
            sharedWith: isShared ? sharedWithCount : nil
        )

        Task {
            await viewModel.addSubscription(subscription)
            isSaving = false

            // Controlla se abbiamo raggiunto un milestone e l'utente non è Pro
            let newCount = viewModel.subscriptions.count
            if let milestone = checkMilestone(count: newCount), !storeManager.isPro {
                currentMilestone = milestone
                markMilestoneAsShown(milestone)
                showingMilestonePromo = true
            } else {
                showingSuccessAlert = true
            }
        }
    }

    // MARK: - Milestone Helpers

    private var shownMilestones: Set<Int> {
        get {
            (try? JSONDecoder().decode(Set<Int>.self, from: shownMilestonesData)) ?? []
        }
        set {
            shownMilestonesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    private func checkMilestone(count: Int) -> Int? {
        for milestone in milestones {
            if count == milestone && !shownMilestones.contains(milestone) {
                return milestone
            }
        }
        return nil
    }

    private func markMilestoneAsShown(_ milestone: Int) {
        var shown = shownMilestones
        shown.insert(milestone)
        shownMilestonesData = (try? JSONEncoder().encode(shown)) ?? Data()
    }
}

#Preview {
    AddSubscriptionView(initialService: nil)
        .environmentObject(SubscriptionViewModel())
}
