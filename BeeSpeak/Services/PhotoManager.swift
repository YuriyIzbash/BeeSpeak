//
//  PhotoManager.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import UIKit
import SwiftUI
import PhotosUI
import Combine

/// Manages photo capture and storage for inspections
@MainActor
class PhotoManager: ObservableObject {
    @Published var selectedPhotos: [PhotoItem] = []
    @Published var isPresentingCamera = false
    @Published var isPresentingPicker = false
    
    private let documentsURL: URL
    
    init() {
        documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("InspectionPhotos", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
    }
    
    /// Save image to app container and return file URI
    func saveImage(_ image: UIImage, forHiveID hiveID: UUID) throws -> String {
        let filename = "\(hiveID.uuidString)_\(UUID().uuidString).jpg"
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw PhotoError.compressionFailed
        }
        
        try imageData.write(to: fileURL)
        return fileURL.path
    }
    
    /// Load image from file URI
    func loadImage(from path: String) -> UIImage? {
        guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    /// Delete image file
    func deleteImage(at path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
    
    /// Add photo from camera
    func addPhotoFromCamera(_ image: UIImage, hiveID: UUID) {
        do {
            let path = try saveImage(image, forHiveID: hiveID)
            let photoItem = PhotoItem(id: UUID(), path: path, timestamp: Date())
            selectedPhotos.append(photoItem)
        } catch {
            print("Failed to save photo: \(error)")
        }
    }
    
    /// Remove photo
    func removePhoto(_ photo: PhotoItem) {
        deleteImage(at: photo.path)
        selectedPhotos.removeAll { $0.id == photo.id }
    }
    
    /// Clear all photos
    func clearPhotos() {
        for photo in selectedPhotos {
            deleteImage(at: photo.path)
        }
        selectedPhotos.removeAll()
    }
}

struct PhotoItem: Identifiable {
    let id: UUID
    let path: String
    let timestamp: Date
}

enum PhotoError: LocalizedError {
    case compressionFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .saveFailed:
            return "Failed to save image"
        }
    }
}

