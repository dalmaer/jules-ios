//
//  NotificationManager.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }

    func scheduleNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        scheduleNotificationWithData(title: title, body: body, sessionId: nil, identifier: identifier)
    }

    func scheduleNotificationWithData(title: String, body: String, sessionId: String?, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Add session ID to userInfo for deep linking
        if let sessionId = sessionId {
            content.userInfo = ["sessionId": sessionId]
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
