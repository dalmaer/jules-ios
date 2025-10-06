//
//  JulesApp.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import SwiftUI
import UserNotifications

@main
struct JulesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var navigationCoordinator = NavigationCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationCoordinator)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register background tasks
        BackgroundTaskManager.shared.registerBackgroundTasks()

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Schedule initial background refresh
        BackgroundTaskManager.shared.scheduleAppRefresh()

        return true
    }

    // Handle notification tap when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let sessionId = userInfo["sessionId"] as? String {
            // Post notification to navigate to session
            NotificationCenter.default.post(name: NSNotification.Name("OpenSession"), object: sessionId)
        }

        completionHandler()
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

class NavigationCoordinator: ObservableObject {
    @Published var sessionToOpen: Session?

    init() {
        // Listen for notification taps
        NotificationCenter.default.addObserver(forName: NSNotification.Name("OpenSession"), object: nil, queue: .main) { notification in
            if let sessionId = notification.object as? String {
                self.openSession(sessionId: sessionId)
            }
        }
    }

    private func openSession(sessionId: String) {
        Task {
            do {
                // Fetch all sessions to find the one we need
                let sessions = try await JulesAPIClient.shared.fetchSessions()
                if let session = sessions.first(where: { $0.id == sessionId }) {
                    await MainActor.run {
                        self.sessionToOpen = session
                    }
                }
            } catch {
                print("Error fetching session: \(error)")
            }
        }
    }
}
