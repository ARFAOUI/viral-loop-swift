//
//  ViralloopModels.swift
//  viralloop
//
//  Created by Bechir Arfaoui on 15.01.25.
//

import Foundation

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
        referralCode: String? = nil
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
    }
}
public struct ReferralStatus: Codable {
    public let totalReferrals: Int
    public let pendingRewards: Double
    public let redeemedRewards: Double
}

internal struct ReferralSubmission: Codable {
    let referralCode: String
}

internal struct UserUpdate: Codable {
    let isPaidUser: Bool
    let lifetimeValueUsd: Double
}


public struct APIError: Codable {
    public let error: String
    public let message: String?
    
    public init(error: String, message: String?) {
        self.error = error
        self.message = message
    }
}
