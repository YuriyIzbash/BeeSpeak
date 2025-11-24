//
//  Hive.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import SwiftData

@Model
final class Hive {
    @Attribute(.unique) var id: UUID
    var name: String
    var qrString: String
    var type: String
    var notes: String
    var apiary: Apiary?
    @Relationship(deleteRule: .cascade, inverse: \Inspection.hive) var inspections: [Inspection]
    @Relationship(deleteRule: .cascade, inverse: \Treatment.hive) var treatments: [Treatment]
    @Relationship(deleteRule: .cascade, inverse: \Harvest.hive) var harvests: [Harvest]
    var createdAt: Date
    var modifiedAt: Date
    
    init(id: UUID = UUID(), name: String, qrString: String? = nil, type: String = "Langstroth", notes: String = "", apiary: Apiary? = nil) {
        self.id = id
        self.name = name
        self.qrString = qrString ?? id.uuidString
        self.type = type
        self.notes = notes
        self.apiary = apiary
        self.inspections = []
        self.treatments = []
        self.harvests = []
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

