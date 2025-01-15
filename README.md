# Viralloop

A Swift package for integrating Viralloop referral system.

## Installation

Add this package to your Xcode project using Swift Package Manager:

1. File > Add Packages...
2. Enter the package URL: `[https://github.com/yourusername/viralloop.git](https://github.com/ARFAOUI/viral-loop-swift.git)`

## Usage

Initialize the client early in your app lifecycle:

```swift
ViralloopClient.configure(
    apiKey: "your_api_key",
    appId: "your_app_id"
)

// Get referral status
try? ViralloopClient.shared().getReferralStatus { result in
    switch result {
    case .success(let status):
        print("Total referrals: \(status.totalReferrals)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
