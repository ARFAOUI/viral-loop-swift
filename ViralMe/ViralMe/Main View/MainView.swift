//
//  MainView.swift
//  ViralMe
//
//  Created by Bechir Arfaoui on 16.01.25.
//

import SwiftUI
import Viralloop

struct MainView: View {
    @State private var shouldShowPaywall = false
    @State private var showInviteModal = false
    @State private var showOnboarding = false
    
    var inviteCode: String? {
        // Retrieve the invite code from ViralloopClient
        ViralloopClient.shared().getReferralCodeFromStorage()
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to ViralMe!")
                    .font(.largeTitle)
                    .padding()

                Spacer()

                // Show Invite Friends Button only if inviteCode exists
                if inviteCode != nil {
                    Button(action: {
                        inviteFriends()
                    }) {
                        Text("Invite Friends to Unlock Reward")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .sheet(isPresented: $showInviteModal) {
                        InviteModalView()
                            .presentationDetents([.fraction(0.5)]) // Half-height modal
                            .presentationDragIndicator(.visible) // Show drag indicator
                    }
                }

                // Upgrade to Premium Button
                Button(action: {
                    displayPaywall()
                }) {
                    Text("Upgrade to Premium")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .navigationBarTitle("ViralMe", displayMode: .inline)
            .alert(isPresented: $shouldShowPaywall) { // Present the alert
                paywallAlert()
            }
        }
    }

    private func inviteFriends() {
        // Add your invitation logic here, such as opening a share sheet
        print("Invite Friends button tapped")
        showInviteModal = true
    }

    private func displayPaywall() {
        shouldShowPaywall = true
    }

    private func paywallAlert() -> Alert {
        Alert(
            title: Text("Upgrade to Premium"),
            message: Text("Display your paywall here :)"),
            dismissButton: .default(Text("OK"))
        )
    }
}
