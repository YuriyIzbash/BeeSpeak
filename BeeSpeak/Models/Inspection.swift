//
//  Inspection.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import SwiftData

enum VarroaLevel: String, Codable, CaseIterable {
    case none = "None"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

@Model
final class Inspection {
    @Attribute(.unique) var id: UUID
    var hiveID: UUID
    var date: Date
    var queenSeen: Bool?
    var eggsPresent: Bool?
    var broodPatternGood: Bool?
    var queenCells: Bool?
    var varroaLevel: String
    var photos: [String] // File URIs
    var transcript: String
    var tags: [String]
    var hive: Hive?
    var createdAt: Date
    var modifiedAt: Date
    
    init(id: UUID = UUID(), hiveID: UUID, date: Date = Date(), queenSeen: Bool? = nil, eggsPresent: Bool? = nil, broodPatternGood: Bool? = nil, queenCells: Bool? = nil, varroaLevel: VarroaLevel = .none, photos: [String] = [], transcript: String = "", tags: [String] = [], hive: Hive? = nil) {
        self.id = id
        self.hiveID = hiveID
        self.date = date
        self.queenSeen = queenSeen
        self.eggsPresent = eggsPresent
        self.broodPatternGood = broodPatternGood
        self.queenCells = queenCells
        self.varroaLevel = varroaLevel.rawValue
        self.photos = photos
        self.transcript = transcript
        self.tags = tags
        self.hive = hive
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

