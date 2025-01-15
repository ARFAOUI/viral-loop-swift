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
    let appBuildNumber: Int
    var isPaidUser: Bool
    var lifetimeValueUsd: Double
    let referralCode: String?
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
