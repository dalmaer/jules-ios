//
//  ActivitiesView.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import SwiftUI

struct ActivitiesView: View {
    let session: Session

    @State private var activities: [Activity] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showMessageSheet = false
    @State private var pollingTimer: Timer?
    @State private var isPolling = false

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Content
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadActivities() }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    Spacer()
                } else if activities.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "message")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No activities yet")
                            .foregroundColor(.gray)
                            .font(.headline)
                        Text("Send a message to get started")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(activities.filter { hasDisplayableContent($0) }) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                        .padding()
                    }
                }

                // Talk to Agent Button
                Button(action: { showMessageSheet = true }) {
                    Text("Talk to Agent")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(session.title ?? "Session")
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
        }
        .sheet(isPresented: $showMessageSheet) {
            SendMessageSheet(session: session) {
                Task { await loadActivities() }
            }
        }
        .task {
            await loadActivities()
            startPolling()

            // Add this session to background monitoring
            BackgroundTaskManager.shared.addMonitoredSession(session.id, title: session.title ?? "Session")
        }
        .refreshable {
            await loadActivities()
        }
        .onDisappear {
            stopPolling()
        }
    }

    private func hasDisplayableContent(_ activity: Activity) -> Bool {
        // Check if activity has any meaningful content to display
        if let progress = activity.progressUpdated {
            if let desc = progress.description, !desc.isEmpty { return true }
            if let title = progress.title, !title.isEmpty { return true }
        }

        if activity.sessionCompleted != nil { return true }

        if let plan = activity.planGenerated?.plan, let steps = plan.steps, !steps.isEmpty {
            return true
        }

        if activity.planApproved != nil { return true }

        if let artifact = activity.artifacts?.first,
           let commitMsg = artifact.changeSet?.gitPatch?.suggestedCommitMessage,
           !commitMsg.isEmpty {
            return true
        }

        return false
    }

    private func loadActivities(silent: Bool = false) async {
        if !silent {
            isLoading = true
        }
        errorMessage = nil

        do {
            print("Loading activities for session: \(session.id)")
            print("Session name: \(session.name)")

            let newActivities = try await JulesAPIClient.shared.fetchActivities(sessionId: session.id)
            print("Loaded \(newActivities.count) activities")

            // Check for new activities from agent
            if let latestActivity = newActivities.first,
               !activities.contains(where: { $0.id == latestActivity.id }),
               latestActivity.originator?.lowercased() != "user" {

                // Extract notification content
                let notificationBody = extractNotificationContent(from: latestActivity)
                let sessionTitle = session.title ?? "Session"

                NotificationManager.shared.scheduleNotificationWithData(
                    title: "Jules: \(sessionTitle)",
                    body: notificationBody,
                    sessionId: session.id,
                    identifier: latestActivity.id
                )
            }

            activities = newActivities
        } catch let apiError as JulesAPIError {
            switch apiError {
            case .httpError(let code):
                errorMessage = "HTTP error \(code) loading activities"
            case .decodingError(let error):
                errorMessage = "Failed to decode activities: \(error.localizedDescription)"
            default:
                errorMessage = "Failed to load activities: \(apiError)"
            }
        } catch {
            errorMessage = "Failed to load activities: \(error.localizedDescription)"
        }

        if !silent {
            isLoading = false
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

    private func startPolling() {
        // Poll every 30 seconds
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await loadActivities(silent: true)
            }
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}

// MARK: - Activity Content Views

struct PlanGeneratedView: View {
    let planGenerated: Activity.PlanGenerated

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("I have a plan:")
                .font(.headline)
                .foregroundColor(.white)

            if let plan = planGenerated.plan, let steps = plan.steps {
                ForEach(steps.sorted(by: { ($0.index ?? 0) < ($1.index ?? 0) }), id: \.self) { step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(step.index.map { String($0 + 1) } ?? "•").")
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        Text(step.title ?? "Unnamed step")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct PlanApprovedView: View {
    var body: some View {
        Text("Plan approved.")
            .font(.body)
            .foregroundColor(.green)
    }
}

struct ProgressUpdatedView: View {
    let progressUpdated: Activity.ProgressUpdated

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = progressUpdated.title, !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            if let description = progressUpdated.description,
               !description.isEmpty,
               description != progressUpdated.title {
                Text(LocalizedStringKey(description))
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
        }
    }
}

struct SessionCompletedView: View {
    let artifacts: [Activity.Artifact]?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Completed")
                .font(.headline)
                .foregroundColor(.green)

            if let commitMsg = artifacts?.first?.changeSet?.gitPatch?.suggestedCommitMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested Commit Message:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(commitMsg)
                        .font(.body.monospaced())
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
            }
        }
    }
}

struct CodeChangeView: View {
    let artifacts: [Activity.Artifact]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(artifacts, id: \.self) { artifact in
                if let changeSet = artifact.changeSet, let gitPatch = changeSet.gitPatch {
                    VStack(alignment: .leading) {
                        if let commitMsg = gitPatch.suggestedCommitMessage, !commitMsg.isEmpty {
                            Text(commitMsg)
                                .font(.body)
                                .foregroundColor(.white)
                        } else if let patch = gitPatch.unidiffPatch {
                            let lines = patch.components(separatedBy: "\n")
                            let additions = lines.filter { $0.hasPrefix("+") && !$0.hasPrefix("+++") }.count
                            let deletions = lines.filter { $0.hasPrefix("-") && !$0.hasPrefix("---") }.count
                            Text("Code changed: +\(additions) insertions, -\(deletions) deletions")
                                .font(.body)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
}

struct FallbackActivityView: View {
    let activity: Activity

    var body: some View {
        Text(activity.name)
            .font(.body)
            .foregroundColor(.white)
            .fixedSize(horizontal: false, vertical: true)
    }
}


// MARK: - ActivityRow (Dispatcher)

struct ActivityRow: View {
    let activity: Activity

    private var isUserMessage: Bool {
        activity.originator?.lowercased() == "user"
    }

    private var activityType: String? {
        if activity.planGenerated != nil { return "Plan" }
        if activity.planApproved != nil { return "Plan Approved" }
        if activity.sessionCompleted != nil { return "Completed" }
        if activity.progressUpdated != nil { return "Progress" }
        if let artifacts = activity.artifacts, !artifacts.isEmpty { return "Code Change" }
        if let originator = activity.originator { return originator.capitalized }
        return nil
    }

    private var displayTime: String {
        formatRelativeTime(activity.createTime ?? "")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: isUserMessage ? "person.fill" : "cpu.fill")
                .font(.title3)
                .foregroundColor(.white)
                .padding(12)
                .background(Color(red: 0.2, green: 0.18, blue: 0.28))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 8) {
                // Header: Type and Time
                HStack {
                    if let type = activityType {
                        Text(type)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(6)
                    }
                    Spacer()
                    if !displayTime.isEmpty {
                        Text(displayTime)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                // Content View
                activityContentView()
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
        )
    }

    @ViewBuilder
    private func activityContentView() -> some View {
        if let planGen = activity.planGenerated {
            PlanGeneratedView(planGenerated: planGen)
        } else if activity.planApproved != nil {
            PlanApprovedView()
        } else if let progress = activity.progressUpdated {
            ProgressUpdatedView(progressUpdated: progress)
        } else if activity.sessionCompleted != nil {
            SessionCompletedView(artifacts: activity.artifacts)
        } else if let artifacts = activity.artifacts, !artifacts.isEmpty {
            CodeChangeView(artifacts: artifacts)
        } else {
            FallbackActivityView(activity: activity)
        }
    }

    private func formatRelativeTime(_ isoString: String) -> String {
        guard !isoString.isEmpty else { return "just now" }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let date: Date?
        if let d = formatter.date(from: isoString) {
            date = d
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: isoString)
        }

        guard let validDate = date else { return "a while ago" }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full
        return relativeFormatter.localizedString(for: validDate, relativeTo: Date())
    }
}

struct SendMessageSheet: View {
    let session: Session
    let onMessageSent: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.11, green: 0.11, blue: 0.15)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .foregroundColor(.white)
                            .font(.headline)

                        TextEditor(text: $message)
                            .frame(height: 200)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                            )
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Spacer()

                    Button(action: sendMessage) {
                        if isSending {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Message")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .disabled(isSending || message.isEmpty)
                    .opacity(message.isEmpty ? 0.5 : 1.0)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text("Talk to Agent")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func sendMessage() {
        guard !message.isEmpty else { return }

        isSending = true
        errorMessage = nil

        Task {
            do {
                try await JulesAPIClient.shared.sendMessage(sessionId: session.id, message: message)
                dismiss()
                onMessageSent()
            } catch {
                errorMessage = "Failed to send message: \(error.localizedDescription)"
                isSending = false
            }
        }
    }
}

// #Preview {
//     NavigationStack {
//         ActivitiesView(session: Session(
//             id: "123",
//             name: "session-123",
//             title: "Test Session",
//             sourceContext: Session.SourceContext(
//                 source: "sources/test",
//                 githubRepoContext: nil
//             ),
//             prompt: "Test prompt",
//             requirePlanApproval: nil
//         ))
//     }
// }
