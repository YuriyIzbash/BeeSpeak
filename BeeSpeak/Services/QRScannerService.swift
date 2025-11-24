//
//  QRScannerService.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

/// Service for QR code scanning using AVFoundation
@MainActor
class QRScannerService: NSObject, ObservableObject {
    @Published var scannedCode: String?
    @Published var isScanning = false
    @Published var errorMessage: String?
    
    private var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    /// Setup and start QR scanning
    func setupScanner() throws {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            throw QRScannerError.cameraUnavailable
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            throw QRScannerError.inputError(error)
        }
        
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            throw QRScannerError.cannotAddInput
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            throw QRScannerError.cannotAddOutput
        }
        
        isScanning = true
        captureSession.startRunning()
    }
    
    /// Stop scanning
    func stopScanning() {
        captureSession?.stopRunning()
        isScanning = false
    }
    
    /// Create preview layer for camera view
    func createPreviewLayer(in bounds: CGRect) -> AVCaptureVideoPreviewLayer? {
        guard let captureSession = captureSession else { return nil }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
        
        return previewLayer
    }
}

extension QRScannerService: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
        Task { @MainActor in
            self.scannedCode = stringValue
            self.stopScanning()
        }
    }
}

enum QRScannerError: LocalizedError {
    case cameraUnavailable
    case inputError(Error)
    case cannotAddInput
    case cannotAddOutput
    
    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is not available"
        case .inputError(let error):
            return "Input error: \(error.localizedDescription)"
        case .cannotAddInput:
            return "Cannot add camera input"
        case .cannotAddOutput:
            return "Cannot add metadata output"
        }
    }
}

