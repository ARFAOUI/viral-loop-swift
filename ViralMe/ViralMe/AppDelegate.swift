//
//  AppDelegate.swift
//  ViralMe
//
//  Created by Bechir Arfaoui on 15.01.25.
//
import Foundation
import UIKit
import Viralloop

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(  _ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        #warning ("update your API key and App id before compiling!")
        ViralloopClient.configure(apiKey: "8def_test_key_6f43bfbe5ac5", appId: "8def", logLevel: .debug)
        
        // Perform any app setup here
        print("App has launched.")
        return true
    }

    // Add other delegate methods if needed, like push notifications, background tasks, etc.
}
