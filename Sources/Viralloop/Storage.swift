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
    private static let secureStorage = SecureStorage()
    private static let lastUserUpdateKey = "com.viralloop.lastUserUpdate"
    
    static func getLastUserUpdate() -> Date? {
         return UserDefaults.standard.object(forKey: lastUserUpdateKey) as? Date
     }
     
     static func saveLastUserUpdate(_ date: Date) {
         UserDefaults.standard.set(date, forKey: lastUserUpdateKey)
     }
    
    static func getLastUpdate() -> Date? {
        return UserDefaults.standard.object(forKey: lastUpdateKey) as? Date
    }
    
    static func saveLastUpdate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastUpdateKey)
        
    }
    
    static func saveUserId(_ userId: String) {
       // UserDefaults.standard.set(userId, forKey: userIdKey)
        try? secureStorage.saveUserId(userId)
    }
    
    static func getUserId() -> String? {
        try? secureStorage.getUserId()
    }
    
    static func saveReferralCode(_ code: String) {
        try? secureStorage.saveReferralCode(code)
        UserDefaults.standard.set(code, forKey: referralCodeKey) // Keep for backwards compatibility
    }
    
    static func getReferralCode() -> String? {
        if let code = try? secureStorage.getReferralCode() {
            return code
        }
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
