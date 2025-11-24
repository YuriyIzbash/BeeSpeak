//
//  InspectionViewModel.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import SwiftData
import SwiftUI
import UIKit
import Combine

@MainActor
class InspectionViewModel: ObservableObject {
    @Published var queenSeen: Bool?
    @Published var eggsPresent: Bool?
    @Published var broodPatternGood: Bool?
    @Published var queenCells: Bool?
    @Published var varroaLevel: VarroaLevel = .none
    @Published var transcript: String = ""
    @Published var tags: [String] = []
    @Published var isPocketMode: Bool = false
    @Published var parsedCommands: [String] = []
    
    private let hiveID: UUID
    private var modelContext: ModelContext
    private let speechService = SpeechRecognitionService()
    private let photoManager = PhotoManager()
    
    var photos: [PhotoItem] {
        photoManager.selectedPhotos
    }
    
    init(hiveID: UUID, modelContext: ModelContext) {
        self.hiveID = hiveID
        self.modelContext = modelContext
    }
    
    /// Update the model context (called when view appears)
    func updateContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// Toggle a boolean flag
    func toggleFlag(_ flag: InspectionFlag) {
        switch flag {
        case .queenSeen:
            queenSeen = queenSeen == true ? nil : true
        case .eggsPresent:
            eggsPresent = eggsPresent == true ? nil : true
        case .broodPatternGood:
            broodPatternGood = broodPatternGood == true ? nil : true
        case .queenCells:
            queenCells = queenCells == true ? nil : true
        }
    }
    
    /// Set varroa level
    func setVarroaLevel(_ level: VarroaLevel) {
        varroaLevel = level
    }
    
    /// Start voice recording
    func startVoiceRecording() async {
        do {
            try await speechService.startRecording()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    /// Stop voice recording and process transcript
    func stopVoiceRecording() {
        speechService.stopRecording()
        transcript = speechService.transcript
        
        // Extract flags from transcript
        let flags = speechService.extractFlags(from: transcript)
        applyFlags(flags)
        
        // Track parsed commands
        if let command = speechService.lastCommand {
            parsedCommands.append(command)
        }
    }
    
    /// Apply extracted flags
    private func applyFlags(_ flags: InspectionFlags) {
        if let queenSeen = flags.queenSeen {
            self.queenSeen = queenSeen
        }
        if let eggsPresent = flags.eggsPresent {
            self.eggsPresent = eggsPresent
        }
        if let broodPatternGood = flags.broodPatternGood {
            self.broodPatternGood = broodPatternGood
        }
        if let queenCells = flags.queenCells {
            self.queenCells = queenCells
        }
        if flags.varroaLevel != .none {
            self.varroaLevel = flags.varroaLevel
        }
    }
    
    /// Process voice command in Pocket Mode
    func processVoiceCommand(_ command: String) {
        parsedCommands.append(command)
        
        switch command {
        case "queen_seen":
            queenSeen = true
        case "queen_not_seen":
            queenSeen = false
        case "eggs_present":
            eggsPresent = true
        case "eggs_not_present":
            eggsPresent = false
        case "brood_good":
            broodPatternGood = true
        case "brood_bad":
            broodPatternGood = false
        case "queen_cells_present":
            queenCells = true
        case "queen_cells_absent":
            queenCells = false
        case "varroa_low":
            varroaLevel = .low
        case "varroa_medium":
            varroaLevel = .medium
        case "varroa_high":
            varroaLevel = .high
        default:
            break
        }
    }
    
    /// Add photo
    func addPhoto(_ image: UIImage) {
        photoManager.addPhotoFromCamera(image, hiveID: hiveID)
    }
    
    /// Remove photo
    func removePhoto(_ photo: PhotoItem) {
        photoManager.removePhoto(photo)
    }
    
    /// Save inspection
    func saveInspection() throws {
        let descriptor = FetchDescriptor<Hive>(predicate: #Predicate { $0.id == hiveID })
        guard let hive = try modelContext.fetch(descriptor).first else {
            throw InspectionError.hiveNotFound
        }
        
        let inspection = Inspection(
            hiveID: hiveID,
            date: Date(),
            queenSeen: queenSeen,
            eggsPresent: eggsPresent,
            broodPatternGood: broodPatternGood,
            queenCells: queenCells,
            varroaLevel: varroaLevel,
            photos: photos.map { $0.path },
            transcript: transcript,
            tags: tags,
            hive: hive
        )
        
        modelContext.insert(inspection)
        try modelContext.save()
        
        // Clear form
        reset()
    }
    
    /// Reset form
    func reset() {
        queenSeen = nil
        eggsPresent = nil
        broodPatternGood = nil
        queenCells = nil
        varroaLevel = .none
        transcript = ""
        tags = []
        parsedCommands = []
        photoManager.clearPhotos()
    }
    
    var isRecording: Bool {
        speechService.isRecording
    }
}

enum InspectionFlag {
    case queenSeen
    case eggsPresent
    case broodPatternGood
    case queenCells
}

enum InspectionError: LocalizedError {
    case hiveNotFound
    
    var errorDescription: String? {
        switch self {
        case .hiveNotFound:
            return "Hive not found"
        }
    }
}

