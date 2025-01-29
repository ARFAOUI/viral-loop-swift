//
//  ViralloopModels.swift
//  viralloop
//
//  Created by Bechir Arfaoui on 15.01.25.
//

import Foundation
import Network

internal struct User: Codable {
    let externalUserId: String
    let deviceType: String
    let deviceBrand: String
    let deviceModel: String
    let operatingSystem: String
    let osVersion: String
    let appVersion: String
    let appBuildNumber: String
    let isPaidUser: Bool
    let lifetimeValueUsd: Double
    let referralCode: String?
    let countryCode: String
    let connectivity: String
    let deviceLanguage: String
    let timezone: String
    let firstReferralSource: String?
    let attributionSource: String?
    
    enum CodingKeys: String, CodingKey {
        case externalUserId
        case deviceType
        case deviceBrand
        case deviceModel
        case operatingSystem
        case osVersion
        case appVersion
        case appBuildNumber
        case isPaidUser
        case lifetimeValueUsd
        case referralCode
        case countryCode
        case connectivity
        case deviceLanguage
        case timezone
        case firstReferralSource
        case attributionSource
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        externalUserId = try container.decode(String.self, forKey: .externalUserId)
        deviceType = try container.decode(String.self, forKey: .deviceType)
        deviceBrand = try container.decode(String.self, forKey: .deviceBrand)
        deviceModel = try container.decode(String.self, forKey: .deviceModel)
        operatingSystem = try container.decode(String.self, forKey: .operatingSystem)
        osVersion = try container.decode(String.self, forKey: .osVersion)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        isPaidUser = try container.decode(Bool.self, forKey: .isPaidUser)
        referralCode = try container.decodeIfPresent(String.self, forKey: .referralCode)
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode) ?? "unknown"
        connectivity = try container.decodeIfPresent(String.self, forKey: .connectivity) ?? "unknown"
        deviceLanguage = try container.decodeIfPresent(String.self, forKey: .deviceLanguage) ?? "unknown"
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone) ?? "unknown"
        firstReferralSource = try container.decodeIfPresent(String.self, forKey: .firstReferralSource)
        attributionSource = try container.decodeIfPresent(String.self, forKey: .attributionSource)
        
        // Robust decoding for lifetimeValueUsd
        if let doubleValue = try? container.decode(Double.self, forKey: .lifetimeValueUsd) {
            lifetimeValueUsd = doubleValue
        } else if let stringValue = try? container.decode(String.self, forKey: .lifetimeValueUsd),
                  let convertedValue = Double(stringValue) {
            lifetimeValueUsd = convertedValue
        } else {
            lifetimeValueUsd = 0.0
            Logger.warning("Could not decode lifetimeValueUsd. Defaulting to 0.0")
        }
        
        // Robust decoding for appBuildNumber
        if let intValue = try? container.decode(Int.self, forKey: .appBuildNumber) {
            appBuildNumber = String(intValue)
        } else if let stringValue = try? container.decode(String.self, forKey: .appBuildNumber) {
            appBuildNumber = stringValue
        } else {
            appBuildNumber = "0"
            Logger.warning("Could not decode appBuildNumber. Defaulting to '0'")
        }
    }
    
    // Default initializer for creating User instances
    public init(
        externalUserId: String,
        deviceType: String,
        deviceBrand: String,
        deviceModel: String,
        operatingSystem: String,
        osVersion: String,
        appVersion: String,
        appBuildNumber: String,
        isPaidUser: Bool,
        lifetimeValueUsd: Double,
        referralCode: String? = nil,
        countryCode: String = "unknown",
        connectivity: String = "unknown",
        deviceLanguage: String = "unknown",
        timezone: String = "unknown",
        firstReferralSource: String? = nil,
        attributionSource: String? = nil
    ) {
        self.externalUserId = externalUserId
        self.deviceType = deviceType
        self.deviceBrand = deviceBrand
        self.deviceModel = deviceModel
        self.operatingSystem = operatingSystem
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.appBuildNumber = appBuildNumber
        self.isPaidUser = isPaidUser
        self.lifetimeValueUsd = lifetimeValueUsd
        self.referralCode = referralCode
        self.countryCode = countryCode
        self.connectivity = connectivity
        self.deviceLanguage = deviceLanguage
        self.timezone = timezone
        self.firstReferralSource = firstReferralSource
        self.attributionSource = attributionSource
    }
}

public struct ReferralStatus: Codable {
    public let activeReferrals: Int
    public let requiredInvitations: Int
    public let remainingInvitations: Int
    public let isComplete: Bool
    public let referralCode: String
    
    // Custom coding keys to match the JSON structure
    enum CodingKeys: String, CodingKey {
        case activeReferrals
        case requiredInvitations
        case remainingInvitations
        case isComplete
        case referralCode
    }
    
    // Custom initializer to handle nested JSON and type conversions
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle activeReferrals as a string
        if let stringValue = try? container.decode(String.self, forKey: .activeReferrals) {
            activeReferrals = Int(stringValue) ?? 0
        } else {
            activeReferrals = try container.decode(Int.self, forKey: .activeReferrals)
        }
        
        requiredInvitations = try container.decode(Int.self, forKey: .requiredInvitations)
        remainingInvitations = try container.decode(Int.self, forKey: .remainingInvitations)
        isComplete = try container.decode(Bool.self, forKey: .isComplete)
        referralCode = try container.decode(String.self, forKey: .referralCode)
    }
}

public struct ReferralStatusResponse: Codable {
    public let referralStatus: ReferralStatus
}

internal struct ReferralSubmission: Codable {
    let referralCode: String
}

internal struct UserUpdate: Codable {
    let isPaidUser: Bool
    let lifetimeValueUsd: Double
}

internal struct AttributionUpdate: Codable {
    let firstReferralSource: String?
    let attributionSource: String?
}

public struct APIError: Codable {
    public let error: String
    public let message: String?
    
    public init(error: String, message: String?) {
        self.error = error
        self.message = message
    }
}

struct UserResponse: Codable {
    let user: User
}

public struct ReferralSubmissionResponse: Codable {
    public let success: Bool
    public let relationship: Relationship
}

public struct Relationship: Codable {
    public let id: Int
    public let status: String
    public let activationDate: String
    
    public init(id: Int, status: String, activationDate: String) {
        self.id = id
        self.status = status
        self.activationDate = activationDate
    }
}

public enum ViralloopError: Error {
    case invalidResponse
    case apiError(message: String)
    case notConfigured
    case userNotInitialized
    case encodingError
    case noData
    case unknownError
    case decodingError(message: String)
}

struct APIErrorResponse: Codable {
    let message: String
}

internal struct UserDailyUpdate: Codable {
    let deviceType: String
    let deviceBrand: String
    let deviceModel: String
    let operatingSystem: String
    let osVersion: String
    let appVersion: String
    let appBuildNumber: String
    let countryCode: String
    let connectivity: String
    let deviceLanguage: String
    let timezone: String
}

struct InstallationRecord: Codable {
    let timestamp: Date
    let deviceFingerprint: String
    let referralCode: String?
}


