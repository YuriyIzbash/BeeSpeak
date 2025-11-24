//
//  Harvest.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import SwiftData

@Model
final class Harvest {
    @Attribute(.unique) var id: UUID
    var hiveID: UUID
    var date: Date
    var weightKg: Double
    var notes: String
    var hive: Hive?
    var createdAt: Date
    var modifiedAt: Date
    
    init(id: UUID = UUID(), hiveID: UUID, date: Date = Date(), weightKg: Double, notes: String = "", hive: Hive? = nil) {
        self.id = id
        self.hiveID = hiveID
        self.date = date
        self.weightKg = weightKg
        self.notes = notes
        self.hive = hive
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

