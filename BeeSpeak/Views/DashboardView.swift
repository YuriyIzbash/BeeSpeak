//
//  DashboardView.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Apiary.name) private var apiaries: [Apiary]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        SummaryCard(
                            title: "Total Hives",
                            value: "\(totalHives)",
                            icon: "square.grid.2x2.fill",
                            color: .blue
                        )
                        
                        SummaryCard(
                            title: "Total Inspections",
                            value: "\(totalInspections)",
                            icon: "magnifyingglass",
                            color: .green
                        )
                        
                        SummaryCard(
                            title: "Varroa Alerts",
                            value: "\(varroaAlerts)",
                            icon: "exclamationmark.triangle.fill",
                            color: .orange
                        )
                        
                        SummaryCard(
                            title: "Total Harvest",
                            value: String(format: "%.1f kg", totalHarvest),
                            icon: "scissors",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Recent Inspections
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Inspections")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(recentInspections.prefix(5), id: \.id) { inspection in
                            InspectionRowView(inspection: inspection)
                        }
                    }
                    .padding(.vertical)
                    
                    // Upcoming Treatment Checks
                    if !upcomingTreatments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming Treatment Checks")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(upcomingTreatments.prefix(5), id: \.id) { treatment in
                                TreatmentRowView(treatment: treatment)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
        }
    }
    
    private var totalHives: Int {
        apiaries.reduce(0) { $0 + $1.hives.count }
    }
    
    private var totalInspections: Int {
        apiaries.flatMap { $0.hives }.reduce(0) { $0 + $1.inspections.count }
    }
    
    private var varroaAlerts: Int {
        apiaries.flatMap { $0.hives }
            .flatMap { $0.inspections }
            .filter { $0.varroaLevel == "High" || $0.varroaLevel == "Medium" }
            .count
    }
    
    private var totalHarvest: Double {
        apiaries.flatMap { $0.hives }
            .flatMap { $0.harvests }
            .reduce(0) { $0 + $1.weightKg }
    }
    
    private var recentInspections: [Inspection] {
        apiaries.flatMap { $0.hives }
            .flatMap { $0.inspections }
            .sorted { $0.date > $1.date }
    }
    
    private var upcomingTreatments: [Treatment] {
        let now = Date()
        return apiaries.flatMap { $0.hives }
            .flatMap { $0.treatments }
            .filter { treatment in
                if let nextCheck = treatment.nextCheckDate {
                    return nextCheck >= now
                }
                return false
            }
            .sorted { treatment1, treatment2 in
                let date1 = treatment1.nextCheckDate ?? Date.distantFuture
                let date2 = treatment2.nextCheckDate ?? Date.distantFuture
                return date1 < date2
            }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InspectionRowView: View {
    let inspection: Inspection
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let hive = inspection.hive {
                    Text(hive.name)
                        .font(.headline)
                }
                Text(inspection.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if inspection.varroaLevel == "High" {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct TreatmentRowView: View {
    let treatment: Treatment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let hive = treatment.hive {
                    Text(hive.name)
                        .font(.headline)
                }
                Text(treatment.product)
                    .font(.subheadline)
                if let nextCheck = treatment.nextCheckDate {
                    Text("Check: \(nextCheck, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Apiary.self, Hive.self, Inspection.self, Treatment.self, Harvest.self], inMemory: true)
}

