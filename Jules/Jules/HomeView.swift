//
//  HomeView.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import SwiftUI

struct HomeView: View {
    @State private var sources: [Source] = []
    @State private var isLoading = false
    @State private var showSettings = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
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
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Connected Sources")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .padding(.horizontal)

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
                                    Task { await loadSources() }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .padding()
                            Spacer()
                        } else if sources.isEmpty {
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
                                VStack(spacing: 12) {
                                    ForEach(sources) { source in
                                        NavigationLink(value: source) {
                                            SourceRow(source: source)
                                        }
                                    }
                                }
                                .padding(.horizontal)
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
        }
    }

    private func loadSources() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedSources = try await JulesAPIClient.shared.fetchSources()
            // Sort sources by repository name
            sources = fetchedSources.sorted {
                $0.githubRepo.repo.lowercased() < $1.githubRepo.repo.lowercased()
            }
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

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: "network")
                .font(.title)
                .foregroundColor(.green)
                .padding(12)
                .background(Color.green.opacity(0.2))
                .cornerRadius(8)

            Text("\(source.githubRepo.owner)/\(source.githubRepo.repo)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

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

// Preview disabled due to API key requirement
// #Preview {
//     HomeView()
// }
