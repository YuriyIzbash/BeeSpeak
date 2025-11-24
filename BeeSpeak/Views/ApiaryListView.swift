//
//  ApiaryListView.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import SwiftUI
import SwiftData

struct ApiaryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Apiary.name) private var apiaries: [Apiary]
    @State private var showingAddApiary = false
    @State private var apiaryName = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(apiaries) { apiary in
                    NavigationLink {
                        HiveListView(apiary: apiary)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(apiary.name)
                                .font(.headline)
                            if !apiary.notes.isEmpty {
                                Text(apiary.notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("\(apiary.hives.count) hives")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteApiaries)
            }
            .navigationTitle("Apiaries")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddApiary = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Add Apiary")
                    }
                }
            }
            .sheet(isPresented: $showingAddApiary) {
                AddApiaryView()
            }
        }
    }
    
    private func deleteApiaries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(apiaries[index])
            }
            try? modelContext.save()
        }
    }
}

struct AddApiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Apiary Information") {
                    TextField("Name", text: $name)
                        .accessibilityLabel("Apiary name")
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Apiary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let apiary = Apiary(name: name, notes: notes)
                        modelContext.insert(apiary)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ApiaryListView()
        .modelContainer(for: [Apiary.self, Hive.self], inMemory: true)
}

