//
//  QRScannerView.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import SwiftUI
import AVFoundation
import SwiftData

struct QRScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanner = QRScannerService()
    @State private var showingPermissionAlert = false
    @State private var scannedHive: Hive?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera Preview
                if scanner.isScanning {
                    CameraPreview(scanner: scanner)
                        .ignoresSafeArea()
                } else {
                    Color.black
                        .ignoresSafeArea()
                }
                
                // Overlay
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("Position QR code within frame")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                        
                        if let error = scanner.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                setupScanner()
            }
            .onChange(of: scanner.scannedCode) { oldValue, newValue in
                if let code = newValue {
                    handleScannedCode(code)
                }
            }
            .fullScreenCover(item: $scannedHive) { hive in
                NavigationStack {
                    InspectionView(hive: hive)
                }
            }
        }
    }
    
    private func setupScanner() {
        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            do {
                try scanner.setupScanner()
            } catch {
                scanner.errorMessage = error.localizedDescription
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    Task { @MainActor in
                        do {
                            try scanner.setupScanner()
                        } catch {
                            scanner.errorMessage = error.localizedDescription
                        }
                    }
                } else {
                    showingPermissionAlert = true
                }
            }
        default:
            showingPermissionAlert = true
        }
    }
    
    private func handleScannedCode(_ code: String) {
        // Find hive by QR string
        let descriptor = FetchDescriptor<Hive>(predicate: #Predicate { $0.qrString == code })
        if let hive = try? modelContext.fetch(descriptor).first {
            scannedHive = hive
        } else {
            scanner.errorMessage = "Hive not found for QR code: \(code)"
            // Resume scanning after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                scanner.errorMessage = nil
                try? scanner.setupScanner()
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let scanner: QRScannerService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        DispatchQueue.main.async {
            if let previewLayer = scanner.createPreviewLayer(in: view.bounds) {
                view.layer.addSublayer(previewLayer)
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = scanner.previewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

#Preview {
    QRScannerView()
        .modelContainer(for: [Hive.self], inMemory: true)
}

