//
//  EditSubscriptionView.swift
//  SublySwift
//
//  Vista per modificare un abbonamento esistente
//

import SwiftUI

struct EditSubscriptionView: View {
    @EnvironmentObject var viewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss

    let subscription: Subscription

    // Form State
    @State private var customName: String
    @State private var cost: String
    @State private var billingCycle: BillingCycle
    @State private var nextBillingDate: Date
    @State private var notes: String
    @State private var category: ServiceCategory
    @State private var isEssential: Bool

    // UI State
    @State private var isSaving = false
    @State private var showingSuccessAlert = false

    init(subscription: Subscription) {
        self.subscription = subscription
        _customName = State(initialValue: subscription.customName ?? "")
        _cost = State(initialValue: String(format: "%.2f", subscription.cost))
        _billingCycle = State(initialValue: subscription.billingCycle)
        _nextBillingDate = State(initialValue: subscription.nextBillingDate)
        _notes = State(initialValue: subscription.notes ?? "")
        _category = State(initialValue: subscription.category)
        _isEssential = State(initialValue: subscription.isEssential)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Service Info (read-only)
                Section {
                    HStack {
                        ServiceLogoView(
                            serviceName: subscription.serviceName,
                            category: category,
                            size: 40
                        )

                        Text(subscription.serviceName)
                            .fontWeight(.medium)
                    }

                    TextField("Nome personalizzato (opzionale)", text: $customName)
                } header: {
                    Text("Servizio")
                }

                // Cost
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

                // Date
                Section {
                    DatePicker(
                        "Prossimo rinnovo",
                        selection: $nextBillingDate,
                        displayedComponents: .date
                    )
                } header: {
                    Text("Data rinnovo")
                }

                // Category
                Section {
                    Picker("Categoria", selection: $category) {
                        ForEach(ServiceCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }
                } header: {
                    Text("Categoria")
                }

                // Notes
                Section {
                    TextField("Note (opzionale)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)

                    Toggle("Abbonamento essenziale", isOn: $isEssential)
                } header: {
                    Text("Altro")
                }

                // Changes summary
                if hasChanges {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Modifiche non salvate", systemImage: "pencil.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.orange)

                            if billingCycle != subscription.billingCycle || cost != String(format: "%.2f", subscription.cost) {
                                Text("Le notifiche verranno riprogrammate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Modifica")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || !hasChanges || isSaving)
                }
            }
            .alert("Modifiche salvate", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !cost.isEmpty &&
        Double(cost.replacingOccurrences(of: ",", with: ".")) != nil &&
        Double(cost.replacingOccurrences(of: ",", with: "."))! > 0
    }

    private var hasChanges: Bool {
        customName != (subscription.customName ?? "") ||
        cost != String(format: "%.2f", subscription.cost) ||
        billingCycle != subscription.billingCycle ||
        !Calendar.current.isDate(nextBillingDate, inSameDayAs: subscription.nextBillingDate) ||
        notes != (subscription.notes ?? "") ||
        category != subscription.category ||
        isEssential != subscription.isEssential
    }

    // MARK: - Actions

    private func saveChanges() {
        guard let costValue = Double(cost.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        isSaving = true

        var updated = subscription
        updated.customName = customName.isEmpty ? nil : customName
        updated.cost = costValue
        updated.billingCycle = billingCycle
        updated.nextBillingDate = nextBillingDate
        updated.notes = notes.isEmpty ? nil : notes
        updated.category = category
        updated.isEssential = isEssential

        Task {
            await viewModel.updateSubscription(updated)
            isSaving = false
            showingSuccessAlert = true
        }
    }
}

#Preview {
    EditSubscriptionView(
        subscription: Subscription(
            serviceName: "Netflix",
            customName: "Netflix Famiglia",
            cost: 12.99,
            billingCycle: .monthly,
            nextBillingDate: Date(),
            notes: "Account condiviso",
            category: .streaming
        )
    )
    .environmentObject(SubscriptionViewModel())
}
