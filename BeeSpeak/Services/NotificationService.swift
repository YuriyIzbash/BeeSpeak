//
//  NotificationService.swift
//  BeeSpeak
//
//  Created by yuriy on 24. 11. 25.
//

import Foundation
import UserNotifications

/// Service for scheduling local notifications for treatment reminders
@MainActor
class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    /// Request notification authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    /// Schedule a treatment reminder notification
    func scheduleTreatmentReminder(for treatment: Treatment, hiveName: String) async throws -> String {
        guard let nextCheckDate = treatment.nextCheckDate else {
            throw NotificationError.noDateProvided
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Treatment Check Reminder"
        content.body = "Time to check treatment for \(hiveName): \(treatment.product)"
        content.sound = .default
        content.categoryIdentifier = "TREATMENT_REMINDER"
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextCheckDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let notificationID = UUID().uuidString
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        
        try await UNUserNotificationCenter.current().add(request)
        return notificationID
    }
    
    /// Cancel a scheduled notification
    func cancelNotification(withID id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

enum NotificationError: LocalizedError {
    case noDateProvided
    
    var errorDescription: String? {
        switch self {
        case .noDateProvided:
            return "No next check date provided for treatment"
        }
    }
}

