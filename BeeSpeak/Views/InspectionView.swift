//
//  InspectionView.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import SwiftUI
import SwiftData
import UIKit

struct InspectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let hive: Hive
    @StateObject private var viewModel: InspectionViewModel
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingPocketMode = false
    @State private var showingSaveConfirmation = false
    
    init(hive: Hive) {
        self.hive = hive
        // Create a temporary context for initialization - will be updated in onAppear
        let tempSchema = Schema([Apiary.self, Hive.self, Inspection.self, Treatment.self, Harvest.self])
        let tempConfig = ModelConfiguration(schema: tempSchema, isStoredInMemoryOnly: true)
        let tempContainer = try! ModelContainer(for: tempSchema, configurations: [tempConfig])
        _viewModel = StateObject(wrappedValue: InspectionViewModel(hiveID: hive.id, modelContext: tempContainer.mainContext))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Template Toggles
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    InspectionToggleButton(
                        title: "Queen Seen",
                        isSet: Binding(
                            get: { viewModel.queenSeen == true },
                            set: { _ in viewModel.toggleFlag(.queenSeen) }
                        )
                    )
                    
                    InspectionToggleButton(
                        title: "Eggs Present",
                        isSet: Binding(
                            get: { viewModel.eggsPresent == true },
                            set: { _ in viewModel.toggleFlag(.eggsPresent) }
                        )
                    )
                    
                    InspectionToggleButton(
                        title: "Brood Pattern Good",
                        isSet: Binding(
                            get: { viewModel.broodPatternGood == true },
                            set: { _ in viewModel.toggleFlag(.broodPatternGood) }
                        )
                    )
                    
                    InspectionToggleButton(
                        title: "Queen Cells",
                        isSet: Binding(
                            get: { viewModel.queenCells == true },
                            set: { _ in viewModel.toggleFlag(.queenCells) }
                        )
                    )
                }
                .padding(.horizontal)
                
                // Varroa Level Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Varroa Level")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        ForEach(VarroaLevel.allCases, id: \.self) { level in
                            Button {
                                viewModel.setVarroaLevel(level)
                            } label: {
                                Text(level.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(viewModel.varroaLevel == level ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(viewModel.varroaLevel == level ? Color.blue : Color.secondary.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .accessibilityLabel("Varroa level \(level.rawValue)")
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Photo Strip
                if !viewModel.photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.photos) { photo in
                                PhotoThumbnailView(photo: photo) {
                                    viewModel.removePhoto(photo)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Add Photo Buttons
                HStack(spacing: 16) {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .accessibilityLabel("Take photo")
                    
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .accessibilityLabel("Choose from library")
                }
                .padding(.horizontal)
                
                // Voice Recording Button
                Button {
                    if viewModel.isRecording {
                        viewModel.stopVoiceRecording()
                    } else {
                        Task {
                            await viewModel.startVoiceRecording()
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 24))
                        Text(viewModel.isRecording ? "Stop Recording" : "Record Voice")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .accessibilityLabel(viewModel.isRecording ? "Stop recording" : "Start voice recording")
                
                // Transcript Display
                if !viewModel.transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcript")
                            .font(.headline)
                            .padding(.horizontal)
                        Text(viewModel.transcript)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                
                // Pocket Mode Button
                Button {
                    showingPocketMode = true
                } label: {
                    Label("Pocket Inspection Mode", systemImage: "iphone.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .accessibilityLabel("Start pocket inspection mode")
                
                // Save Button
                Button {
                    do {
                        try viewModel.saveInspection()
                        showingSaveConfirmation = true
                    } catch {
                        print("Failed to save inspection: \(error)")
                    }
                } label: {
                    Text("Save Inspection")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .accessibilityLabel("Save inspection")
            }
            .padding(.vertical)
        }
        .navigationTitle("Inspect: \(hive.name)")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                viewModel.addPhoto(image)
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView { image in
                viewModel.addPhoto(image)
            }
        }
        .sheet(isPresented: $showingPocketMode) {
            PocketInspectionModeView(hive: hive)
        }
        .alert("Inspection Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") {
                dismiss()
            }
        }
        .onAppear {
            // Update viewModel with actual context
            viewModel.updateContext(modelContext)
        }
    }
}

struct InspectionToggleButton: View {
    let title: String
    @Binding var isSet: Bool
    
    var body: some View {
        Button {
            isSet.toggle()
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: isSet ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 32))
                    .foregroundColor(isSet ? .green : .gray)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSet ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .accessibilityLabel("\(title), \(isSet ? "selected" : "not selected")")
        .accessibilityAddTraits(isSet ? .isSelected : [])
    }
}

struct PhotoThumbnailView: View {
    let photo: PhotoItem
    let onDelete: () -> Void
    @State private var showingFullScreen = false
    
    var body: some View {
        Button {
            showingFullScreen = true
        } label: {
            if let image = UIImage(contentsOfFile: photo.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingFullScreen) {
            if let image = UIImage(contentsOfFile: photo.path) {
                FullScreenPhotoView(image: image, onDelete: onDelete)
            }
        }
    }
}

struct FullScreenPhotoView: View {
    let image: UIImage
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .navigationTitle("Photo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Hive.self, Inspection.self, configurations: config)
    let hive = Hive(name: "Test Hive")
    container.mainContext.insert(hive)
    
    return NavigationStack {
        InspectionView(hive: hive)
    }
    .modelContainer(container)
}

