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
            print("\n========== API REQUEST ==========")
            print("URL: \(request.url?.absoluteString ?? "unknown")")
            print("Method: \(request.httpMethod ?? "GET")")
            print("Headers:")
            request.allHTTPHeaderFields?.forEach { key, value in
                // Mask the API key for security
                if key == "X-Goog-Api-Key" {
                    print("  \(key): [REDACTED]")
                } else {
                    print("  \(key): \(value)")
                }
            }
            if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
                print("Request Body:")
                print(bodyString)
            }
            print("=================================\n")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw JulesAPIError.invalidResponse
            }

            print("\n========== API RESPONSE ==========")
            print("Status Code: \(httpResponse.statusCode)")
            print("Response Size: \(data.count) bytes")

            guard (200...299).contains(httpResponse.statusCode) else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Error Response Body:")
                    print(responseString)
                }
                print("==================================\n")
                throw JulesAPIError.httpError(httpResponse.statusCode)
            }

            // Print successful response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Body:")
                print(responseString)
            }
            print("==================================\n")

            // Handle empty response
            if data.isEmpty {
                print("⚠️ Warning: Empty response received")
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("\n========== DECODING ERROR ==========")
                print("Error: \(error)")
                if let decodingError = error as? DecodingError {
                    print("Detailed: \(decodingError)")
                }
                print("====================================\n")
                throw JulesAPIError.decodingError(error)
            }
        } catch let error as JulesAPIError {
            throw error
        } catch {
            print("\n========== NETWORK ERROR ==========")
            print("Error: \(error.localizedDescription)")
            print("===================================\n")
            throw JulesAPIError.networkError(error)
        }
    }

    // MARK: - API Methods

    func fetchSources() async throws -> [Source] {
        let request = try createRequest(path: "/sources")
        let response: SourcesResponse = try await performRequest(request)
        return response.sources ?? []
    }

    func fetchSessions(pageSize: Int = 50, sourceId: String? = nil) async throws -> [Session] {
        var path = "/sessions?pageSize=\(pageSize)"
        if let sourceId = sourceId {
            // URL encode the source parameter
            if let encodedSource = sourceId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                path += "&source=\(encodedSource)"
            }
        }
        let request = try createRequest(path: path)
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
