//
//  Storage.swift
//  viralloop
//
//  Created by Bechir Arfaoui on 15.01.25.
//

import Foundation

public class ViralloopClient {
    // Shared instance
    // MARK: - Shared Instance Management
    static var sharedInstance: ViralloopClient?
    private let secureStorage = SecureStorage()
    private var firstReferralSource: String?
    private var attributionSource: String?
    private static let lock = NSLock()
     
     public static func configure(apiKey: String, appId: String, logLevel: LogLevel = .info) {
         lock.lock()
                defer { lock.unlock() }
                
                if sharedInstance != nil {
                    Logger.warning("ViralloopClient already configured. Ignoring new configuration.")
                    return
                }
                
                let instance = ViralloopClient(apiKey: apiKey, appId: appId, logLevel: logLevel)
                
                // Migrate old data when configuring for the first time
                instance.migrateFromUserDefaults()
                
                sharedInstance = instance
     }
    
    private func migrateFromUserDefaults() {
          if let oldUserId = UserDefaults.standard.string(forKey: "com.viralloop.userId") {
              do {
                  try secureStorage.saveUserId(oldUserId)
                  UserDefaults.standard.removeObject(forKey: "com.viralloop.userId")
                  Logger.info("Successfully migrated user ID to Keychain")
              } catch {
                  Logger.error("Failed to migrate user ID to Keychain: \(error)")
              }
          }
        
        // Migrate referralCode
            if let oldReferralCode = UserDefaults.standard.string(forKey: "com.viralloop.referralCode") {
                do {
                    try secureStorage.saveReferralCode(oldReferralCode)
                    Logger.info("Successfully migrated referral code to Keychain")
                } catch {
                    Logger.error("Failed to migrate referral code to Keychain: \(error)")
                }
            }
      }

     public static func shared() -> ViralloopClient {
         lock.lock()
         defer { lock.unlock() }
         
         guard let instance = sharedInstance else {  // Updated reference
             fatalError("ViralloopClient not configured. Call configure() first.")
         }
         
         return instance
     }

      // MARK: - Instance Properties
      private let apiKey: String
      private let appId: String
      private let session: URLSession
      private let baseURL = "https://tryviralloop.com"
      private var currentUser: User?
    
    
    private init(apiKey: String, appId: String, logLevel: LogLevel = .info) {
        self.apiKey = apiKey
        self.appId = appId
        self.session = URLSession.shared
        Logger.logLevel = logLevel
        Logger.info("Viralloop client initialized with appId: \(appId)")
        initializeUser()
    }
    // Method to get referral code from offline storage
     public func getReferralCodeFromStorage() -> String? {
         return Storage.getReferralCode()
     }
     
     // Property to check if referral code is available in storage
     public var hasReferralCodeInStorage: Bool {
         return Storage.getReferralCode() != nil
     }
    
    private func initializeUser() {
        // First check for existing UserDefaults data to migrate
        if let legacyUserId = UserDefaults.standard.string(forKey: "com.viralloop.userId") {
            do {
                // Try to migrate to Keychain
                try secureStorage.saveUserId(legacyUserId)
                // If successful, remove from UserDefaults
                UserDefaults.standard.removeObject(forKey: "com.viralloop.userId")
                Logger.info("Successfully migrated user ID from UserDefaults to Keychain: \(legacyUserId)")
            } catch {
                Logger.warning("Failed to migrate user ID to Keychain, will continue using UserDefaults: \(error)")
            }
        }

        do {
            if let existingUserId = try secureStorage.getUserId() {
                let deviceInfo = DeviceInfo.getDeviceInfo()
                let appInfo = DeviceInfo.getAppInfo()
                
                // Record this installation in secure storage
                do {
                    try secureStorage.recordInstallation(
                        deviceFingerprint: "\(deviceInfo.brand)-\(deviceInfo.model)-\(deviceInfo.deviceType)",
                        referralCode: nil
                    )
                } catch {
                    Logger.warning("Failed to record installation: \(error)")
                }
                
                // Check installation history for potential fraud
                if let history = try? secureStorage.retrieveInstallationHistory(),
                   history.count > 1 {
                    Logger.warning("Multiple installations detected: \(history.count)")
                }
                
                // Create initial user object
                currentUser = User(
                    externalUserId: existingUserId,
                    deviceType: deviceInfo.deviceType,
                    deviceBrand: deviceInfo.brand,
                    deviceModel: deviceInfo.model,
                    operatingSystem: deviceInfo.os,
                    osVersion: deviceInfo.osVersion,
                    appVersion: appInfo.version,
                    appBuildNumber: String(appInfo.buildNumber),
                    isPaidUser: false,
                    lifetimeValueUsd: 0.0,
                    referralCode: Storage.getReferralCode()
                )
                
                // Refresh user info from server
                updateUserIfNeeded()
                
                Logger.info("Existing user loaded: \(existingUserId)")
                return
            }
            
            // Initialize new user
            let deviceInfo = DeviceInfo.getDeviceInfo()
            let appInfo = DeviceInfo.getAppInfo()
            let userId = DeviceInfo.generateUserId()
            
            // Try to save to secure storage, fallback to UserDefaults
            do {
                try secureStorage.saveUserId(userId)
            } catch {
                Logger.warning("Failed to save to Keychain, falling back to UserDefaults: \(error)")
                UserDefaults.standard.set(userId, forKey: "com.viralloop.userId")
            }
            
            // Record first installation
            do {
                try secureStorage.recordInstallation(
                    deviceFingerprint: "\(deviceInfo.brand)-\(deviceInfo.model)-\(deviceInfo.deviceType)",
                    referralCode: nil
                )
            } catch {
                Logger.warning("Failed to record first installation: \(error)")
            }
            
            currentUser = User(
                externalUserId: userId,
                deviceType: deviceInfo.deviceType,
                deviceBrand: deviceInfo.brand,
                deviceModel: deviceInfo.model,
                operatingSystem: deviceInfo.os,
                osVersion: deviceInfo.osVersion,
                appVersion: appInfo.version,
                appBuildNumber: String(appInfo.buildNumber),
                isPaidUser: false,
                lifetimeValueUsd: 0.0,
                referralCode: nil
            )
            
            registerUser { [weak self] result in
                switch result {
                case .success(let registeredUser):
                    if let referralCode = registeredUser.referralCode {
                        Storage.saveReferralCode(referralCode)
                    }
                    self?.currentUser = registeredUser
                    Logger.info("New user registered: \(registeredUser.externalUserId)")
                case .failure(let error):
                    Logger.error("Failed to register user: \(error)")
                }
            }
        } catch {
            Logger.error("Failed to initialize user: \(error)")
            
            // Complete fallback to UserDefaults
            if let userId = UserDefaults.standard.string(forKey: "com.viralloop.userId") {
                let deviceInfo = DeviceInfo.getDeviceInfo()
                let appInfo = DeviceInfo.getAppInfo()
                
                currentUser = User(
                    externalUserId: userId,
                    deviceType: deviceInfo.deviceType,
                    deviceBrand: deviceInfo.brand,
                    deviceModel: deviceInfo.model,
                    operatingSystem: deviceInfo.os,
                    osVersion: deviceInfo.osVersion,
                    appVersion: appInfo.version,
                    appBuildNumber: String(appInfo.buildNumber),
                    isPaidUser: false,
                    lifetimeValueUsd: 0.0,
                    referralCode: Storage.getReferralCode()
                )
                
                // Also refresh user info in fallback case
                makeRequest("users/\(userId)", method: "GET") { [weak self] (result: Result<User, Error>) in
                    switch result {
                    case .success(let user):
                        self?.currentUser = user
                        if let referralCode = user.referralCode {
                            Storage.saveReferralCode(referralCode)
                        }
                        Logger.info("Refreshed existing user info (UserDefaults): \(userId)")
                    case .failure(let error):
                        Logger.error("Failed to refresh user info (UserDefaults): \(error)")
                    }
                }
                
                Logger.info("Initialized user from UserDefaults: \(userId)")
            } else {
                // Create new user with UserDefaults as last resort
                let userId = DeviceInfo.generateUserId()
                UserDefaults.standard.set(userId, forKey: "com.viralloop.userId")
                
                let deviceInfo = DeviceInfo.getDeviceInfo()
                let appInfo = DeviceInfo.getAppInfo()
                
                currentUser = User(
                    externalUserId: userId,
                    deviceType: deviceInfo.deviceType,
                    deviceBrand: deviceInfo.brand,
                    deviceModel: deviceInfo.model,
                    operatingSystem: deviceInfo.os,
                    osVersion: deviceInfo.osVersion,
                    appVersion: appInfo.version,
                    appBuildNumber: String(appInfo.buildNumber),
                    isPaidUser: false,
                    lifetimeValueUsd: 0.0,
                    referralCode: nil,
                    countryCode: Locale.current.regionCode ?? "unknown",
                    connectivity: DeviceInfo.getCurrentConnectivity(),
                    deviceLanguage: Locale.current.languageCode ?? "unknown",
                    timezone: TimeZone.current.identifier,
                    firstReferralSource: self.firstReferralSource,
                    attributionSource: self.attributionSource
                )
                
                Logger.info("Created new user with UserDefaults: \(userId)")
                
                registerUser { [weak self] result in
                    switch result {
                    case .success(let registeredUser):
                        if let referralCode = registeredUser.referralCode {
                            Storage.saveReferralCode(referralCode)
                        }
                        self?.currentUser = registeredUser
                        Logger.info("New user registered (UserDefaults fallback): \(registeredUser.externalUserId)")
                    case .failure(let error):
                        Logger.error("Failed to register user (UserDefaults fallback): \(error)")
                    }
                }
            }
        }
    }


    // Private register method
    private func registerUser(completion: @escaping (Result<User, Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(ViralloopError.userNotInitialized))
            return
        }
        
        guard let data = try? JSONEncoder().encode(user) else {
            completion(.failure(ViralloopError.encodingError))
            return
        }
        
        makeRequest("users", method: "POST", body: data, completion: completion)
    }
    
    private func updateAttributionData(userId: String) {
         let update = AttributionUpdate(
             firstReferralSource: firstReferralSource,
             attributionSource: attributionSource
         )
         
         guard let data = try? JSONEncoder().encode(update) else {
             Logger.error("Failed to encode attribution update")
             return
         }
         
         makeRequest("users/\(userId)/attribution", method: "PUT", body: data) { (result: Result<User, Error>) in
             switch result {
             case .success(let user):
                 self.currentUser = user
                 Logger.info("Attribution data updated successfully")
             case .failure(let error):
                 Logger.error("Failed to update attribution data: \(error)")
             }
         }
     }
    
    // MARK: - Public Methods
    
    public func setAttributionData(firstReferralSource: String?, attributionSource: String?) {
          self.firstReferralSource = firstReferralSource
          self.attributionSource = attributionSource
          
          // If user is already initialized, update the server
          if let userId = currentUser?.externalUserId {
              updateAttributionData(userId: userId)
          }
      }
    
    public func getReferralStatus(completion: @escaping (Result<ReferralStatus, Error>) -> Void) {
        if let cachedStatus = Storage.getCachedReferralStatus() {
            Logger.debug("Using cached referral status")
            completion(.success(cachedStatus))
            return
        }
        
        guard let userId = currentUser?.externalUserId else {
            completion(.failure(ViralloopError.userNotInitialized))
            return
        }
        
        makeRequest("users/\(userId)/referral-status") { (result: Result<ReferralStatusResponse, Error>) in
            switch result {
            case .success(let response):
                let status = response.referralStatus
                Storage.cacheReferralStatus(status)
                completion(.success(status))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func submitReferralCode(_ code: String, completion: @escaping (Result<ReferralSubmissionResponse, Error>) -> Void) {
        guard let userId = currentUser?.externalUserId else {
            completion(.failure(ViralloopError.userNotInitialized))
            return
        }
        
        let submission = ReferralSubmission(referralCode: code)
        guard let data = try? JSONEncoder().encode(submission) else {
            completion(.failure(ViralloopError.encodingError))
            return
        }
        
        makeRequest("users/\(userId)/submit-referral", method: "POST", body: data, completion: completion)
    }
    
    public func updatePaidStatus(_ isPaid: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = currentUser?.externalUserId else {
            completion(.failure(ViralloopError.userNotInitialized))
            return
        }
        
        let update = UserUpdate(isPaidUser: isPaid, lifetimeValueUsd: currentUser?.lifetimeValueUsd ?? 0)
        guard let data = try? JSONEncoder().encode(update) else {
            completion(.failure(ViralloopError.encodingError))
            return
        }
        
        makeRequest("users/\(userId)", method: "PUT", body: data) { [weak self] (result: Result<User, Error>) in
            switch result {
            case .success(let user):
                self?.currentUser = user
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func redeemRewards(completion: @escaping (Result<ReferralStatus, Error>) -> Void) {
        Storage.clearReferralStatusCache()
        
        guard let userId = currentUser?.externalUserId else {
            completion(.failure(ViralloopError.userNotInitialized))
            return
        }
        
        makeRequest("users/\(userId)/redeem-rewards", method: "POST") { (result: Result<ReferralStatus, Error>) in
            switch result {
            case .success(let status):
                Storage.cacheReferralStatus(status)
                completion(.success(status))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func shouldUpdateToday() -> Bool {
        guard let lastUpdate = Storage.getLastUpdate() else {
            return true
        }
        return !Calendar.current.isDateInToday(lastUpdate)
    }

    private func updateUserIfNeeded() {
        guard let userId = currentUser?.externalUserId,
              shouldUpdateToday() else {
            return
        }
        
        let deviceInfo = DeviceInfo.getDeviceInfo()
        let appInfo = DeviceInfo.getAppInfo()
        
        let update = UserDailyUpdate(
            deviceType: deviceInfo.deviceType,
            deviceBrand: deviceInfo.brand,
            deviceModel: deviceInfo.model,
            operatingSystem: deviceInfo.os,
            osVersion: deviceInfo.osVersion,
            appVersion: appInfo.version,
            appBuildNumber: String(appInfo.buildNumber),
            countryCode: Locale.current.regionCode ?? "unknown",
            connectivity: DeviceInfo.getCurrentConnectivity(),
            deviceLanguage: Locale.current.languageCode ?? "unknown",
            timezone: TimeZone.current.identifier
        )
        
        guard let data = try? JSONEncoder().encode(update) else {
            Logger.error("Failed to encode daily update")
            return
        }
        
        makeRequest("users/\(userId)", method: "PUT", body: data) { (result: Result<User, Error>) in
               switch result {
               case .success(let user):
                   Storage.saveLastUpdate(Date())
                   Storage.saveLastUpdate(Date())
                     if let referralCode = user.referralCode {
                         Storage.saveReferralCode(referralCode)
                     }
                   Logger.info("Daily update successful")
               case .failure(let error):
                   Logger.error("Failed to send daily update: \(error)")
               }
           }
    }
    
    public func updateLifetimeValue(_ lifetimeValue: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = currentUser?.externalUserId else {
            completion(.failure(ViralloopError.userNotInitialized))
            return
        }
        
        let update = UserUpdate(
            isPaidUser: currentUser?.isPaidUser ?? false,
            lifetimeValueUsd: lifetimeValue
        )
        
        guard let data = try? JSONEncoder().encode(update) else {
            completion(.failure(ViralloopError.encodingError))
            return
        }
        
        makeRequest("users/\(userId)", method: "PUT", body: data) { [weak self] (result: Result<User, Error>) in
            switch result {
            case .success(let user):
                self?.currentUser = user
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Network Request Method
    
    private func makeRequest<T: Codable>(_ endpoint: String,
                                        method: String = "GET",
                                        body: Data? = nil,
                                        completion: @escaping (Result<T, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/apps/\(appId)/\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            // Pretty print request body
            if let json = try? JSONSerialization.jsonObject(with: body, options: []),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                Logger.debug("Request body for \(endpoint):\n\(prettyString)")
            } else {
                Logger.debug("Request body: \(String(data: body, encoding: .utf8) ?? "")")
            }
            request.httpBody = body
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(ViralloopError.invalidResponse))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(ViralloopError.noData))
                }
                return
            }
            
            // Pretty print response JSON
            if let json = try? JSONSerialization.jsonObject(with: data, options: []),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                Logger.debug("Response for \(endpoint):\n\(prettyString)")
            } else if let rawJsonString = String(data: data, encoding: .utf8) {
                Logger.debug("Raw JSON Response for \(endpoint): \(rawJsonString)")
            }
            
            // Rest of the existing implementation...
            if httpResponse.statusCode >= 400 {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorMessage = json["error"] as? String {
                        DispatchQueue.main.async {
                            completion(.failure(ViralloopError.apiError(message: errorMessage)))
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(ViralloopError.unknownError))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(ViralloopError.unknownError))
                    }
                }
                return
            }
            
            do {
                if T.self == User.self {
                    if let userResponse = try? JSONDecoder().decode(UserResponse.self, from: data) {
                        DispatchQueue.main.async {
                            completion(.success(userResponse.user as! T))
                        }
                    } else {
                        let user = try JSONDecoder().decode(User.self, from: data)
                        DispatchQueue.main.async {
                            completion(.success(user as! T))
                        }
                    }
                } else {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(decoded))
                    }
                }
            } catch {
                Logger.error("Decoding Error: \(error)")
                if let rawJsonString = String(data: data, encoding: .utf8) {
                    Logger.error("Failed to decode JSON: \(rawJsonString)")
                }
                DispatchQueue.main.async {
                    completion(.failure(ViralloopError.decodingError(message: error.localizedDescription)))
                }
            }
        }
        
        task.resume()
    }
    
}





