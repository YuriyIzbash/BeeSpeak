//
//  ApiaryListViewModel.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class ApiaryListViewModel: ObservableObject {
    @Published var apiaries: [Apiary] = []
    @Published var showingAddApiary = false
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadApiaries()
    }
    
    func loadApiaries() {
        let descriptor = FetchDescriptor<Apiary>(sortBy: [SortDescriptor(\.name)])
        apiaries = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func addApiary(name: String, latitude: Double? = nil, longitude: Double? = nil, notes: String = "") {
        let apiary = Apiary(name: name, latitude: latitude, longitude: longitude, notes: notes)
        modelContext.insert(apiary)
        try? modelContext.save()
        loadApiaries()
    }
    
    func deleteApiary(_ apiary: Apiary) {
        modelContext.delete(apiary)
        try? modelContext.save()
        loadApiaries()
    }
}

