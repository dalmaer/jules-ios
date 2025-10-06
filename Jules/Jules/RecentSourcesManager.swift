//
//  RecentSourcesManager.swift
//  Jules
//
//  Created by Jules on 10/5/25.
//

import Foundation

class RecentSourcesManager {
    static let shared = RecentSourcesManager()
    private let key = "recentSourceIDs"
    private let maxCount = 3

    private init() {}

    func getRecentSourceIDs() -> [String] {
        return UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func addRecentSource(id: String) {
        var recentIDs = getRecentSourceIDs()

        // Remove the id if it already exists to avoid duplicates and move it to the front
        if let index = recentIDs.firstIndex(of: id) {
            recentIDs.remove(at: index)
        }

        // Add the new id to the front
        recentIDs.insert(id, at: 0)

        // Trim the array to the max count
        if recentIDs.count > maxCount {
            recentIDs = Array(recentIDs.prefix(maxCount))
        }

        UserDefaults.standard.set(recentIDs, forKey: key)
    }

    func removeRecentSource(id: String) {
        var recentIDs = getRecentSourceIDs()
        recentIDs.removeAll { $0 == id }
        UserDefaults.standard.set(recentIDs, forKey: key)
    }
}