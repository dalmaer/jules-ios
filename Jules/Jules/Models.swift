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
        let isPrivate: Bool?
        let defaultBranch: Branch?
        let branches: [Branch]?
    }

    struct Branch: Codable, Hashable {
        let displayName: String
    }
}

// MARK: - Session
struct Session: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let title: String?
    let createTime: String?
    let updateTime: String?
    let state: String?
    let url: String?
    let sourceContext: SourceContext?
    let prompt: String?
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
    let name: String
    let createTime: String?
    let originator: String?
    let progressUpdated: ProgressUpdated?
    let sessionCompleted: SessionCompleted?
    let planGenerated: PlanGenerated?
    let planApproved: PlanApproved?
    let artifacts: [Artifact]?

    struct ProgressUpdated: Codable, Hashable {
        let title: String?
        let description: String?
    }

    struct SessionCompleted: Codable, Hashable {
        // Empty for now, just marks completion
    }

    struct PlanGenerated: Codable, Hashable {
        let plan: Plan?

        struct Plan: Codable, Hashable {
            let id: String?
            let steps: [PlanStep]?

            struct PlanStep: Codable, Hashable {
                let id: String?
                let title: String?
                let index: Int?
            }
        }
    }

    struct PlanApproved: Codable, Hashable {
        let planId: String?
    }

    struct Artifact: Codable, Hashable {
        let changeSet: ChangeSet?

        struct ChangeSet: Codable, Hashable {
            let source: String?
            let gitPatch: GitPatch?

            struct GitPatch: Codable, Hashable {
                let unidiffPatch: String?
                let baseCommitId: String?
                let suggestedCommitMessage: String?
            }
        }
    }
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
