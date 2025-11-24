//
//  SettingsView.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import SwiftUI
import SwiftData
import AVFoundation
import UserNotifications
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingExportOptions = false
    @State private var showingDisclaimer = false
    @State private var exportService: ExportService?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Data") {
                    Button {
                        showingExportOptions = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("Permissions") {
                    PermissionRow(
                        title: "Microphone",
                        description: "Required for voice recording",
                        status: checkMicrophonePermission()
                    )
                    
                    PermissionRow(
                        title: "Camera",
                        description: "Required for photo capture and QR scanning",
                        status: checkCameraPermission()
                    )
                    
                    PermissionRow(
                        title: "Photo Library",
                        description: "Required to select photos",
                        status: checkPhotoLibraryPermission()
                    )
                    
                    PermissionRow(
                        title: "Notifications",
                        description: "Required for treatment reminders",
                        status: checkNotificationPermission()
                    )
                }
                
                Section("About") {
                    Button {
                        showingDisclaimer = true
                    } label: {
                        Label("Disclaimer", systemImage: "info.circle")
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView()
            }
            .sheet(isPresented: $showingDisclaimer) {
                DisclaimerView()
            }
            .onAppear {
                exportService = ExportService(modelContext: modelContext)
            }
        }
    }
    
    private func checkMicrophonePermission() -> PermissionStatus {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .undetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkCameraPermission() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .denied
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkPhotoLibraryPermission() -> PermissionStatus {
        // Photo library permission is handled by PHPicker
        return .granted
    }
    
    private func checkNotificationPermission() -> PermissionStatus {
        // This would need async check in real implementation
        return .notDetermined
    }
}

enum PermissionStatus {
    case granted
    case denied
    case notDetermined
    
    var displayText: String {
        switch self {
        case .granted:
            return "Granted"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        }
    }
    
    var color: Color {
        switch self {
        case .granted:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        }
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let status: PermissionStatus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(status.displayText)
                .font(.caption)
                .foregroundColor(status.color)
        }
    }
}

struct ExportOptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var exportService: ExportService?
    
    var body: some View {
        NavigationStack {
            List {
                Button {
                    exportJSON()
                } label: {
                    Label("Export as JSON", systemImage: "doc.text")
                }
                
                Button {
                    exportCSV()
                } label: {
                    Label("Export as CSV", systemImage: "tablecells")
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                exportService = ExportService(modelContext: modelContext)
            }
        }
    }
    
    private func exportJSON() {
        guard let exportService = exportService else { return }
        do {
            let data = try exportService.exportToJSON()
            shareData(data, filename: "beespeak_export.json", mimeType: "application/json")
        } catch {
            print("Export failed: \(error)")
        }
    }
    
    private func exportCSV() {
        guard let exportService = exportService else { return }
        do {
            let csv = try exportService.exportToCSV()
            if let data = csv.data(using: .utf8) {
                shareData(data, filename: "beespeak_export.csv", mimeType: "text/csv")
            }
        } catch {
            print("Export failed: \(error)")
        }
    }
    
    private func shareData(_ data: Data, filename: String, mimeType: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)
        
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

struct DisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Disclaimer")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Record-keeping only — not medical or treatment advice.")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("""
                    This application is designed for beekeepers to record and track hive inspections, treatments, and harvests. The information stored in this app is for record-keeping purposes only.
                    
                    This app does not provide medical advice, treatment recommendations, or professional beekeeping guidance. Always consult with a qualified beekeeping professional or veterinarian for treatment decisions and hive management advice.
                    
                    The developers of this application are not responsible for any decisions made based on the data recorded in this app.
                    """)
                    .font(.body)
                }
                .padding()
            }
            .navigationTitle("Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Apiary.self], inMemory: true)
}

