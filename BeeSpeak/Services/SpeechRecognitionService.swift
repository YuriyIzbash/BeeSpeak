//
//  SpeechRecognitionService.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import Speech
import AVFoundation
import Combine
import UIKit

/// Service for on-device speech recognition with keyword parsing for voice commands
@MainActor
class SpeechRecognitionService: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var lastCommand: String?
    @Published var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    // Keyword mappings for voice commands
    private let commandKeywords: [String: [String]] = [
        "start_inspection": ["start inspection", "begin inspection"],
        "finish_inspection": ["finish inspection", "end inspection", "complete inspection"],
        "queen_seen": ["queen seen", "saw queen", "queen present"],
        "queen_not_seen": ["queen not seen", "no queen", "queen absent"],
        "eggs_present": ["eggs present", "eggs seen", "has eggs"],
        "eggs_not_present": ["eggs not present", "no eggs", "eggs absent"],
        "brood_good": ["brood good", "brood pattern good", "good brood"],
        "brood_bad": ["brood bad", "brood pattern bad", "poor brood"],
        "queen_cells_present": ["queen cells present", "queen cells seen", "has queen cells"],
        "queen_cells_absent": ["queen cells absent", "no queen cells", "queen cells not present"],
        "varroa_low": ["varroa low", "low varroa"],
        "varroa_medium": ["varroa medium", "medium varroa"],
        "varroa_high": ["varroa high", "high varroa"],
        "add_photo": ["add photo", "take photo", "capture photo"],
        "next_frame": ["next frame", "mark frame"],
        "save": ["save", "save inspection"],
        "cancel": ["cancel", "discard"]
    ]
    
    init() {
        // Prefer on-device recognition when available
        speechRecognizer?.defaultTaskHint = .dictation
    }
    
    /// Request speech recognition authorization
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    /// Start recording and transcribing speech
    func startRecording() async throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }
        
        // Request microphone permission
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw SpeechError.audioEngineError
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionRequestError
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true // Force on-device
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        transcript = ""
        lastCommand = nil
        errorMessage = nil
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                self.transcript = bestString
                
                // Check for command keywords
                if let command = self.parseCommand(from: bestString) {
                    self.lastCommand = command
                    // Provide haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.stopRecording()
            }
        }
    }
    
    /// Stop recording
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        isRecording = false
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    /// Parse voice command from transcript using keyword matching
    func parseCommand(from text: String) -> String? {
        let lowercased = text.lowercased()
        
        // Check each command pattern
        for (command, keywords) in commandKeywords {
            for keyword in keywords {
                if lowercased.contains(keyword) {
                    return command
                }
            }
        }
        
        return nil
    }
    
    /// Extract structured flags from transcript
    func extractFlags(from transcript: String) -> InspectionFlags {
        let lowercased = transcript.lowercased()
        
        var flags = InspectionFlags()
        
        // Queen seen
        if lowercased.contains("queen seen") || lowercased.contains("saw queen") {
            flags.queenSeen = true
        } else if lowercased.contains("queen not seen") || lowercased.contains("no queen") {
            flags.queenSeen = false
        }
        
        // Eggs
        if lowercased.contains("eggs present") || lowercased.contains("eggs seen") {
            flags.eggsPresent = true
        } else if lowercased.contains("eggs not present") || lowercased.contains("no eggs") {
            flags.eggsPresent = false
        }
        
        // Brood pattern
        if lowercased.contains("brood good") || lowercased.contains("good brood") {
            flags.broodPatternGood = true
        } else if lowercased.contains("brood bad") || lowercased.contains("poor brood") {
            flags.broodPatternGood = false
        }
        
        // Queen cells
        if lowercased.contains("queen cells present") || lowercased.contains("queen cells seen") {
            flags.queenCells = true
        } else if lowercased.contains("queen cells absent") || lowercased.contains("no queen cells") {
            flags.queenCells = false
        }
        
        // Varroa level
        if lowercased.contains("varroa high") || lowercased.contains("high varroa") {
            flags.varroaLevel = .high
        } else if lowercased.contains("varroa medium") || lowercased.contains("medium varroa") {
            flags.varroaLevel = .medium
        } else if lowercased.contains("varroa low") || lowercased.contains("low varroa") {
            flags.varroaLevel = .low
        }
        
        return flags
    }
}

/// Structured flags extracted from voice commands
struct InspectionFlags {
    var queenSeen: Bool?
    var eggsPresent: Bool?
    var broodPatternGood: Bool?
    var queenCells: Bool?
    var varroaLevel: VarroaLevel = .none
}

enum SpeechError: LocalizedError {
    case recognizerUnavailable
    case audioEngineError
    case recognitionRequestError
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognizer is not available"
        case .audioEngineError:
            return "Audio engine error"
        case .recognitionRequestError:
            return "Recognition request error"
        case .authorizationDenied:
            return "Speech recognition authorization denied"
        }
    }
}

