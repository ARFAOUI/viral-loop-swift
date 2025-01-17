import Foundation

public class ViralloopClient {
    // Shared instance
    // MARK: - Shared Instance Management
     static var sharedInstance: ViralloopClient?  // Changed from 'shared' to 'sharedInstance'
     private static let lock = NSLock()
     
     public static func configure(apiKey: String, appId: String, logLevel: LogLevel = .info) {
         lock.lock()
         defer { lock.unlock() }
         
         if sharedInstance != nil {  // Updated reference
             Logger.warning("ViralloopClient already configured. Ignoring new configuration.")
             return
         }
         
         sharedInstance = ViralloopClient(apiKey: apiKey, appId: appId, logLevel: logLevel)  // Updated reference
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
        // Check if we already have a user ID
        if let existingUserId = Storage.getUserId() {
            let deviceInfo = DeviceInfo.getDeviceInfo()
            let appInfo = DeviceInfo.getAppInfo()
            
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
                lifetimeValueUsd: 0.0,  // Explicitly set as Double
                referralCode: Storage.getReferralCode()
            )
            Logger.info("Existing user loaded: \(existingUserId)")
            updateUserIfNeeded()
            return
        }

        // Initialize new user
        let deviceInfo = DeviceInfo.getDeviceInfo()
        let appInfo = DeviceInfo.getAppInfo()
        let userId = DeviceInfo.generateUserId()
        
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
            lifetimeValueUsd: 0.0,  // Explicitly set as Double
            referralCode: nil
        )
        
        registerUser { [weak self] result in
            switch result {
            case .success(let registeredUser):
                Storage.saveUserId(registeredUser.externalUserId)
                if let referralCode = registeredUser.referralCode {
                    Storage.saveReferralCode(referralCode)
                }
                self?.currentUser = registeredUser
                Logger.info("New user registered: \(registeredUser.externalUserId)")
            case .failure(let error):
                Logger.error("Failed to register user: \(error)")
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
    
    // MARK: - Public Methods
    
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
            appBuildNumber: String(appInfo.buildNumber)
        )
        
        guard let data = try? JSONEncoder().encode(update) else {
            Logger.error("Failed to encode daily update")
            return
        }
        
        makeRequest("users/\(userId)", method: "PUT", body: data) { (result: Result<User, Error>) in
               switch result {
               case .success(_):
                   Storage.saveLastUpdate(Date())
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





