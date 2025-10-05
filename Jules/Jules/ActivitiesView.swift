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
        }
        .refreshable {
            await loadActivities()
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

    private func loadActivities() async {
        isLoading = true
        errorMessage = nil

        do {
            print("Loading activities for session: \(session.id)")
            print("Session name: \(session.name)")
            activities = try await JulesAPIClient.shared.fetchActivities(sessionId: session.id)
            print("Loaded \(activities.count) activities")
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

        isLoading = false
    }
}

struct ActivityRow: View {
    let activity: Activity

    var isUserMessage: Bool {
        activity.originator?.lowercased() == "user"
    }

    var displayContent: String {
        // Check for plan generated
        if let planGen = activity.planGenerated, let plan = planGen.plan, let steps = plan.steps {
            return steps.enumerated().map { index, step in
                let num = step.index ?? index
                return "\(num + 1). \(step.title ?? "Step \(num + 1)")"
            }.joined(separator: "\n\n")
        }

        // Check for plan approved
        if activity.planApproved != nil {
            return "Plan approved by user"
        }

        // Check for progress update
        if let progress = activity.progressUpdated {
            if let description = progress.description, !description.isEmpty {
                return description
            }
            if let title = progress.title, !title.isEmpty {
                return title
            }
        }

        // Check for session completion
        if activity.sessionCompleted != nil {
            // Get commit message from artifacts if available
            if let commitMsg = activity.artifacts?.first?.changeSet?.gitPatch?.suggestedCommitMessage {
                return commitMsg
            }
            return "Session completed"
        }

        // Check for code changes
        if let artifact = activity.artifacts?.first,
           let changeSet = artifact.changeSet,
           let gitPatch = changeSet.gitPatch {
            if let commitMsg = gitPatch.suggestedCommitMessage, !commitMsg.isEmpty {
                return commitMsg
            }
            // Show a summary of changes
            let patch = gitPatch.unidiffPatch ?? ""
            let lines = patch.components(separatedBy: "\n")
            let additions = lines.filter { $0.hasPrefix("+") && !$0.hasPrefix("+++") }.count
            let deletions = lines.filter { $0.hasPrefix("-") && !$0.hasPrefix("---") }.count
            return "Code changes: +\(additions) -\(deletions) lines"
        }

        // Fallback to name
        return activity.name
    }

    var displayTime: String {
        let timeString = activity.createTime ?? ""
        return formatRelativeTime(timeString)
    }

    var activityType: String? {
        if activity.planGenerated != nil {
            return "Plan"
        }

        if activity.planApproved != nil {
            return "Plan Approved"
        }

        if activity.sessionCompleted != nil {
            return "Completed"
        }

        if activity.progressUpdated != nil {
            return "Progress"
        }

        if activity.artifacts != nil {
            return "Code Change"
        }

        if let originator = activity.originator {
            return originator.capitalized
        }

        return nil
    }

    func formatRelativeTime(_ isoString: String) -> String {
        guard !isoString.isEmpty else { return "" }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: isoString) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: isoString) else {
                return isoString
            }
            return formatDate(date)
        }

        return formatDate(date)
    }

    func formatDate(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        // Less than a minute
        if interval < 60 {
            return "just now"
        }

        // Less than an hour
        if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins) min\(mins == 1 ? "" : "s") ago"
        }

        // Less than a day
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }

        // Less than a week
        if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }

        // Format as "14:42 on January 6th, 1976"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let time = timeFormatter.string(from: date)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        let dateStr = dateFormatter.string(from: date)

        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }

        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        let year = yearFormatter.string(from: date)

        return "\(time) on \(dateStr)\(suffix), \(year)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: isUserMessage ? "person.fill" : "cpu.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color(red: 0.2, green: 0.18, blue: 0.28))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 6) {
                    // Activity type if available
                    if let type = activityType, !type.isEmpty {
                        Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(6)
                    }

                    Text(displayContent)
                        .font(.body)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    if !displayTime.isEmpty {
                        Text(displayTime)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
        )
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
            .navigationTitle("Talk to Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
