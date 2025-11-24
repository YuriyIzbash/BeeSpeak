//
//  HiveListView.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import SwiftUI
import SwiftData

struct HiveListView: View {
    @Environment(\.modelContext) private var modelContext
    let apiary: Apiary
    @State private var showingAddHive = false
    @State private var showingQRScanner = false
    
    var body: some View {
        List {
            ForEach(apiary.hives) { hive in
                NavigationLink {
                    InspectionView(hive: hive)
                } label: {
                    HiveRowView(hive: hive)
                }
            }
            .onDelete(perform: deleteHives)
        }
        .navigationTitle(apiary.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingAddHive = true
                    } label: {
                        Label("Add Hive", systemImage: "plus")
                    }
                    Button {
                        showingQRScanner = true
                    } label: {
                        Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                    }
                } label: {
                    Image(systemName: "plus")
                        .accessibilityLabel("Add options")
                }
            }
        }
        .sheet(isPresented: $showingAddHive) {
            AddHiveView(apiary: apiary)
        }
        .sheet(isPresented: $showingQRScanner) {
            QRScannerView()
        }
    }
    
    private func deleteHives(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(apiary.hives[index])
            }
            try? modelContext.save()
        }
    }
}

struct HiveRowView: View {
    let hive: Hive
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(hive.name)
                    .font(.headline)
                Spacer()
                Text(hive.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if !hive.notes.isEmpty {
                Text(hive.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(hive.inspections.count) inspections", systemImage: "magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let lastInspection = hive.inspections.sorted(by: { $0.date > $1.date }).first {
                    Text(lastInspection.date, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddHiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let apiary: Apiary
    @State private var name = ""
    @State private var type = "Langstroth"
    @State private var notes = ""
    
    private let hiveTypes = ["Langstroth", "Top Bar", "Warre", "Flow Hive", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Hive Information") {
                    TextField("Name", text: $name)
                        .accessibilityLabel("Hive name")
                    Picker("Type", selection: $type) {
                        ForEach(hiveTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Hive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let hive = Hive(name: name, type: type, notes: notes, apiary: apiary)
                        modelContext.insert(hive)
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Apiary.self, Hive.self, configurations: config)
    let apiary = Apiary(name: "Test Apiary")
    let hive = Hive(name: "Hive 1", apiary: apiary)
    container.mainContext.insert(apiary)
    container.mainContext.insert(hive)
    
    return NavigationStack {
        HiveListView(apiary: apiary)
    }
    .modelContainer(container)
}

