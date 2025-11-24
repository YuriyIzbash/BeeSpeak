//
//  Apiary.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import SwiftData

@Model
final class Apiary {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double?
    var longitude: Double?
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \Hive.apiary) var hives: [Hive]
    var createdAt: Date
    var modifiedAt: Date
    
    init(id: UUID = UUID(), name: String, latitude: Double? = nil, longitude: Double? = nil, notes: String = "") {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.hives = []
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

