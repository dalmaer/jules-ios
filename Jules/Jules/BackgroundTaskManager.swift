//
//  BackgroundTaskManager.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import Foundation
import BackgroundTasks

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    static let backgroundTaskIdentifier = "com.jules.ios.refresh"

    private init() {}

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.backgroundTaskIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh
        scheduleAppRefresh()

        // Create task to check for new activities
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let checkOperation = BlockOperation {
            Task {
                await self.checkForNewActivities()
            }
        }

        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        checkOperation.completionBlock = {
            task.setTaskCompleted(success: !checkOperation.isCancelled)
        }

        queue.addOperation(checkOperation)
    }

    private func checkForNewActivities() async {
        // Get the last known sessions from UserDefaults
        guard let sessionIds = UserDefaults.standard.array(forKey: "monitoredSessions") as? [String] else {
            return
        }

        for sessionId in sessionIds {
            do {
                let activities = try await JulesAPIClient.shared.fetchActivities(sessionId: sessionId)

                // Check if there's a new activity from agent
                let lastActivityId = UserDefaults.standard.string(forKey: "lastActivity_\(sessionId)")

                if let latestActivity = activities.first,
                   latestActivity.id != lastActivityId,
                   latestActivity.originator?.lowercased() != "user" {

                    // Save this as the latest activity
                    UserDefaults.standard.set(latestActivity.id, forKey: "lastActivity_\(sessionId)")

                    // Get session title
                    let sessionTitle = UserDefaults.standard.string(forKey: "sessionTitle_\(sessionId)") ?? "Session"

                    // Send notification
                    let body = extractNotificationContent(from: latestActivity)
                    NotificationManager.shared.scheduleNotificationWithData(
                        title: "Jules: \(sessionTitle)",
                        body: body,
                        sessionId: sessionId,
                        identifier: latestActivity.id
                    )
                }
            } catch {
                print("Error checking activities for session \(sessionId): \(error)")
            }
        }
    }

    private func extractNotificationContent(from activity: Activity) -> String {
        if let progress = activity.progressUpdated {
            if let title = progress.title, !title.isEmpty {
                return title
            }
            if let description = progress.description, !description.isEmpty {
                return description
            }
        }

        if activity.sessionCompleted != nil {
            return "Session completed"
        }

        if let plan = activity.planGenerated?.plan, let steps = plan.steps, !steps.isEmpty {
            return "Generated a plan with \(steps.count) steps"
        }

        if activity.planApproved != nil {
            return "Plan approved"
        }

        if let artifact = activity.artifacts?.first,
           let commitMsg = artifact.changeSet?.gitPatch?.suggestedCommitMessage,
           !commitMsg.isEmpty {
            return commitMsg
        }

        return "New activity"
    }

    func addMonitoredSession(_ sessionId: String, title: String) {
        var sessions = UserDefaults.standard.array(forKey: "monitoredSessions") as? [String] ?? []
        if !sessions.contains(sessionId) {
            sessions.append(sessionId)
            UserDefaults.standard.set(sessions, forKey: "monitoredSessions")
            UserDefaults.standard.set(title, forKey: "sessionTitle_\(sessionId)")
        }
    }

    func removeMonitoredSession(_ sessionId: String) {
        var sessions = UserDefaults.standard.array(forKey: "monitoredSessions") as? [String] ?? []
        sessions.removeAll { $0 == sessionId }
        UserDefaults.standard.set(sessions, forKey: "monitoredSessions")
        UserDefaults.standard.removeObject(forKey: "lastActivity_\(sessionId)")
        UserDefaults.standard.removeObject(forKey: "sessionTitle_\(sessionId)")
    }
}
