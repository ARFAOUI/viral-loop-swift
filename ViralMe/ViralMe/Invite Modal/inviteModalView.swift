//
//  inviteModalView.swift
//  ViralMe
//
//  Created by Bechir Arfaoui on 16.01.25.
//
import SwiftUI
import Viralloop

struct InviteModalView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var copied = false
    @State private var isRedeemEnabled = false
    @State private var showDisabledAlert = false // State to manage disabled button alert
    @State private var inviteStatus: ReferralStatus? = nil // Store referral status
    let inviteCode = ViralloopClient.shared().getReferralCodeFromStorage() ?? "N/A"

    var body: some View {
        VStack {
            // Reserved Space for Redeem Button
            HStack {
                Spacer() // Keep this to push other content to the right
                Button(action: {
                    if isRedeemEnabled {
                        print("Redeem reward action triggered")
                    } else {
                        showDisabledAlert = true // Show alert when conditions are not met
                    }
                }) {
                    Text("Redeem")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(isRedeemEnabled ? Color.green : Color.gray)
                        .cornerRadius(10)
                }
                .frame(height: 44) // Explicit height to reserve space
                .alert(isPresented: $showDisabledAlert) {
                    let remainingInvitations = inviteStatus?.remainingInvitations ?? 0
                    return Alert(
                        title: Text("Requirement Not Met"),
                        message: Text("You need \(remainingInvitations) more invitations to redeem your reward."),
                        dismissButton: .default(Text("OK"))
                    )
                }

               
            }
            .padding(.horizontal)

            Spacer()

            // Title
            Text("Share your invite code")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.bottom, 4)

            // Subtitle
            Text("Invite 3 friends to unlock 1 Month Premium free, 100 coins, and remove ads")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            // Invite Code Area
            HStack {
                Text(inviteCode)
                    .font(.title2)
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(12)

                Button(action: {
                    UIPasteboard.general.string = inviteCode
                    copied = true
                }) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(8)
                }
                .alert(isPresented: $copied) {
                    Alert(
                        title: Text("Copied"),
                        message: Text("Invite code copied to clipboard"),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .padding(.horizontal)

            Spacer()

            // Share Button
            Button(action: {
                presentationMode.wrappedValue.dismiss()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let shareMessage = "Check out ViralMe! Use my code \(inviteCode) to unlock rewards: https://example.com/applink"

                    let activityVC = UIActivityViewController(activityItems: [shareMessage], applicationActivities: nil)

                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(activityVC, animated: true, completion: nil)
                    }
                }
            }) {
                Text("Share")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .onAppear(perform: fetchReferralStatus) // Fetch status on view load
    }

    private func fetchReferralStatus() {
        ViralloopClient.shared().getReferralStatus { result in
            switch result {
            case .success(let status):
                self.inviteStatus = status
                print("Total Referrals: \(status.activeReferrals)")
                print("Pending Rewards: \(status.remainingInvitations)")
                print("Redeemed Rewards: \(status.requiredInvitations)")

                // Enable or disable the redeem button based on the conditions
                DispatchQueue.main.async {
                    self.isRedeemEnabled = status.activeReferrals >= status.requiredInvitations
                }
            case .failure(let error):
                print("Error fetching referral status: \(error)")
            }
        }
    }
}
