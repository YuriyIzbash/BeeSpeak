# BeeSpeak - Beekeeping Inspection Tracker

A comprehensive iOS app for beekeepers to track hive inspections, treatments, and harvests using voice commands, photos, and structured data entry.

## Features

### Core Features
- **Apiary & Hive Management**: Organize your apiaries and hives with QR code support
- **Inspection Tracking**: Record detailed inspections with structured flags (Queen seen, Eggs present, Brood pattern, Queen cells, Varroa levels)
- **Voice Commands**: On-device speech recognition with keyword parsing for hands-free inspection recording
- **Pocket Inspection Mode**: Voice-driven inspection mode for use when phone is in pocket (works with AirPods/headphones)
- **Photo Capture**: Attach photos to inspections with automatic timestamping
- **QR Code Scanner**: Quick access to hive inspections via QR codes
- **Treatment Tracking**: Record treatments and schedule reminder notifications
- **Dashboard**: Overview of hive health, recent inspections, and upcoming treatment checks
- **Data Export**: Export all data to JSON, CSV, or generate PDF summaries per hive

### Technical Highlights
- **iOS 18+** with Swift 6 and SwiftUI
- **SwiftData** for local-first persistence
- **On-device Speech Recognition** using Apple Speech framework
- **MVVM Architecture** for testable, modular code
- **Offline-first**: All features work without network connectivity
- **Accessibility**: VoiceOver support, large tap targets, scalable fonts

## Requirements

- iOS 18.0 or later
- Xcode 16.0 or later
- Swift 6.0
- Physical device recommended for testing (camera, microphone, speech recognition)

## Building and Running

1. Open `BeeSpeak.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on a physical iOS device (simulator has limited support for camera/microphone)
4. Grant permissions when prompted:
   - Microphone (for voice recording)
   - Camera (for photos and QR scanning)
   - Photo Library (for selecting photos)
   - Notifications (for treatment reminders)

## Project Structure

```
BeeSpeak/
├── Models/              # SwiftData models
│   ├── Apiary.swift
│   ├── Hive.swift
│   ├── Inspection.swift
│   ├── Treatment.swift
│   └── Harvest.swift
├── Services/            # Business logic services
│   ├── SpeechRecognitionService.swift
│   ├── PhotoManager.swift
│   ├── QRScannerService.swift
│   ├── ExportService.swift
│   └── NotificationService.swift
├── ViewModels/          # MVVM view models
│   ├── InspectionViewModel.swift
│   └── ApiaryListViewModel.swift
├── Views/               # SwiftUI views
│   ├── HomeView.swift
│   ├── ApiaryListView.swift
│   ├── HiveListView.swift
│   ├── InspectionView.swift
│   ├── PocketInspectionModeView.swift
│   ├── QRScannerView.swift
│   ├── DashboardView.swift
│   ├── TreatmentsView.swift
│   └── SettingsView.swift
└── BeeSpeakApp.swift    # App entry point
```

## Voice Commands

The app recognizes the following voice commands (case-insensitive):

- **"Start inspection"** / **"Finish inspection"**
- **"Queen seen"** / **"Queen not seen"**
- **"Eggs present"** / **"Eggs not present"**
- **"Brood good"** / **"Brood bad"**
- **"Queen cells present"** / **"Queen cells absent"**
- **"Varroa low"** / **"Varroa medium"** / **"Varroa high"**
- **"Add photo"** (triggers camera capture)
- **"Next frame"** (timestamp marker)
- **"Save"** / **"Cancel"**

## Testing Pocket Inspection Mode

1. Connect AirPods or headphones to your device
2. Open a hive inspection
3. Tap "Pocket Inspection Mode"
4. Place phone in pocket
5. Say commands like "Queen seen", "Eggs present", "Varroa low"
6. The app will parse commands and update inspection flags
7. Tap "Save & Finish" when done

**Note**: Speech recognition works best in quiet environments. Commands should be spoken clearly and at a normal pace.

## Data Export

### JSON Export
Exports all apiaries, hives, inspections, treatments, and harvests in JSON format with ISO8601 date formatting.

### CSV Export
Exports data in CSV format with separate sections for:
- Inspections
- Treatments
- Harvests

### PDF Summary
Generates a PDF summary for a specific hive including:
- Hive information
- Recent inspections (last 10)
- Inspection details (flags, varroa levels, notes)

## Permissions

The app requires the following permissions (with user-facing explanations):

- **Microphone**: For voice recording during inspections
- **Camera**: For photo capture and QR code scanning
- **Photo Library**: For selecting existing photos
- **Notifications**: For treatment reminder scheduling

All permissions are requested with clear explanations of why they're needed.

## Disclaimer

**Record-keeping only — not medical or treatment advice.**

This application is designed for beekeepers to record and track hive inspections, treatments, and harvests. The information stored in this app is for record-keeping purposes only.

This app does not provide medical advice, treatment recommendations, or professional beekeeping guidance. Always consult with a qualified beekeeping professional or veterinarian for treatment decisions and hive management advice.

## Architecture

- **MVVM Pattern**: Separation of concerns with ViewModels handling business logic
- **SwiftData**: Local-first data persistence with automatic relationship management
- **Async/Await**: Modern Swift concurrency for speech recognition and notifications
- **Service Layer**: Reusable services for speech, photos, QR scanning, export, and notifications

## Known Limitations

- Speech recognition requires internet connection for some languages (on-device recognition preferred when available)
- Photo storage is local to the app (not synced to iCloud Photos)
- No cloud sync/backup in MVP (export functionality provided)
- QR code generation for printing not yet implemented (QR string is available per hive)

## Future Enhancements (Optional)

- iCloud sync for data backup
- QR code generation and printing
- Photo thumbnail caching
- Onboarding flow
- Custom voice command training
- Advanced analytics and trends

## License

This project is provided as-is for beekeeping record-keeping purposes.

