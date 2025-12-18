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
    @StateObject private var storeService = StoreService.shared

    // Form State
    @State private var selectedService: Service?
    @State private var customName = ""
    @State private var cost = ""
    @State private var billingCycle: BillingCycle = .monthly
    @State private var nextBillingDate = Date()
    @State private var notes = ""
    @State private var category: ServiceCategory = .other
    @State private var isEssential = false

    // UI State
    @State private var showingServicePicker = false
    @State private var isSaving = false
    @State private var showingSuccessAlert = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                // Service Selection
                serviceSection

                // Cost & Billing
                costSection

                // Date
                dateSection

                // Notes
                notesSection

                // Budget Impact Preview
                if let impact = budgetImpact {
                    budgetImpactSection(impact: impact)
                }
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
                ServicePickerView(selectedService: $selectedService, category: $category)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onAppear {
                // Mostra paywall se ha raggiunto il limite
                if !storeService.canAddSubscription(currentCount: viewModel.activeSubscriptions.count) {
                    showingPaywall = true
                }
            }
            .onChange(of: storeService.isUnlocked) { _, isUnlocked in
                // Chiudi paywall se ha sbloccato
                if isUnlocked {
                    showingPaywall = false
                }
            }
            .onChange(of: showingPaywall) { _, isShowing in
                // Se chiude il paywall senza aver sbloccato, torna indietro
                if !isShowing && !storeService.canAddSubscription(currentCount: viewModel.activeSubscriptions.count) {
                    dismiss()
                }
            }
            .alert("Abbonamento tracciato", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("L'abbonamento è ora tracciato. Riceverai notifiche prima di ogni rinnovo.")
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

            if selectedService != nil {
                TextField("Nome personalizzato (opzionale)", text: $customName)
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

    private var dateSection: some View {
        Section {
            DatePicker(
                "Prossimo rinnovo",
                selection: $nextBillingDate,
                displayedComponents: .date
            )
        } header: {
            Text("Data rinnovo")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Note (opzionale)", text: $notes, axis: .vertical)
                .lineLimit(3...6)

            Toggle("Abbonamento essenziale", isOn: $isEssential)
        } header: {
            Text("Altro")
        } footer: {
            Text("Gli abbonamenti essenziali sono esclusi dai suggerimenti di risparmio.")
        }
    }

    private func budgetImpactSection(impact: BudgetImpact) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Nuovo totale mensile")
                    Spacer()
                    Text(impact.newTotal.currencyFormatted)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Budget utilizzato")
                    Spacer()
                    Text(impact.newPercentage.percentageFormatted)
                        .foregroundColor(impact.willExceedBudget ? .red : .primary)
                        .fontWeight(.semibold)
                }

                BudgetProgressView(
                    percentage: impact.newPercentage,
                    color: impact.willExceedBudget ? .budgetDanger : (impact.newPercentage >= 80 ? .budgetWarning : .budgetSafe)
                )

                if impact.willExceedBudget {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(impact.impactText)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        } header: {
            Text("Impatto sul budget")
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        selectedService != nil &&
        !cost.isEmpty &&
        Double(cost.replacingOccurrences(of: ",", with: ".")) != nil &&
        Double(cost.replacingOccurrences(of: ",", with: "."))! > 0
    }

    private var budgetImpact: BudgetImpact? {
        guard let costValue = Double(cost.replacingOccurrences(of: ",", with: ".")) else {
            return nil
        }
        return viewModel.calculateBudgetImpact(newCost: costValue, billingCycle: billingCycle)
    }

    // MARK: - Actions

    private func saveSubscription() {
        // Controllo sicurezza: verifica limite abbonamenti
        guard storeService.canAddSubscription(currentCount: viewModel.activeSubscriptions.count) else {
            showingPaywall = true
            return
        }

        guard let service = selectedService,
              let costValue = Double(cost.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        isSaving = true

        let subscription = Subscription(
            serviceName: service.name,
            customName: customName.isEmpty ? nil : customName,
            cost: costValue,
            billingCycle: billingCycle,
            nextBillingDate: nextBillingDate,
            notes: notes.isEmpty ? nil : notes,
            category: category,
            isEssential: isEssential
        )

        Task {
            await viewModel.addSubscription(subscription)
            isSaving = false
            showingSuccessAlert = true
        }
    }
}

#Preview {
    AddSubscriptionView()
        .environmentObject(SubscriptionViewModel())
}
