//
//  Untitled 3.swift
//  ViralMe
//
//  Created by Bechir Arfaoui on 16.01.25.
//
//

import SwiftUI
import Viralloop

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var referralCode = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var isMainViewPresented = false
    @State private var showErrorAlert = false // State to manage error alert
    @State private var errorMessage = "" // Message for the alert
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                TabView(selection: $currentPage) {
                    // Screen 1
                    OnboardingPage(
                        title: "Welcome to ViralMe",
                        description: nil,
                        content: nil,
                        buttonTitle: "Continue",
                        action: { nextPage() }
                    )
                    .tag(0)

                    // Screen 2
                    OnboardingPage(
                        title: "Why ViralMe?",
                        description: nil,
                        content: AnyView(
                            VStack(alignment: .leading, spacing: 10) {
                                Text("• Grow your network like never before.")
                                Text("• Earn rewards for every referral.")
                                Text("• Track your progress seamlessly.")
                            }
                            .font(.headline)
                            .foregroundColor(.secondary)
                        ),
                        buttonTitle: "Continue",
                        action: { nextPage() }
                    )
                    .tag(1)

                    // Screen 3
                    OnboardingPage(
                        title: "Do you have a referral code?",
                        description: nil,
                        content: AnyView(
                            VStack {
                                TextField("Enter your referral code", text: $referralCode)
                                    .focused($isTextFieldFocused)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                                if referralCode.count > 0 && referralCode.count < 6 {
                                    Text("Referral code must be 6 characters or more.")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                        ),
                        buttonTitle: "Submit",
                        action: { submitReferralCode() }
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: currentPage == 2 ? Button("Skip") {
                           completeOnboarding()
            } : nil)
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Submission"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func nextPage() {
        if currentPage < 2 {
            currentPage += 1
        }
    }

    private func submitReferralCode() {
        guard referralCode.count >= 6 else {
            errorMessage = "Referral code must be at least 6 characters."
            showErrorAlert = true
            return
        }

        ViralloopClient.shared().submitReferralCode(referralCode) { result in
            switch result {
            case .success:
                // Display success message and dismiss the view
                DispatchQueue.main.async {
                    errorMessage = "Referral code submitted successfully!"
                    showErrorAlert = true // Trigger alert for success message

                    // Dismiss the view after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Delay for user to see the message
                        completeOnboarding()
                    }
                }
            case .failure(let error):
                // Show an alert with the error message
                if case let ViralloopError.apiError(message) = error {
                    print("API Error: \(message)")
                    DispatchQueue.main.async {
                        errorMessage = message
                        showErrorAlert = true
                    }
                } else {
                    print("Other error: \(error)")
                }
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        isMainViewPresented = true
    }
}
