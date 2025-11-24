//
//  PhotoPickerView.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import SwiftUI
import PhotosUI
import UIKit

struct PhotoPickerView: View {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Text("Select Photo")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding()
            }
            .navigationTitle("Select Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                if let item = newValue {
                    loadImage(from: item)
                }
            }
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        onImageSelected(image)
                        dismiss()
                    }
                }
            case .failure(let error):
                print("Failed to load image: \(error)")
            }
        }
    }
}

