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
                            ForEach(activities) { activity in
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
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
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

    private func loadActivities() async {
        isLoading = true
        errorMessage = nil

        do {
            activities = try await JulesAPIClient.shared.fetchActivities(sessionId: session.id)
        } catch {
            errorMessage = "Failed to load activities: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

struct ActivityRow: View {
    let activity: Activity

    var isUserMessage: Bool {
        activity.type.lowercased().contains("user") || activity.type == "message"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: isUserMessage ? "person.fill" : "robot.fill")
                .font(.title2)
                .foregroundColor(.white)
                .padding(16)
                .background(Color(red: 0.2, green: 0.18, blue: 0.28))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(isUserMessage ? "User: " : "Agent: ") + Text(activity.content)
                    .font(.body)
                    .foregroundColor(.white)

                Text(activity.timestamp)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
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

#Preview {
    NavigationStack {
        ActivitiesView(session: Session(
            id: "123",
            name: "session-123",
            title: "Test Session",
            sourceContext: Session.SourceContext(
                source: "sources/test",
                githubRepoContext: nil
            ),
            prompt: "Test prompt",
            requirePlanApproval: nil
        ))
    }
}
