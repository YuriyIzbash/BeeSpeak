//
//  TreatmentsView.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import SwiftUI
import SwiftData

struct TreatmentsView: View {
    @Environment(\.modelContext) private var modelContext
    let hive: Hive
    @Query(sort: \Treatment.date, order: .reverse) private var treatments: [Treatment]
    @State private var showingAddTreatment = false
    
    var body: some View {
        List {
            ForEach(treatments.filter { $0.hiveID == hive.id }) { treatment in
                TreatmentRowView(treatment: treatment)
            }
            .onDelete(perform: deleteTreatments)
        }
        .navigationTitle("Treatments")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddTreatment = true
                } label: {
                    Image(systemName: "plus")
                        .accessibilityLabel("Add Treatment")
                }
            }
        }
        .sheet(isPresented: $showingAddTreatment) {
            AddTreatmentView(hive: hive)
        }
    }
    
    private func deleteTreatments(offsets: IndexSet) {
        let filtered = treatments.filter { $0.hiveID == hive.id }
        withAnimation {
            for index in offsets {
                modelContext.delete(filtered[index])
            }
            try? modelContext.save()
        }
    }
}

struct AddTreatmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let hive: Hive
    @State private var product = ""
    @State private var dosage = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var nextCheckDate: Date?
    @State private var hasNextCheck = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Treatment Information") {
                    TextField("Product", text: $product)
                        .accessibilityLabel("Treatment product")
                    TextField("Dosage", text: $dosage)
                        .accessibilityLabel("Dosage")
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Reminder") {
                    Toggle("Schedule Next Check", isOn: $hasNextCheck)
                    if hasNextCheck {
                        DatePicker("Next Check Date", selection: Binding(
                            get: { nextCheckDate ?? Date().addingTimeInterval(7 * 24 * 60 * 60) },
                            set: { nextCheckDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Treatment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTreatment()
                    }
                    .disabled(product.isEmpty)
                }
            }
        }
    }
    
    private func saveTreatment() {
        let treatment = Treatment(
            hiveID: hive.id,
            date: date,
            product: product,
            dosage: dosage,
            notes: notes,
            nextCheckDate: hasNextCheck ? nextCheckDate : nil,
            hive: hive
        )
        
        modelContext.insert(treatment)
        try? modelContext.save()
        
        // Schedule notification if needed
        if hasNextCheck, let nextCheck = nextCheckDate {
            Task {
                do {
                    let notificationID = try await NotificationService.shared.scheduleTreatmentReminder(
                        for: treatment,
                        hiveName: hive.name
                    )
                    treatment.notificationID = notificationID
                    try? modelContext.save()
                } catch {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Hive.self, Treatment.self, configurations: config)
    let hive = Hive(name: "Test Hive")
    container.mainContext.insert(hive)
    
    return NavigationStack {
        TreatmentsView(hive: hive)
    }
    .modelContainer(container)
}

