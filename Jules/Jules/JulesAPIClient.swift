//
//  JulesAPIClient.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import Foundation

enum JulesAPIError: Error {
    case invalidURL
    case noAPIKey
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
}

class JulesAPIClient {
    static let shared = JulesAPIClient()
    private let baseURL = "https://jules.googleapis.com/v1alpha"
    private let keychainManager = KeychainManager.shared

    private init() {}

    // MARK: - Helper Methods

    private func createRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) throws -> URLRequest {
        guard let apiKey = keychainManager.getAPIKey() else {
            throw JulesAPIError.noAPIKey
        }

        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw JulesAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = body
        }

        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw JulesAPIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw JulesAPIError.httpError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw JulesAPIError.decodingError(error)
            }
        } catch let error as JulesAPIError {
            throw error
        } catch {
            throw JulesAPIError.networkError(error)
        }
    }

    // MARK: - API Methods

    func fetchSources() async throws -> [Source] {
        let request = try createRequest(path: "/sources")
        let response: SourcesResponse = try await performRequest(request)
        return response.sources ?? []
    }

    func fetchSessions(pageSize: Int = 50) async throws -> [Session] {
        let request = try createRequest(path: "/sessions?pageSize=\(pageSize)")
        let response: SessionsResponse = try await performRequest(request)
        return response.sessions ?? []
    }

    func createSession(title: String, prompt: String, sourceId: String) async throws -> Session {
        let requestBody = CreateSessionRequestBody(
            title: title,
            prompt: prompt,
            sourceContext: CreateSessionRequestBody.SourceContext(source: sourceId)
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let bodyData = try encoder.encode(requestBody)

        let request = try createRequest(path: "/sessions", method: "POST", body: bodyData)
        return try await performRequest(request)
    }

    func fetchActivities(sessionId: String, pageSize: Int = 50) async throws -> [Activity] {
        let request = try createRequest(path: "/sessions/\(sessionId)/activities?pageSize=\(pageSize)")
        let response: ActivitiesResponse = try await performRequest(request)
        return response.activities ?? []
    }

    func sendMessage(sessionId: String, message: String) async throws {
        let requestBody = SendMessageRequestBody(prompt: message)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let bodyData = try encoder.encode(requestBody)

        let request = try createRequest(
            path: "/sessions/\(sessionId):sendMessage",
            method: "POST",
            body: bodyData
        )

        let _: EmptyResponse = try await performRequest(request)
    }
}

// MARK: - Response Models

private struct SourcesResponse: Codable {
    let sources: [Source]?
}

private struct SessionsResponse: Codable {
    let sessions: [Session]?
}

private struct ActivitiesResponse: Codable {
    let activities: [Activity]?
}

private struct EmptyResponse: Codable {}

private struct CreateSessionRequestBody: Codable {
    let title: String
    let prompt: String
    let sourceContext: SourceContext

    struct SourceContext: Codable {
        let source: String
    }
}

private struct SendMessageRequestBody: Codable {
    let prompt: String
}
