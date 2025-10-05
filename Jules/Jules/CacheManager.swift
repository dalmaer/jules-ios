//
//  CacheManager.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import Foundation

class CacheManager {
    static let shared = CacheManager()

    private let sourceCache = NSCache<NSString, NSData>()
    private let sessionCache = NSCache<NSString, NSData>()

    private init() {}

    // MARK: - Cache Keys
    private func sourcesCacheKey() -> NSString {
        return "all_sources"
    }

    private func sessionsCacheKey(forSourceId sourceId: String) -> NSString {
        return "sessions_for_\(sourceId)" as NSString
    }

    // MARK: - Generic Caching
    private func set<T: Codable>(_ value: T, forKey key: NSString, in cache: NSCache<NSString, NSData>) {
        do {
            let data = try JSONEncoder().encode(value)
            cache.setObject(data as NSData, forKey: key)
            print("CACHE: 📝 Stored data for key '\(key)'")
        } catch {
            print("CACHE ERROR: ❌ Failed to encode data for key '\(key)': \(error)")
        }
    }

    private func get<T: Codable>(forKey key: NSString, from cache: NSCache<NSString, NSData>) -> T? {
        guard let data = cache.object(forKey: key) as Data? else {
            print("CACHE: 💨 MISS for key '\(key)'")
            return nil
        }

        do {
            let value = try JSONDecoder().decode(T.self, from: data)
            print("CACHE: ✅ HIT for key '\(key)'")
            return value
        } catch {
            print("CACHE ERROR: ❌ Failed to decode data for key '\(key)': \(error)")
            // Data is corrupt or model has changed, remove it
            cache.removeObject(forKey: key)
            return nil
        }
    }

    // MARK: - Public Interface for Sources
    func getSources() -> [Source]? {
        return get(forKey: sourcesCacheKey(), from: sourceCache)
    }

    func setSources(_ sources: [Source]) {
        set(sources, forKey: sourcesCacheKey(), in: sourceCache)
    }

    // MARK: - Public Interface for Sessions
    func getSessions(forSourceId sourceId: String) -> [Session]? {
        return get(forKey: sessionsCacheKey(forSourceId: sourceId), from: sessionCache)
    }

    func setSessions(_ sessions: [Session], forSourceId sourceId: String) {
        set(sessions, forKey: sessionsCacheKey(forSourceId: sourceId), in: sessionCache)
    }

    // MARK: - Cache Invalidation
    func invalidateSources() {
        print("CACHE: 🗑️ Invalidating all sources.")
        sourceCache.removeObject(forKey: sourcesCacheKey())
    }

    func invalidateSessions(forSourceId sourceId: String) {
        print("CACHE: 🗑️ Invalidating sessions for source: \(sourceId)")
        sessionCache.removeObject(forKey: sessionsCacheKey(forSourceId: sourceId))
    }

    func invalidateAll() {
        print("CACHE: 💥 Invalidating all caches.")
        sourceCache.removeAllObjects()
        sessionCache.removeAllObjects()
    }
}