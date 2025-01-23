//
//  SecureStorage.swift
//  Viralloop
//
//  Created by Bechir Arfaoui on 22.01.25.
//
import Foundation

enum ViralloopKeychainConstants {
    static let service = "com.viralloop.secure"
    
    enum Account {
        static let userId = "userId"
        static let referralCode = "referralCode"
        static let deviceFingerprint = "deviceFingerprint"
        static let installationHistory = "installationHistory"
    }
}

class SecureStorage {
    private let keychain = KeychainManager.shared
    
    func saveUserId(_ userId: String) throws {
        do {
            guard let data = userId.data(using: .utf8) else {
                throw KeychainError.invalidItemFormat
            }
            try keychain.save(
                data,
                service: ViralloopKeychainConstants.service,
                account: ViralloopKeychainConstants.Account.userId
            )
        } catch let error {
            Logger.error("Failed to save userId to Keychain: \(error)")
            // Fallback to UserDefaults if Keychain fails
            UserDefaults.standard.set(userId, forKey: "com.viralloop.userId")
            throw error
        }
    }
    
    func getUserId() throws -> String? {
        do {
            let data = try keychain.retrieve(
                service: ViralloopKeychainConstants.service,
                account: ViralloopKeychainConstants.Account.userId
            )
            guard let string = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidItemFormat
            }
            return string
        } catch {
            // Try to get from UserDefaults as fallback
            if let userId = UserDefaults.standard.string(forKey: "com.viralloop.userId") {
                return userId
            }
            throw error
        }
    }
    
    // MARK: - Installation History
    struct InstallationRecord: Codable {
        let timestamp: Date
        let deviceFingerprint: String
        let referralCode: String?
    }
    
    func recordInstallation(deviceFingerprint: String, referralCode: String?) throws {
        var history = (try? retrieveInstallationHistory()) ?? []
        let newRecord = InstallationRecord(
            timestamp: Date(),
            deviceFingerprint: deviceFingerprint,
            referralCode: referralCode
        )
        history.append(newRecord)
        
        let data = try JSONEncoder().encode(history)
        try keychain.save(
            data,
            service: ViralloopKeychainConstants.service,
            account: ViralloopKeychainConstants.Account.installationHistory
        )
    }
    
    func retrieveInstallationHistory() throws -> [InstallationRecord] {
        do {
            let data = try keychain.retrieve(
                service: ViralloopKeychainConstants.service,
                account: ViralloopKeychainConstants.Account.installationHistory
            )
            return try JSONDecoder().decode([InstallationRecord].self, from: data)
        } catch KeychainError.itemNotFound {
            return []
        } catch {
            Logger.error("Failed to retrieve installation history: \(error)")
            return []
        }
    }
    
    func saveReferralCode(_ code: String) throws {
        guard let data = code.data(using: .utf8) else { throw KeychainError.invalidItemFormat }
        try keychain.save(data, service: ViralloopKeychainConstants.service, account: ViralloopKeychainConstants.Account.referralCode)
    }
    
    func getReferralCode() throws -> String? {
        do {
            let data = try keychain.retrieve(service: ViralloopKeychainConstants.service, account: ViralloopKeychainConstants.Account.referralCode)
            return String(data: data, encoding: .utf8)
        } catch KeychainError.itemNotFound {
            return UserDefaults.standard.string(forKey: "com.viralloop.referralCode")
        }
    }
}
