//
//  Storage.swift
//  viralloop
//
//  Created by Bechir Arfaoui on 15.01.25.
//

import Foundation

internal enum Storage {
    private static let userIdKey = "com.viralloop.userId"
    private static let referralCodeKey = "com.viralloop.referralCode"
    private static let lastUpdateKey = "com.viralloop.lastUpdate"
    private static var referralStatusCache: ReferralCache?
    
    static func getLastUpdate() -> Date? {
        return UserDefaults.standard.object(forKey: lastUpdateKey) as? Date
    }
    
    static func saveLastUpdate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastUpdateKey)
        
    }
    
    static func saveUserId(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: userIdKey)
    }
    
    static func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: userIdKey)
    }
    
    static func saveReferralCode(_ code: String) {
        UserDefaults.standard.set(code, forKey: referralCodeKey)
    }
    
    static func getReferralCode() -> String? {
        return UserDefaults.standard.string(forKey: referralCodeKey)
    }
    
    static func cacheReferralStatus(_ status: ReferralStatus) {
        referralStatusCache = ReferralCache(status: status, timestamp: Date())
    }
    
    static func getCachedReferralStatus() -> ReferralStatus? {
        guard let cache = referralStatusCache, cache.isValid else {
            return nil
        }
        return cache.status
    }
    
    static func clearReferralStatusCache() {
        referralStatusCache = nil
    }
}
