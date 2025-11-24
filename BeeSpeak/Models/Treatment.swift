//
//  Treatment.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import SwiftData

@Model
final class Treatment {
    @Attribute(.unique) var id: UUID
    var hiveID: UUID
    var date: Date
    var product: String
    var dosage: String
    var notes: String
    var nextCheckDate: Date?
    var notificationID: String?
    var hive: Hive?
    var createdAt: Date
    var modifiedAt: Date
    
    init(id: UUID = UUID(), hiveID: UUID, date: Date = Date(), product: String, dosage: String, notes: String = "", nextCheckDate: Date? = nil, notificationID: String? = nil, hive: Hive? = nil) {
        self.id = id
        self.hiveID = hiveID
        self.date = date
        self.product = product
        self.dosage = dosage
        self.notes = notes
        self.nextCheckDate = nextCheckDate
        self.notificationID = notificationID
        self.hive = hive
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

