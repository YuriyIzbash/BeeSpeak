//
//  HomeView.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ApiaryListView()
                .tabItem {
                    Label("Apiaries", systemImage: "house.fill")
                }
                .tag(0)
            
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Apiary.self, Hive.self, Inspection.self, Treatment.self, Harvest.self], inMemory: true)
}

