//
//  SessionsView.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import SwiftUI

struct SessionsView: View {
    let source: Source

    @State private var sessions: [Session] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateSession = false

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sessions")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

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
                            Task { await loadSessions() }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    Spacer()
                } else if sessions.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No sessions yet")
                            .foregroundColor(.gray)
                            .font(.headline)
                        Text("Create a session to get started")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(sessions) { session in
                                NavigationLink(value: session) {
                                    SessionRow(session: session)
                                }
                            }
                        }
                        .padding()
                    }
                }

                // Create Session Button
                Button(action: { showCreateSession = true }) {
                    Text("Create Session")
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
        .navigationTitle("Source")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Session.self) { session in
            ActivitiesView(session: session)
        }
        .sheet(isPresented: $showCreateSession) {
            CreateSessionSheet(source: source) {
                Task { await loadSessions() }
            }
        }
        .task {
            await loadSessions()
        }
    }

    private func loadSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            let allSessions = try await JulesAPIClient.shared.fetchSessions()
            // Filter sessions for this source
            sessions = allSessions.filter { $0.sourceContext.source.contains(source.id) }
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.title2)
                .foregroundColor(.white)
                .padding(16)
                .background(Color(red: 0.2, green: 0.18, blue: 0.28))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(session.name)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
        )
    }
}

struct CreateSessionSheet: View {
    let source: Source
    let onSessionCreated: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var prompt = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.11, green: 0.11, blue: 0.15)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .foregroundColor(.white)
                            .font(.headline)

                        TextField("e.g., Boba App", text: $title)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                            )
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prompt")
                            .foregroundColor(.white)
                            .font(.headline)

                        TextEditor(text: $prompt)
                            .frame(height: 120)
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

                    Button(action: createSession) {
                        if isCreating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Session")
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
                    .disabled(isCreating || title.isEmpty || prompt.isEmpty)
                    .opacity((title.isEmpty || prompt.isEmpty) ? 0.5 : 1.0)
                }
                .padding()
            }
            .navigationTitle("Create Session")
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

    private func createSession() {
        guard !title.isEmpty, !prompt.isEmpty else { return }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                _ = try await JulesAPIClient.shared.createSession(
                    title: title,
                    prompt: prompt,
                    sourceId: source.id
                )
                dismiss()
                onSessionCreated()
            } catch {
                errorMessage = "Failed to create session: \(error.localizedDescription)"
                isCreating = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        SessionsView(source: Source(
            id: "123",
            name: "Test Source",
            githubRepo: Source.GitHubRepo(owner: "test", repo: "repo")
        ))
    }
}
