//
//  ViralMeApp.swift
//  ViralMe
//
//  Created by Bechir Arfaoui on 15.01.25.
//

import SwiftUI

@main
struct ViralMeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainView() // Replace with your main view
            } else {
                OnboardingView()
            }
        }
    }
}
