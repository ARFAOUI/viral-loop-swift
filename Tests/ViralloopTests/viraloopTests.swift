//
//  TestConfig.swift
//  viralloop
//
//  Created by Bechir Arfaoui on 15.01.25.
//

import XCTest
@testable import viralloop

final class ViralloopTests: XCTestCase {
    override func setUp() {
        super.setUp()
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        ViralloopClient.sharedInstance = nil
    }
    
    func testClientInitialization() {
        // Configure the client with env variables
        ViralloopClient.configure(
            apiKey: TestConfig.apiKey,
            appId: TestConfig.appId
        )
        
        let client = ViralloopClient.shared()
        XCTAssertNotNil(client)
    }
    
    func testDoubleConfiguration() {
        // First configuration
        ViralloopClient.configure(
            apiKey: TestConfig.apiKey,
            appId: TestConfig.appId
        )
        let firstClient = ViralloopClient.shared()
        
        // Second configuration should be ignored
        ViralloopClient.configure(
            apiKey: "different_key",
            appId: "different_app"
        )
        let secondClient = ViralloopClient.shared()
        
        XCTAssertEqual(ObjectIdentifier(firstClient), ObjectIdentifier(secondClient))
    }
    
    // ... rest of your tests
}
