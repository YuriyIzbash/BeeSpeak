//
//  BeeSpeakApp.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import SwiftUI
import SwiftData

@main
struct BeeSpeakApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Apiary.self,
            Hive.self,
            Inspection.self,
            Treatment.self,
            Harvest.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
