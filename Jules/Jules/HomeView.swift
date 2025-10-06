//
//  HomeView.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import SwiftUI

struct HomeView: View {
    @State private var recentSources: [Source] = []
    @State private var otherSources: [Source] = []
    @State private var isLoading = false
    @State private var showSettings = false
    @State private var errorMessage: String?
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(red: 0.11, green: 0.11, blue: 0.15)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        // Jules logo placeholder - replace with actual logo image
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 60, height: 60)

                            // Octopus-like shape to represent Jules logo
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 30, height: 30)
                                HStack(spacing: 4) {
                                    ForEach(0..<4) { _ in
                                        Capsule()
                                            .fill(Color.purple)
                                            .frame(width: 6, height: 15)
                                    }
                                }
                            }
                            .padding(8)
                        }

                        Text("Jules")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()

                    // Content
                    VStack(alignment: .leading, spacing: 0) {
                        if isLoading {
                            Spacer()
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(2.0)
                                    .tint(.white)
                                Spacer()
                            }
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
                                    Task { await loadSources(forceRefresh: true) }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .padding()
                            Spacer()
                        } else if recentSources.isEmpty && otherSources.isEmpty {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "folder")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No sources connected")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                            }
                            Spacer()
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    if !recentSources.isEmpty {
                                        Text("Recent Sources")
                                            .font(.title3)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal)
                                            .padding(.bottom, 4)

                                        VStack(spacing: 12) {
                                            ForEach(recentSources) { source in
                                                NavigationLink(value: source) {
                                                    SourceRow(source: source, isRecent: true)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }

                                    if !otherSources.isEmpty {
                                        Text("All Sources")
                                            .font(.title3)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal)
                                            .padding(.top, recentSources.isEmpty ? 0 : 20)
                                            .padding(.bottom, 4)

                                        VStack(spacing: 12) {
                                            ForEach(otherSources) { source in
                                                NavigationLink(value: source) {
                                                    SourceRow(source: source)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .refreshable {
                                await loadSources(forceRefresh: true)
                            }
                        }

                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationDestination(for: Source.self) { source in
                SessionsView(source: source)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .task {
                await loadSources()
            }
            .onChange(of: navigationCoordinator.sessionToOpen) { _, newSession in
                if let session = newSession {
                    // Find the source for this session
                    if let source = (recentSources + otherSources).first(where: { source in
                        session.sourceContext?.source == source.id ||
                        session.sourceContext?.source == source.name
                    }) {
                        navigationPath.append(source)
                        navigationPath.append(session)
                    }
                    // Clear the session after navigation
                    navigationCoordinator.sessionToOpen = nil
                }
            }
        }
    }

    private func loadSources(forceRefresh: Bool = false) async {
        if !forceRefresh {
            isLoading = true
        }
        errorMessage = nil

        do {
            let fetchedSources = try await JulesAPIClient.shared.fetchSources(forceRefresh: forceRefresh)
            let recentIDs = RecentSourcesManager.shared.getRecentSourceIDs()
            let recentIDSet = Set(recentIDs)

            let sourceDict = Dictionary(uniqueKeysWithValues: fetchedSources.map { ($0.id, $0) })

            var recent: [Source] = []
            for id in recentIDs {
                if let source = sourceDict[id] {
                    recent.append(source)
                }
            }

            var others = fetchedSources.filter { !recentIDSet.contains($0.id) }
            others.sort {
                $0.githubRepo.repo.lowercased() < $1.githubRepo.repo.lowercased()
            }

            self.recentSources = recent
            self.otherSources = others

        } catch JulesAPIError.noAPIKey {
            errorMessage = "No API key found. Please add one in Settings."
        } catch {
            errorMessage = "Failed to load sources: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

struct SourceRow: View {
    let source: Source
    var isRecent: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon
            Image(systemName: isRecent ? "arrow.counterclockwise" : "network")
                .font(.title)
                .foregroundColor(isRecent ? .yellow : .green)
                .padding(12)
                .background((isRecent ? Color.yellow : Color.green).opacity(0.2))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(source.githubRepo.owner)/\(source.githubRepo.repo)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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

// Preview disabled due to API key requirement
// #Preview {
//     HomeView()
// }
