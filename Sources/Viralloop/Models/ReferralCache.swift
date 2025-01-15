//
//  ReferralCache.swift
//  viralloop
//
//  Created by Bechir Arfaoui on 15.01.25.
//

import Foundation

internal struct ReferralCache {
    let status: ReferralStatus
    let timestamp: Date
    
    var isValid: Bool {
        // Cache valid for 5 minutes
        return Date().timeIntervalSince(timestamp) < 300
    }
}
