//
//  PocketInspectionModeView.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import SwiftUI
import SwiftData

struct PocketInspectionModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let hive: Hive
    @StateObject private var viewModel: InspectionViewModel
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var isListening = false
    @State private var lastCommand: String?
    
    init(hive: Hive) {
        self.hive = hive
        // Create a temporary context for initialization - will be updated in onAppear
        let tempSchema = Schema([Apiary.self, Hive.self, Inspection.self, Treatment.self, Harvest.self])
        let tempConfig = ModelConfiguration(schema: tempSchema, isStoredInMemoryOnly: true)
        let tempContainer = try! ModelContainer(for: tempSchema, configurations: [tempConfig])
        _viewModel = StateObject(wrappedValue: InspectionViewModel(hiveID: hive.id, modelContext: tempContainer.mainContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Listening Indicator
                VStack(spacing: 16) {
                    if isListening {
                        Image(systemName: "waveform")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .symbolEffect(.pulse)
                    } else {
                        Image(systemName: "mic.slash.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                    
                    Text(isListening ? "Listening..." : "Tap to Start")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Last Command Display
                if let command = lastCommand {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Command:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(command.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                // Parsed Flags Summary
                if !viewModel.parsedCommands.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Parsed Flags")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                if viewModel.queenSeen != nil {
                                    FlagRow(label: "Queen Seen", value: viewModel.queenSeen == true ? "Yes" : "No")
                                }
                                if viewModel.eggsPresent != nil {
                                    FlagRow(label: "Eggs Present", value: viewModel.eggsPresent == true ? "Yes" : "No")
                                }
                                if viewModel.broodPatternGood != nil {
                                    FlagRow(label: "Brood Pattern", value: viewModel.broodPatternGood == true ? "Good" : "Poor")
                                }
                                if viewModel.queenCells != nil {
                                    FlagRow(label: "Queen Cells", value: viewModel.queenCells == true ? "Present" : "Absent")
                                }
                                if viewModel.varroaLevel != .none {
                                    FlagRow(label: "Varroa Level", value: viewModel.varroaLevel.rawValue)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
                
                // Control Buttons
                VStack(spacing: 16) {
                    Button {
                        if isListening {
                            stopListening()
                        } else {
                            startListening()
                        }
                    } label: {
                        HStack {
                            Image(systemName: isListening ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 24))
                            Text(isListening ? "Stop Listening" : "Start Listening")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isListening ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .accessibilityLabel(isListening ? "Stop listening" : "Start listening")
                    
                    HStack(spacing: 16) {
                        Button {
                            saveAndDismiss()
                        } label: {
                            Text("Save & Finish")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .accessibilityLabel("Save and finish inspection")
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                        .accessibilityLabel("Cancel")
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .navigationTitle("Pocket Mode")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Update viewModel with actual context
            viewModel.updateContext(modelContext)
            
            // Request authorization
            Task {
                let authorized = await speechService.requestAuthorization()
                if !authorized {
                    dismiss()
                }
            }
        }
    }
    
    private func startListening() {
        isListening = true
        Task {
            do {
                try await speechService.startRecording()
            } catch {
                print("Failed to start recording: \(error)")
                isListening = false
            }
        }
    }
    
    private func stopListening() {
        speechService.stopRecording()
        isListening = false
        
        // Process transcript and extract commands
        let transcript = speechService.transcript
        viewModel.transcript = transcript
        
        // Extract flags
        let flags = speechService.extractFlags(from: transcript)
        if flags.queenSeen != nil { viewModel.queenSeen = flags.queenSeen }
        if flags.eggsPresent != nil { viewModel.eggsPresent = flags.eggsPresent }
        if flags.broodPatternGood != nil { viewModel.broodPatternGood = flags.broodPatternGood }
        if flags.queenCells != nil { viewModel.queenCells = flags.queenCells }
        if flags.varroaLevel != .none { viewModel.varroaLevel = flags.varroaLevel }
        
        // Check for command
        if let command = speechService.parseCommand(from: transcript) {
            lastCommand = command
            viewModel.processVoiceCommand(command)
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func saveAndDismiss() {
        do {
            try viewModel.saveInspection()
            dismiss()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}

struct FlagRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Hive.self, configurations: config)
    let hive = Hive(name: "Test Hive")
    container.mainContext.insert(hive)
    
    return PocketInspectionModeView(hive: hive)
        .modelContainer(container)
}

