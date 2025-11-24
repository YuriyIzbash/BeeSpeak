//
//  ExportService.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import SwiftData
import PDFKit
import UIKit

/// Service for exporting data to CSV, JSON, and PDF
@MainActor
class ExportService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Export all data to JSON
    func exportToJSON() throws -> Data {
        let descriptor = FetchDescriptor<Apiary>(sortBy: [SortDescriptor(\.name)])
        let apiaries = try modelContext.fetch(descriptor)
        
        var exportData: [String: Any] = [:]
        exportData["exportDate"] = ISO8601DateFormatter().string(from: Date())
        exportData["apiaries"] = apiaries.map { apiary in
            [
                "id": apiary.id.uuidString,
                "name": apiary.name,
                "latitude": apiary.latitude as Any,
                "longitude": apiary.longitude as Any,
                "notes": apiary.notes,
                "hives": apiary.hives.map { hive in
                    [
                        "id": hive.id.uuidString,
                        "name": hive.name,
                        "qrString": hive.qrString,
                        "type": hive.type,
                        "notes": hive.notes,
                        "inspections": hive.inspections.map { inspection in
                            [
                                "id": inspection.id.uuidString,
                                "date": ISO8601DateFormatter().string(from: inspection.date),
                                "queenSeen": inspection.queenSeen as Any,
                                "eggsPresent": inspection.eggsPresent as Any,
                                "broodPatternGood": inspection.broodPatternGood as Any,
                                "queenCells": inspection.queenCells as Any,
                                "varroaLevel": inspection.varroaLevel,
                                "photos": inspection.photos,
                                "transcript": inspection.transcript,
                                "tags": inspection.tags
                            ]
                        },
                        "treatments": hive.treatments.map { treatment in
                            [
                                "id": treatment.id.uuidString,
                                "date": ISO8601DateFormatter().string(from: treatment.date),
                                "product": treatment.product,
                                "dosage": treatment.dosage,
                                "notes": treatment.notes,
                                "nextCheckDate": treatment.nextCheckDate.map { ISO8601DateFormatter().string(from: $0) } as Any
                            ]
                        },
                        "harvests": hive.harvests.map { harvest in
                            [
                                "id": harvest.id.uuidString,
                                "date": ISO8601DateFormatter().string(from: harvest.date),
                                "weightKg": harvest.weightKg,
                                "notes": harvest.notes
                            ]
                        }
                    ]
                }
            ]
        }
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    /// Export all data to CSV
    func exportToCSV() throws -> String {
        let descriptor = FetchDescriptor<Apiary>(sortBy: [SortDescriptor(\.name)])
        let apiaries = try modelContext.fetch(descriptor)
        
        var csv = "Export Date,\(ISO8601DateFormatter().string(from: Date()))\n\n"
        
        // Inspections CSV
        csv += "=== INSPECTIONS ===\n"
        csv += "Hive ID,Hive Name,Date,Queen Seen,Eggs Present,Brood Pattern Good,Queen Cells,Varroa Level,Transcript,Tags\n"
        
        for apiary in apiaries {
            for hive in apiary.hives {
                for inspection in hive.inspections {
                    csv += "\(hive.id.uuidString),\"\(hive.name)\",\(ISO8601DateFormatter().string(from: inspection.date)),"
                    csv += "\(inspection.queenSeen?.description ?? ""),"
                    csv += "\(inspection.eggsPresent?.description ?? ""),"
                    csv += "\(inspection.broodPatternGood?.description ?? ""),"
                    csv += "\(inspection.queenCells?.description ?? ""),"
                    csv += "\(inspection.varroaLevel),"
                    csv += "\"\(inspection.transcript.replacingOccurrences(of: "\"", with: "\"\""))\","
                    csv += "\"\(inspection.tags.joined(separator: "; "))\"\n"
                }
            }
        }
        
        csv += "\n=== TREATMENTS ===\n"
        csv += "Hive ID,Hive Name,Date,Product,Dosage,Notes,Next Check Date\n"
        
        for apiary in apiaries {
            for hive in apiary.hives {
                for treatment in hive.treatments {
                    csv += "\(hive.id.uuidString),\"\(hive.name)\",\(ISO8601DateFormatter().string(from: treatment.date)),"
                    csv += "\"\(treatment.product)\",\"\(treatment.dosage)\","
                    csv += "\"\(treatment.notes.replacingOccurrences(of: "\"", with: "\"\""))\","
                    csv += "\(treatment.nextCheckDate.map { ISO8601DateFormatter().string(from: $0) } ?? "")\n"
                }
            }
        }
        
        csv += "\n=== HARVESTS ===\n"
        csv += "Hive ID,Hive Name,Date,Weight (kg),Notes\n"
        
        for apiary in apiaries {
            for hive in apiary.hives {
                for harvest in hive.harvests {
                    csv += "\(hive.id.uuidString),\"\(hive.name)\",\(ISO8601DateFormatter().string(from: harvest.date)),"
                    csv += "\(harvest.weightKg),"
                    csv += "\"\(harvest.notes.replacingOccurrences(of: "\"", with: "\"\""))\"\n"
                }
            }
        }
        
        return csv
    }
    
    /// Generate PDF summary for a specific hive
    func generatePDFSummary(for hive: Hive) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "BeeSpeak",
            kCGPDFContextAuthor: "BeeSpeak App",
            kCGPDFContextTitle: "Hive Inspection Summary - \(hive.name)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 72
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let title = "Hive Inspection Summary"
            title.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Hive Info
            let hiveInfo = "Hive: \(hive.name)\nType: \(hive.type)\nQR Code: \(hive.qrString)"
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.darkGray
            ]
            hiveInfo.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: infoAttributes)
            yPosition += 60
            
            // Recent Inspections
            let sortedInspections = hive.inspections.sorted { $0.date > $1.date }
            let recentInspections = Array(sortedInspections.prefix(10))
            
            let sectionTitle = "Recent Inspections"
            sectionTitle.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: titleAttributes)
            yPosition += 30
            
            for inspection in recentInspections {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                
                var inspectionText = "Date: \(dateFormatter.string(from: inspection.date))\n"
                if let queenSeen = inspection.queenSeen {
                    inspectionText += "Queen Seen: \(queenSeen ? "Yes" : "No")\n"
                }
                if let eggsPresent = inspection.eggsPresent {
                    inspectionText += "Eggs Present: \(eggsPresent ? "Yes" : "No")\n"
                }
                if let broodPatternGood = inspection.broodPatternGood {
                    inspectionText += "Brood Pattern: \(broodPatternGood ? "Good" : "Poor")\n"
                }
                if let queenCells = inspection.queenCells {
                    inspectionText += "Queen Cells: \(queenCells ? "Present" : "Absent")\n"
                }
                inspectionText += "Varroa Level: \(inspection.varroaLevel)\n"
                if !inspection.transcript.isEmpty {
                    inspectionText += "Notes: \(inspection.transcript)\n"
                }
                inspectionText += "\n"
                
                let textRect = CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 200)
                inspectionText.draw(in: textRect, withAttributes: infoAttributes)
                yPosition += CGFloat(inspectionText.components(separatedBy: "\n").count * 20)
                
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = 72
                }
            }
        }
        
        return data
    }
}

