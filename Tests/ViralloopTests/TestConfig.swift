//
//  TestConfig.swift
//  viralloop
//
//  Created by Bechir Arfaoui on 15.01.25.
//

import Foundation

enum TestConfig {
    static var apiKey: String {
        guard let apiKey = ProcessInfo.processInfo.environment["VIRALLOOP_TEST_API_KEY"] else {
            fatalError("VIRALLOOP_TEST_API_KEY environment variable not set")
        }
        return apiKey
    }
    
    static var appId: String {
        guard let appId = ProcessInfo.processInfo.environment["VIRALLOOP_TEST_APP_ID"] else {
            fatalError("VIRALLOOP_TEST_APP_ID environment variable not set")
        }
        return appId
    }
}
