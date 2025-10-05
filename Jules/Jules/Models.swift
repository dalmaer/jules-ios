//
//  Models.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import Foundation

// MARK: - Source
struct Source: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let githubRepo: GitHubRepo

    struct GitHubRepo: Codable, Hashable {
        let owner: String
        let repo: String
    }
}

// MARK: - Session
struct Session: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let title: String
    let sourceContext: SourceContext
    let prompt: String
    let requirePlanApproval: Bool?

    struct SourceContext: Codable, Hashable {
        let source: String
        let githubRepoContext: GitHubRepoContext?

        struct GitHubRepoContext: Codable, Hashable {
            let startingBranch: String
        }
    }
}

// MARK: - Activity
struct Activity: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let content: String
    let timestamp: String
}

// MARK: - API Request/Response Models

struct CreateSessionRequest: Codable {
    let title: String
    let prompt: String
    let sourceId: String
}

struct SendMessageRequest: Codable {
    let message: String
}
