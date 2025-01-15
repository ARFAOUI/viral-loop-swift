# Viralloop - Refferal code system for viral Apps

A Swift package for integrating Viralloop referral system.

## Installation

Add this package to your Xcode project using Swift Package Manager:

1. File > Add Packages...
2. Enter the package URL: https://github.com/ARFAOUI/viral-loop-swift.git

# Viralloop iOS SDK

## Installation

(Add your preferred installation method here, e.g., CocoaPods, Swift Package Manager)

## Core Methods

### 1. Configure SDK
```swift
ViralloopClient.configure(apiKey: "YOUR_API_KEY", appId: "YOUR_APP_ID")
```
- **Description**: Initialize the Viralloop SDK
- **Required**: Must be called before using any other SDK methods
- **Parameters**:
  - `apiKey`: Your unique Viralloop API key
  - `appId`: Your application identifier
  - `logLevel`: Optional logging level (default: .info)

### 2. Submit Referral Code
- **Typical Use Case**: Verify user's referral code before sharing with friends
  - Confirm a referral code is generated
  - Validate code availability before initiating friend invitations
  - Prepare sharing mechanisms (social media, messaging, etc.)

```swift
ViralloopClient.shared().submitReferralCode("REFERRAL_CODE") { result in
    switch result {
    case .success(let status):
        // Referral code submitted successfully
    case .failure(let error):
        // Handle submission error
    }
}
```
- **Description**: Submit a referral code for the current user
- **Actions**: 
  - Validates referral code
  - Updates user's referral status
  - Clears cached referral status

### 3. Check Referral Code Existence
- **Typical Use Case**: Verify user's referral code before sharing with friends
  - Confirm a referral code is generated
  - Validate code availability before initiating friend invitations
  - Prepare sharing mechanisms (social media, messaging, etc.)

```swift
let hasReferralCode = ViralloopClient.shared().hasReferralCodeInStorage
if hasReferralCode {
    // User has a referral code
    // Proceed with friend invitation flow
    let referralCode = ViralloopClient.shared().getReferralCodeFromStorage()
    // you can show you code in the UI here
} else {
    // Handle scenario without a referral code
    // Potentially request code generation or show error
}
```
- **Description**: Check if a personal referral code is available in offline storage
- **Recommended Workflow**:
  - Verify referral code existence before sharing
  - Implement fallback strategies if no code is available
  - Ensure smooth referral invitation process

### 4. Read Referral Code
```swift
if let referralCode = ViralloopClient.shared().getReferralCodeFromStorage() {
    // Use the referral code
}
```
- **Description**: Retrieve referral code from offline storage
- **Returns**: Referral code as an optional string

### 5. Get Referral Status
```swift
ViralloopClient.shared().getReferralStatus { result in
    switch result {
    case .success(let status):
        // Number of users joined using his code
        print("Total Referrals: \(status.activeReferrals)") 
        // Number invitation required left to match the reward condition
        print("Pending Rewards: \(status.remainingInvitations)") 
        // This is the required number of invitation required by app
        print("Redeemed Rewards: \(status.requiredInvitations)")
    case .failure(let error):
        // Handle error
        print("Error fetching referral status: \(error)")
    }
}
```
- **Description**: Retrieves current user's referral status
- **Caching**: Supports local caching of referral status

### 6. Redeem Rewards
```swift
ViralloopClient.shared().redeemRewards {
    result in
        switch result {
            case.success(let status):
                // Handle reward redemption -> offer the reward to the user
                // our already applied the reward in our servers and set the invitation to redeemed.
                // for example if the required invitations count is 3 and the user invited 5, we redeem 3 and we keep 2 available once the total 3 is met again we can redeem him again.
                // this scenario is usefull if you have a game and you want to offer coins for each x friends.
                print("redeemed rewards: \(status)")
            case.failure(let error):
                // Handle redemption error
                print("Error fetching referral status: \(error)")
        }
}
```
- **Description**: Allows user to redeem accumulated referral rewards

## Optional Methods

### 1. Update Lifetime Value (LTV)
```swift
ViralloopClient.shared().updateLifetimeValue(100.50) {
    result in
        switch result {
            case.success:
                // Lifetime value updated successfully
                print("Lifetime value updated successfully")
            case.failure(let error):
                // Handle update error
                print("Error updateLifetimeValue: \(error)")
        }
}
```
- **Description**: Updates user's lifetime value in USD
- **Parameters**: 
  - `lifetimeValue`: Double representing total user value
- **Use Cases**:
  - Track total purchases
  - Update user's monetary contribution
  - Segment users based on spend

### 2. Update Paid User Status
```swift
ViralloopClient.shared().updatePaidStatus(true) {
    result in
        switch result {
            case.success:
                // Paid status updated successfully
                print("Paid status updated successfully")
            case.failure(let error):
                // Handle update error
                print("Error updatePaidStatus: \(error)")
        }
}
```
- **Description**: Updates user's paid subscription status
- **Parameters**: 
  - `isPaid`: Boolean indicating paid status

## Error Handling

The SDK provides detailed error types:
- `invalidResponse`: Invalid server response
- `apiError`: Specific API-related errors
- `notConfigured`: SDK not properly initialized
- `userNotInitialized`: User data not set up
- `encodingError`: JSON encoding failed
- `noData`: No data received from server
- `unknownError`: Unspecified error

## Logging

The SDK includes a logging mechanism with different log levels:
- `.debug`: Detailed information
- `.info`: General information
- `.warning`: Potential issues
- `.error`: Critical errors

## Requirements
- iOS 13.0+
- Swift 5.3+

## License
(Add your license information)

## Support
For any issues or questions, please contact [Your Support Email/Channel]
