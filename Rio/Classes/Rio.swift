
import Alamofire
import Moya
import KeychainSwift
import ObjectMapper
import JWTDecode
import Foundation
import TrustKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

let defaultCulture = "en-us"

public enum RioRegion {
    case euWest1,
         euWest1Beta,
         customRegionWith(url: String, firebaseOptions: RioFirebaseOptions)
    
    var getUrl: String {
        switch self {
        case .euWest1, .customRegionWith: return "https://root.api.retter.io"
        case .euWest1Beta: return "https://root.test-api.retter.io"
        }
    }
    
    var postUrl: String {
        switch self {
        case .euWest1, .customRegionWith: return "https://root.api.retter.io"
        case .euWest1Beta: return "https://root.test-api.retter.io"
        }
    }
    
    var apiURL: String {
        switch self {
        case .euWest1:
            return "api.retter.io"
        case .euWest1Beta:
            return "test-api.retter.io"
        case .customRegionWith(let url, _):
            return url
        }
    }
    
    var firebaseOptions: FirebaseOptions {
        switch self {
        case .euWest1:
            return prodOptions
        case .euWest1Beta:
            return betaOptions
        case .customRegionWith(_, let options):
            let firebaseOptions = FirebaseOptions(googleAppID: options.googleAppID, gcmSenderID: options.gcmSenderID)
            firebaseOptions.projectID = options.projectID
            firebaseOptions.apiKey = options.apiKey
            return firebaseOptions
        }
    }
        
    private var betaOptions: FirebaseOptions {
        let firebaseOptions = FirebaseOptions(googleAppID: "1:814752823492:ios:6429462157e997a146f191",
                                              gcmSenderID: "814752823492")
        firebaseOptions.projectID = "rtbs-c82e1"
        firebaseOptions.apiKey = "AIzaSyCYKQHVjql92jRX350a7dEaxQUhgkSxiUE"
        return firebaseOptions
    }
    
    private var prodOptions: FirebaseOptions {
        let firebaseOptions = FirebaseOptions(googleAppID: "1:1060598260564:ios:e2e8d6ad8c297c1319dec1",
                                              gcmSenderID: "1060598260564")
        firebaseOptions.projectID = "retterio"
        firebaseOptions.apiKey = "AIzaSyAnUv1-qAZYj-MqT0qg-_ErsxJmu1gAOtg"
        return firebaseOptions
    }
}

public struct RioFirebaseOptions {
    let googleAppID: String
    let gcmSenderID: String
    let projectID: String
    let apiKey: String
    
    public init (googleAppID: String, gcmSenderID: String, projectID: String, apiKey: String) {
        self.googleAppID = googleAppID
        self.gcmSenderID = gcmSenderID
        self.projectID = projectID
        self.apiKey = apiKey
    }
}

public struct RioConfig {
    var projectId: String?
    var secretKey: String?
    var developerId: String?
    var serviceId: String?
    var region: RioRegion?
    var sslPinningEnabled: Bool?
    var isLoggingEnabled: Bool?
    var culture: String? = defaultCulture
    
    public init(
        projectId: String,
        secretKey: String? = nil,
        developerId: String? = nil,
        serviceId: String? = nil,
        region: RioRegion? = nil,
        sslPinningEnabled: Bool? = nil,
        isLoggingEnabled: Bool = false,
        culture: String? = nil
    ) {
        self.projectId = projectId
        self.secretKey = secretKey
        self.developerId = developerId
        self.serviceId = serviceId
        self.region = region == nil ? .euWest1 : region
        self.sslPinningEnabled = sslPinningEnabled
        self.isLoggingEnabled = isLoggingEnabled
        self.culture = culture == nil ? defaultCulture : culture
    }
}

struct RioLogger {
    let isLoggingEnabled: Bool
    
    func log(_ text: Any) {
        if isLoggingEnabled {
            print("RioDebug: \(text)")
        }
    }
}

public struct RioUser {
    public var uid: String
    public var isAnonymous: Bool
}

struct RioTokenResponse: Decodable {
    var response: RioTokenData
}

struct RioTokenData: Mappable, Decodable {
    var projectId: String?
    var isAnonym: Bool?
    var uid: String?
    var accessToken: String?
    var refreshToken: String?
    var firebaseToken: String?
    var firebase: CloudOption?
    var deltaTime: Double?
    
    var accessTokenExpiresAt: Date? {
        get {
            guard let accessToken = self.accessToken else { return nil }
            
            let jwt = try! decode(jwt: accessToken)
            return jwt.expiresAt
        }
    }
    
    var refreshTokenExpiresAt: Date? {
        get {
            guard let token = self.refreshToken else { return nil }
            
            let jwt = try! decode(jwt: token)
            return jwt.expiresAt
        }
    }
    
    var userId: String? {
        if let token = accessToken {
            let jwt = try! decode(jwt: token)
            guard let id = jwt.claim(name: "userId").string else {
                return nil
            }
            
            return id
        }
        return nil
    }
    
    
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        isAnonym <- map["isAnonym"]
        projectId <- map["projectId"]
        uid <- map["uid"]
        accessToken <- map["accessToken"]
        refreshToken <- map["refreshToken"]
        firebaseToken <- map["firebaseToken"]
        deltaTime <- map["deltaTime"]
    }
}

public enum RioClientAuthStatus {
    case signedIn(user: RioUser),
         signedInAnonymously(user: RioUser),
         signedOut,
         authenticating
}

public enum RioCulture: String {
    case en = "en-US",
         tr = "tr-TR"
}

public protocol RioClientDelegate {
    func rioClient(client: Rio, authStatusChanged toStatus: RioClientAuthStatus)
}

enum RioKeychainKey {
    case token
    
    var keyName: String {
        get {
            switch self {
            case .token: return "io.retter.token"
            }
        }
    }
}

struct ValidationError: Decodable {
    let issues: [ValidationIssue]?
}

public struct ValidationIssue: Decodable {
    let message: String?
    let params: Params?
    
    public struct Params: Decodable {
        let missingProperty: String? // required missing dependency - only the first one is reported
        let property: String? // dependent property,
        let deps: String? // required dependencies, comma separated list as a string (TODO change to string[])
        let depsCount: Int? // the number of required dependencies
    }
}

public struct RioCloudListResponse: Decodable {
    public let instanceIds: [String]?
}

public enum RioError: Error {
    case TokenError,
         cloudNotConfigured,
         classIdRequired,
         cloudObjectNotFound,
         methodReturnedError,
         validationError(validationIssues: [ValidationIssue]),
         parsingError,
         firebaseInitError,
         networkError(statusCode: Int),
         moyaError(MoyaError)
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

class RioAction {
    var tokenData: RioTokenData?
    
    var successCompletion: ((_ result: [Any]) -> Void)?
    var errorCompletion: ((_ error: Error) -> Void)?
    var action: String?
    var data: [String: Any]?
    
    init() { }
}

public class Rio {
    var projectId: String!
    
    let serialQueue = DispatchQueue(label: "com.queue.Serial")
    
    let semaphore = DispatchSemaphore(value: 0)
    let firebaseAuthSemaphore = DispatchSemaphore(value: 0)
    
    private var cloudObjects: [RioCloudObject] = []
    
    public var delegate: RioClientDelegate? {
        didSet {
            // Check token data and raise status update
            if let data = self.keychain.getData(RioKeychainKey.token.keyName) {
                let json = try! JSONSerialization.jsonObject(with: data, options: [])
                
                if let tokenData = Mapper<RioTokenData>().map(JSONObject: json),
                   let accessToken = tokenData.accessToken {
                    
                    let jwt = try! decode(jwt: accessToken)
                    if let userId = jwt.claim(name: "userId").string, let anonymous = jwt.claim(name: "anonymous").rawValue as? Bool {
                        
                        // User has changed.
                        let user = RioUser(uid: userId, isAnonymous: anonymous)
                        
                        if anonymous {
                            self.delegate?.rioClient(client: self, authStatusChanged: .signedInAnonymously(user: user))
                        } else {
                            self.delegate?.rioClient(client: self, authStatusChanged: .signedIn(user: user))
                        }
                    } else {
                        self.delegate?.rioClient(client: self, authStatusChanged: .signedOut)
                    }
                } else {
                    self.delegate?.rioClient(client: self, authStatusChanged: .signedOut)
                }
            } else {
                self.delegate?.rioClient(client: self, authStatusChanged: .signedOut)
            }
            
        }
    }
    
    private var _service: MoyaProvider<RioService>?
    private var service : MoyaProvider<RioService> {
        get {
            if self._service != nil {
                return self._service!
            }
            
            let accessTokenPlugin = AccessTokenPlugin { _ -> String in
                if let data = self.keychain.getData(RioKeychainKey.token.keyName) {
                    let json = try! JSONSerialization.jsonObject(with: data, options: [])
                    if let tokenData = Mapper<RioTokenData>().map(JSONObject: json), let accessToken = tokenData.accessToken {
                        return accessToken
                    }
                }
                return ""
            }
            var plugins: [PluginType] = [CachePolicyPlugin(), accessTokenPlugin]
            if config.isLoggingEnabled ?? false {
                plugins.append(NetworkLoggerPlugin())
            }
            self._service = MoyaProvider<RioService>(plugins: plugins)
            
            return self._service!
        }
    }
    
    private let keychain = KeychainSwift()
    
    private var config: RioConfig!
    
    private var firebaseApp: FirebaseApp?
    fileprivate var db: Firestore?
    
    fileprivate let logger: RioLogger
    
    private var deltaTime: TimeInterval = 0
    
    public init(config: RioConfig) {
        self.logger = RioLogger(isLoggingEnabled: config.isLoggingEnabled ?? false)
        if let sslPinningEnabled = config.sslPinningEnabled, sslPinningEnabled == false {
            // Dont enable ssl pinning
            logger.log("WARNING! Rio SSL Pinning disabled.")
        } else {
            self.setupTrustKit()
        }
        
        if let options = config.region?.firebaseOptions {
            FirebaseApp.configure(name: "rio", options: options)
        }
        
        guard let app = FirebaseApp.app(name: "rio") else {
            fatalError()
        }
        
        self.firebaseApp = app
        self.db = Firestore.firestore(app: app)
        
        
        self.config = config
        self.projectId = config.projectId
        globalRioRegion = config.region!
    }
    
    public var culture : String {
        get {
            return self.config.culture == nil ? defaultCulture : self.config.culture!
        }
    }
    
    private var safeNow: Date {
        get {
            let r = Date(timeIntervalSinceNow: 30 + deltaTime)
            logger.log("Safenow is \(r) with delta \(deltaTime)")
            return r
        }
    }
    
    // MARK: - Private methods
    
    private func setupTrustKit() {
        let pinningConfig: [String : Any] = [
            kTSKEnforcePinning: true,
            kTSKIncludeSubdomains: true,
            kTSKExpirationDate: "2025-12-01",
            kTSKPublicKeyHashes: [
                "++MBgDH5WGvL9Bcn5Be30cRcL0f5O+NyoXuWtQdX1aI=",
                "f0KW/FtqTjs108NpYj42SrGvOB2PpxIVM8nWxjPqJGE=",
                "NqvDJlas/GRcYbcWE8S/IceH9cq77kg0jVhZeAPXq8k=",
                "9+ze1cZgR9KO1kZrVDxA4HQ6voHRCSVNz4RdTCx4U8U=",
                "KwccWaCgrnaw6tsrrSO61FgLacNgG2MMLq8GE6+oP5I=",
                "FfFKxFycfaIz00eRZOgTf+Ne4POK6FgYPwhBDqgqxLQ="
            ]
        ]
        let trustKitConfig = [
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: [
                "core.rtbs.io": pinningConfig,
                "core-test.rettermobile.com": pinningConfig,
                "core-test.rtbs.io": pinningConfig,
                "core-internal.rtbs.io": pinningConfig,
                "core-internal-beta.rtbs.io": pinningConfig,
                "api.retter.io": pinningConfig,
                "test-api.retter.io": pinningConfig
            ]
        ] as [String: Any]
        
        TrustKit.setLoggerBlock { (_) in }
        TrustKit.initSharedInstance(withConfiguration: trustKitConfig)
    }
    
    private func getTokenData() throws -> RioTokenData {
        logger.log("getTokenData called")
        
        let now = self.safeNow
        
        if let data = self.keychain.getData(RioKeychainKey.token.keyName) {
            
            let json = try! JSONSerialization.jsonObject(with: data, options: [])
            
            if let tokenData = Mapper<RioTokenData>().map(JSONObject: json),
               let refreshToken = tokenData.refreshToken,
               let refreshTokenExpiresAt = tokenData.refreshTokenExpiresAt,
               let accessTokenExpiresAt = tokenData.accessTokenExpiresAt,
               let projectId = tokenData.projectId {
                
                deltaTime = tokenData.deltaTime ?? 0
                
                if(projectId == self.projectId) {
                    logger.log("refreshTokenExpiresAt \(refreshTokenExpiresAt)")
                    logger.log("accessTokenExpiresAt \(accessTokenExpiresAt)")
                    if refreshTokenExpiresAt > now && accessTokenExpiresAt > now {
                        // Token can be used
                        logger.log("returning tokenData")
                        return tokenData
                    }
                    
                    if refreshTokenExpiresAt > now && accessTokenExpiresAt < now {
                        logger.log("refreshing token")
                        // DO REFRESH
                        let refreshTokenRequest = RefreshTokenRequest()
                        refreshTokenRequest.refreshToken = refreshToken
                        
                        return try self.refreshToken(tokenData: tokenData)
                    }
                }
            }
        }
        
        // Get anonym token
        return try self.getAnonymToken()
    }
    
    private func saveTokenData(tokenData: RioTokenData?, isForCustomTokenFlow: Bool = false) {
        logger.log("saveTokenData called with tokenData")
        var storedUserId: String? = nil
        // First get last stored token data from keychain.
        if let data = self.keychain.getData(RioKeychainKey.token.keyName) {
            let json = try! JSONSerialization.jsonObject(with: data, options: [])
            if let storedTokenData = Mapper<RioTokenData>().map(JSONObject: json), let accessToken = storedTokenData.accessToken {
                let jwt = try! decode(jwt: accessToken)
                if let userId = jwt.claim(name: "userId").string {
                    storedUserId = userId
                }
            }
        }
        
        var tokenDataWithDeltaTime = tokenData
        tokenDataWithDeltaTime?.deltaTime = deltaTime
        
        guard let tokenData = tokenDataWithDeltaTime else {
            
            if storedUserId != nil {
                DispatchQueue.main.async {
                    if !isForCustomTokenFlow {
                        self.delegate?.rioClient(client: self, authStatusChanged: .signedOut)
                    }
                }
            }
            
            self.keychain.delete(RioKeychainKey.token.keyName)
            
            return
        }
        
        let obj = Mapper<RioTokenData>().toJSON(tokenData)
        let data = try! JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
        self.keychain.set(data, forKey: RioKeychainKey.token.keyName)
        
        logger.log("saveTokenData 2")
        
        if let accessToken = tokenData.accessToken {
            let jwt = try! decode(jwt: accessToken)
            if let userId = jwt.claim(name: "userId").string, let anonymous = jwt.claim(name: "anonymous").rawValue as? Bool {
                
                if userId != storedUserId {
                    logger.log("userId \(userId) - stored: \(storedUserId)")
                    // User has changed.
                    let user = RioUser(uid: userId, isAnonymous: anonymous)
                    
                    cloudObjects.forEach { object in
                        object.state?.removeListeners()
                    }
                    
                    cloudObjects.removeAll()
                    
                    logger.log("initFirebaseApp 1")
                    if let app = self.firebaseApp, let customToken = tokenData.firebase?.customToken {
                        self.logger.log("FIREBASE custom auth \(userId)")
                       
                        Auth.auth(app: app).signIn(withCustomToken: customToken) { [weak self] (resp, error)  in
                            self?.logger.log("FIREBASE custom auth COMPLETE user: \(resp?.user)")
                            self?.firebaseAuthSemaphore.signal()
                        }
                        
                        _ = self.firebaseAuthSemaphore.wait(wallTimeout: .distantFuture)
                    }
                    
                    DispatchQueue.main.async {
                        if anonymous {
                            self.delegate?.rioClient(client: self, authStatusChanged: .signedInAnonymously(user: user))
                        } else {
                            self.delegate?.rioClient(client: self, authStatusChanged: .signedIn(user: user))
                        }
                    }
                    
                }
            }
        }
    }
    
    private func getAnonymToken() throws -> RioTokenData {
        logger.log("getAnonymToken called")
        
        let getAnonymTokenRequest = GetAnonymTokenRequest()
        getAnonymTokenRequest.projectId = self.config.projectId
        
        var retVal: RioTokenData? = nil
        var errorResponse: BaseErrorResponse?
        
        self.service.request(.getAnonymToken(request: getAnonymTokenRequest)) { [weak self] result in
            switch result {
            case .success(let response):
                if (200...299).contains(response.statusCode),
                   let resp = try? response.map(RioTokenResponse.self) {
                    self?.checkForDeltaTime(for: resp.response.accessToken)
                    retVal = resp.response
                } else {
                    errorResponse = BaseErrorResponse()
                    errorResponse?.cloudObjectResponse = RioCloudObjectResponse(statusCode: response.statusCode, headers: nil, body: nil)
                    errorResponse?.httpStatusCode = response.statusCode
                }
            case .failure(let f):
                errorResponse = BaseErrorResponse()
                errorResponse?.cloudObjectResponse = RioCloudObjectResponse(statusCode: -1, headers: nil, body: nil)
                errorResponse?.httpStatusCode = -1
                errorResponse?.moyaError = f
            }
            self?.semaphore.signal()
        }
        _ = self.semaphore.wait(wallTimeout: .distantFuture)
        
        retVal?.projectId = self.config.projectId
        retVal?.isAnonym = true

        if let e = errorResponse {
            throw e
        }
        if let r = retVal {
            return r
        }
        throw "Can't get anonym token"
    }
    
    private func refreshToken(tokenData: RioTokenData) throws -> RioTokenData {
        logger.log("refreshToken called")
        
        let refreshTokenRequest = RefreshTokenRequest()
        refreshTokenRequest.refreshToken = tokenData.refreshToken
        refreshTokenRequest.projectId = projectId
        refreshTokenRequest.userId = tokenData.userId
        
        var retVal: RioTokenData? = nil
        var errorResponse: BaseErrorResponse?
        
        self.service.request(.refreshToken(request: refreshTokenRequest)) { [weak self] result in
            switch result {
            case .success(let response):
                if (200...299).contains(response.statusCode),
                   let val = try? response.map(RioTokenData.self) {
                    self?.checkForDeltaTime(for: val.accessToken)
                    retVal = val
                } else {
                    errorResponse = BaseErrorResponse()
                    errorResponse?.cloudObjectResponse = RioCloudObjectResponse(statusCode: response.statusCode, headers: nil, body: nil)
                    errorResponse?.httpStatusCode = response.statusCode
                }
            case .failure(let f):
                errorResponse = BaseErrorResponse()
                errorResponse?.cloudObjectResponse = RioCloudObjectResponse(statusCode: -1, headers: nil, body: nil)
                errorResponse?.httpStatusCode = -1
                errorResponse?.moyaError = f
            }
            self?.semaphore.signal()
        }
        _ = self.semaphore.wait(wallTimeout: .distantFuture)
        
        retVal?.projectId = tokenData.projectId
        retVal?.isAnonym = tokenData.isAnonym

        if let e = errorResponse {
            throw e
        }
        if let r = retVal {
            return r
        }
        throw "Can't refresh token"
    }
    
    private func checkForDeltaTime(for token: String?) {
        guard let accessToken = token,
              let jwt = try? decode(jwt: accessToken),
              let serverTime = jwt.claim(name: "iat").integer else {
                return
        }
        
        deltaTime =  TimeInterval(serverTime) - Date().timeIntervalSince1970
    }
    
    private func executeAction(
        tokenData: RioTokenData,
        action: String,
        data: [String: Any],
        culture: String?,
        headers: [String: String]?,
        cloudObjectOptions: RioCloudObjectOptions? = nil
    ) throws -> [Any] {
        logger.log("executeAction called")
        let req = ExecuteActionRequest()
        req.projectId = self.projectId
        req.accessToken = tokenData.accessToken
        req.actionName = action
        req.payload = data
        req.headers = headers
        req.culture = culture
        req.classID = cloudObjectOptions?.classID
        req.instanceID = cloudObjectOptions?.instanceID
        req.keyValue = cloudObjectOptions?.keyValue
        req.httpMethod = cloudObjectOptions?.httpMethod
        req.method = cloudObjectOptions?.method
        req.queryString = cloudObjectOptions?.queryString
        
        var errorResponse: BaseErrorResponse?
        
        var retVal: [Any]? = nil
        let semaphoreLocal = DispatchSemaphore(value: 0)
        self.service.request(.executeAction(request: req)) { result in
            switch result {
            case .success(let response):
                if (200...299).contains(response.statusCode) {
                    if cloudObjectOptions != nil {
                        retVal = [RioCloudObjectResponse(statusCode: response.statusCode,
                                                         headers: response.response?.headers.dictionary,
                                                         body: response.data)]
                    } else {
                        if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [Any] {
                            retVal = json
                        } else if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) {
                            retVal = [json]
                        }
                        
                        if retVal == nil {
                            retVal = []
                        }
                    }
                } else {
                    errorResponse = try? response.map(BaseErrorResponse.self)
                    errorResponse?.httpStatusCode = response.statusCode
                    
                    errorResponse?.cloudObjectResponse = cloudObjectOptions != nil ? RioCloudObjectResponse(statusCode: response.statusCode,
                                                                                                            headers: response.response?.headers.dictionary,
                                                                                                            body: response.data) : nil
                    
                    if errorResponse == nil {
                        errorResponse = BaseErrorResponse()
                        errorResponse?.httpStatusCode = response.statusCode
                        errorResponse?.cloudObjectResponse = cloudObjectOptions != nil ? RioCloudObjectResponse(statusCode: response.statusCode,
                                                                                                                headers: response.response?.headers.dictionary,
                                                                                                                body: response.data) : nil
                    }
                }
            case .failure(let f):
                self.logger.log(f)
                errorResponse = BaseErrorResponse()
                errorResponse?.cloudObjectResponse = RioCloudObjectResponse(statusCode: -1, headers: nil, body: nil)
                errorResponse?.httpStatusCode = -1
                errorResponse?.moyaError = f
            }
            semaphoreLocal.signal()
        }
        _ = semaphoreLocal.wait(wallTimeout: .distantFuture)
        
        if let e = errorResponse {
            throw e
        }
        if let r = retVal {
            return r
        }
        
        // Işıl & Arda & Efe
        
        throw "Can't execute action."
    }
    
    // MARK: - Public methods
    
    public func authenticateWithCustomToken(_ customToken: String, authSuccess: ((Bool, RioError?) -> Void)? = nil) {
        logger.log("authenticateWithCustomToken called")
        serialQueue.async {
            
            self.saveTokenData(tokenData: nil, isForCustomTokenFlow: true)
            let req = AuthWithCustomTokenRequest()
            req.customToken = customToken
            
            let jwt = try! decode(jwt: customToken)
            guard let id = jwt.claim(name: "userId").string else {
                return
            }
            
            req.userId = id
            req.projectId = self.projectId
            
            self.service.request(.authWithCustomToken(request: req)) { [weak self] result in
                switch result {
                case .success(let response):
                    if (200...299).contains(response.statusCode) {
                        if var tokenData = try? response.map(RioTokenData.self) {
                            tokenData.projectId = self?.config.projectId
                            tokenData.isAnonym = false
                            self?.serialQueue.async {
                                self?.saveTokenData(tokenData: tokenData)
                                authSuccess?(true, nil)
                            }
                        } else {
                            authSuccess?(false, .parsingError)
                        }
                    } else {
                        authSuccess?(false, .networkError(statusCode: response.statusCode))
                    }
                case .failure(let f):
                    authSuccess?(false, .moyaError(f))
                }
                self?.semaphore.signal()
            }
            _ = self.semaphore.wait(wallTimeout: .distantFuture)
            
        }
    }
    
    public func signInAnonymously(completion: (() -> Void)? = nil) {
        send(
            action: "signInAnonym",
            data: [:],
            headers: nil
        ) { _ in
            completion?()
        } onError: { _ in
            completion?()
        }
    }
    
    public func signOut(authSuccess: ((Bool, RioError?) -> Void)? = nil) {
        
        if let data = self.keychain.getData(RioKeychainKey.token.keyName),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            
            if let tokenData = Mapper<RioTokenData>().map(JSONObject: json),
               let accessToken = tokenData.accessToken,
               let userId = tokenData.userId {
                
                let req = SignOutRequest()
                req.accessToken = accessToken
                req.projectId = projectId
                req.userId = userId
                
                self.service.request(.signout(request: req)) { result in
                    switch result {
                    case .success(let response):
                        if (200...299).contains(response.statusCode) {
                            authSuccess?(true, nil)
                        } else {
                            authSuccess?(false, .networkError(statusCode: response.statusCode))
                        }
                    case .failure(let f):
                        authSuccess?(false, .moyaError(f))
                    }
                }
            }
        }
        
        
        self.saveTokenData(tokenData: nil)
        do {
            cloudObjects.forEach { object in
                object.state?.removeListeners()
            }
            cloudObjects.removeAll()
            
            guard let app = firebaseApp else {
                return
            }
            try Auth.auth(app: app).signOut()
        } catch { }
    }
    
    public func removeAllCloudObjects() { // ONLY FOR TEST PURPOSES
        cloudObjects.forEach { object in
            object.state?.removeListeners()
        }
        cloudObjects.removeAll()
    }
    
    private func generatePublicGetActionUrl(
        action actionName: String,
        data: [String: Any]
    ) -> String {
        
        let req = ExecuteActionRequest()
        req.projectId = self.projectId
        req.actionName = actionName
        req.payload = data
        
        let s: RioService = .executeAction(request: req)
        
        var url = "\(s.baseURL)\(s.endPoint)?"
        for param in s.urlParameters {
            url = "\(url)\(param.key)=\(param.value)&"
        }
        
        return url
    }
    
    private func generateGetActionUrl(
        action actionName: String,
        data: [String: Any],
        onSuccess: @escaping (_ result: String) -> Void,
        onError: @escaping (_ error: Error) -> Void
    ) {
        serialQueue.async {
            do {
                let tokenData = try self.getTokenData()
                self.saveTokenData(tokenData: tokenData)
                
                let req = ExecuteActionRequest()
                req.projectId = self.projectId
                req.accessToken = tokenData.accessToken
                req.actionName = actionName
                req.payload = data
                
                let s: RioService = .executeAction(request: req)
                
                var url = "\(s.baseURL)\(s.endPoint)?"
                for param in s.urlParameters {
                    url = "\(url)\(param.key)=\(param.value)&"
                }
                
                DispatchQueue.main.async {
                    onSuccess(url)
                }
                
            } catch {
                onError(error)
            }
        }
    }
    
    public func send(
        action actionName: String,
        data: [String: Any],
        headers: [String: String]?,
        cloudObjectOptions: RioCloudObjectOptions? = nil,
        onSuccess: @escaping (_ result: [Any]) -> Void,
        onError: @escaping (_ error: Error) -> Void
    ) {
        logger.log("send called")
        
        serialQueue.async {
            self.logger.log("send called in async block")
            do {
                
                self.logger.log("getTokenData called in send")
                let tokenData = try self.getTokenData()
                
                self.logger.log("saveTokenData called in send")
                self.saveTokenData(tokenData: tokenData)
                
                if actionName == "signInAnonym" {
                    onSuccess([])
                    return
                }
                
                DispatchQueue.global().async {
                    do {
                        let actionResult = try self.executeAction(
                            tokenData: tokenData,
                            action: actionName,
                            data: data,
                            culture: cloudObjectOptions?.culture,
                            headers: headers,
                            cloudObjectOptions: cloudObjectOptions
                        )
                        
                        DispatchQueue.main.async {
                            self.logger.log("send onSuccess")
                            onSuccess(actionResult)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            onError(error)
                        }
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    onError(error)
                }
            }
        }
    }
    
    // MARK: - Get Cloud Object
    
    public func getCloudObject(
        with options: RioCloudObjectOptions,
        onSuccess: @escaping (RioCloudObject) -> Void,
        onError: @escaping (RioCloudObjectError) -> Void
    ) {
        
        var options2 = options
        if options2.culture == nil { options2.culture = self.culture }
        
        guard let classId = options2.classID else {
            onError(RioCloudObjectError(error: RioError.classIdRequired, response: nil))
            return
        }
        
        if let instance = options2.instanceID,
           let object = cloudObjects.filter({ $0.classID == classId && $0.instanceID == instance }).first {
            onSuccess(object)
            return
        }
        
        let parameters: [String: Any] = options2.body?.compactMapValues( { $0 }) ?? [:]
        let headers = options2.headers?.compactMapValues( { $0 } ) ?? [:]
        
        if (options2.useLocal ?? false) && options2.instanceID != nil {
            onSuccess(RioCloudObject(
                projectID: self.projectId,
                classID: classId,
                instanceID: options2.instanceID!,
                userID: "",
                userIdentity: "",
                rio: self,
                isLocal: true
            ))
            return
        }
        
        send(
            action: "rbs.core.request.INSTANCE",
            data: parameters,
            headers: headers,
            cloudObjectOptions: options2
        ) { [weak self] (response) in
            guard let self = self else {
                return
            }
            
            guard let firstResponse = response.first as? RioCloudObjectResponse,
                  let data = firstResponse.body,
                  let cloudResponse = try? JSONDecoder().decode(RioCloudObjectInstanceResponse.self, from: data) else {
                      return
                  }

            var objectData: Data?
            if let insDict = (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)) as? [String: Any],
               insDict["response"] != nil,
               let insRespData = try? JSONSerialization.data(withJSONObject: insDict["response"] as Any, options: JSONSerialization.WritingOptions.prettyPrinted) {
                objectData = insRespData
            }
            
            if let respInstanceId = cloudResponse.instanceId {
                
                var userIdentity: String?
                var userId: String?
                if let data = self.keychain.getData(RioKeychainKey.token.keyName) {
                    let json = try! JSONSerialization.jsonObject(with: data, options: [])
                    if let storedTokenData = Mapper<RioTokenData>().map(JSONObject: json), let accessToken = storedTokenData.accessToken {
                        let jwt = try! decode(jwt: accessToken)
                        if let id = jwt.claim(name: "userId").string {
                            userId = id
                        }
                        if let identity = jwt.claim(name: "identity").string {
                            userIdentity = identity
                        }
                    }
                }
                
                if let object = self.cloudObjects.filter({ $0.classID == classId && $0.instanceID == respInstanceId }).first {
                    onSuccess(object)
                } else {
                    let object = RioCloudObject(
                        projectID: self.projectId,
                        classID: classId,
                        instanceID: respInstanceId,
                        userID: userId ?? "",
                        userIdentity: userIdentity ?? "",
                        rio: self,
                        response: objectData,
                        methods: cloudResponse.methods,
                        isNewInstance: cloudResponse.isNewInstance ?? false
                    )
                    self.cloudObjects.append(object)
                    onSuccess(object)
                }
            }
        } onError: { (error) in
            if let error = error as? BaseErrorResponse, let cloudObjectResponse = error.cloudObjectResponse {

                if let errorData = cloudObjectResponse.body,
                   let validatationError = try? JSONDecoder().decode(ValidationError.self, from: errorData),
                   let issues = validatationError.issues {
                    onError(RioCloudObjectError(error: .validationError(validationIssues: issues), response: cloudObjectResponse))
                } else if let moyaError = error.moyaError {
                    onError(RioCloudObjectError(error: .moyaError(moyaError), response: cloudObjectResponse))
                } else {
                    onError(RioCloudObjectError(error: .cloudObjectNotFound, response: cloudObjectResponse))
                }
            }
        }
    }
}

// MARK: - RioCloudObject

open class RioCloudObject {
    public struct State {
        public let user: RioCloudObjectState
        public let role: RioCloudObjectState
        public let `public`: RioCloudObjectState
        
        public func removeListeners() {
            user.listener?.remove()
            role.listener?.remove()
            `public`.listener?.remove()
        }
    }
    
    private let projectID: String
    fileprivate let classID: String
    fileprivate let instanceID: String
    private let userID: String
    private let userIdentity: String
    private weak var db: Firestore?
    private weak var rio: Rio?
    public let state: State?
    private let isLocal: Bool
    public let response: Data?
    public let methods: [RioCloudObjectMethod]?
    public let isNewInstance: Bool
    
    public var instanceId: String {
        get {
            return instanceID
        }
    }
    
    init(projectID: String, classID: String, instanceID: String, userID: String, userIdentity: String, rio: Rio?, isLocal: Bool = false, response: Data? = nil, methods: [RioCloudObjectMethod]? = nil, isNewInstance: Bool = false) {
        self.projectID = projectID
        self.classID = classID
        self.instanceID = instanceID
        self.userID = userID
        self.userIdentity = userIdentity
        self.rio = rio
        self.db = rio?.db
        self.isLocal = isLocal
        self.response = response
        self.methods = methods
        self.isNewInstance = isNewInstance
        
        if !isLocal {
            state = State(
                user: RioCloudObjectState(projectID: projectID, classID: classID, instanceID: instanceID, userID: userID, userIdentity: userIdentity, state: .user, db: db),
                role: RioCloudObjectState(projectID: projectID, classID: classID, instanceID: instanceID, userID: userID, userIdentity: userIdentity, state: .role, db: db),
                public: RioCloudObjectState(projectID: projectID, classID: classID, instanceID: instanceID, userID: userID, userIdentity: userIdentity, state: .public, db: db)
            )
        } else {
            state = nil
        }
    }
    
    public func call(
        with options: RioCloudObjectOptions,
        onSuccess: @escaping (RioCloudObjectResponse) -> Void,
        onError: @escaping (RioCloudObjectError) -> Void
    ) {
        
        var options2 = options
        options2.classID = self.classID
        options2.instanceID = self.instanceID
        options2.culture = options.culture == nil ? self.rio?.culture : options.culture
        
        let parameters: [String: Any] = options.body?.compactMapValues( { $0 }) ?? [:]
        let headers = options.headers?.compactMapValues( { $0 } ) ?? [:]
        
        if let encodingWarning = parameters.toEncodableDictionary().1 {
            rio?.logger.log(encodingWarning)
        }
        
        guard let rio = rio else {
            return
        }
        
        rio.send(
            action: "rbs.core.request.CALL",
            data: parameters,
            headers: headers,
            cloudObjectOptions: options2
        ) { (response) in
            if let objectResponse = response.first as? RioCloudObjectResponse {
                onSuccess(objectResponse)
            } else {
                let errorResponse = RioCloudObjectResponse(statusCode: -1, headers: nil, body: response.first as? Data)
                onError(RioCloudObjectError(error: .parsingError, response: errorResponse))
            }
        } onError: { (error) in
            if let error = error as? BaseErrorResponse, let cloudObjectResponse = error.cloudObjectResponse {
                if let errorData = cloudObjectResponse.body,
                   let validatationError = try? JSONDecoder().decode(ValidationError.self, from: errorData),
                   let issues = validatationError.issues {
                    onError(RioCloudObjectError(error: .validationError(validationIssues: issues), response: cloudObjectResponse))
                } else if let moyaError = error.moyaError {
                    onError(RioCloudObjectError(error: .moyaError(moyaError), response: cloudObjectResponse))
                } else {
                    onError(RioCloudObjectError(error: .methodReturnedError, response: cloudObjectResponse))
                }
            }
        }
    }
    
    public func listInstances(
        with options: RioCloudObjectOptions,
        onSuccess: @escaping (RioCloudListResponse) -> Void,
        onError: @escaping (RioCloudObjectError) -> Void
    ) {
        
        var options2 = options
        options2.classID = self.classID
        options2.instanceID = self.instanceID
        options2.culture = options.culture == nil ? self.rio?.culture : options.culture
        
        let parameters: [String: Any] = options.body?.compactMapValues( { $0 }) ?? [:]
        let headers = options.headers?.compactMapValues( { $0 } ) ?? [:]
        
        guard let rio = rio else {
            return
        }
        
        rio.send(
            action: "rio.core.request.LIST",
            data: parameters,
            headers: headers,
            cloudObjectOptions: options2
        ) { (response) in
            if let objectResponse = response.first as? RioCloudObjectResponse {
                if let data = objectResponse.body,
                   let list = try? JSONDecoder().decode(RioCloudListResponse.self, from: data) {
                    onSuccess(list)
                } else {
                    let errorResponse = RioCloudObjectResponse(statusCode: -1, headers: nil, body: response.first as? Data)
                    onError(RioCloudObjectError(error: .parsingError, response: errorResponse))
                }
            } else {
                let errorResponse = RioCloudObjectResponse(statusCode: -1, headers: nil, body: response.first as? Data)
                onError(RioCloudObjectError(error: .parsingError, response: errorResponse))
            }
        } onError: { (error) in
            if let error = error as? BaseErrorResponse, let cloudObjectResponse = error.cloudObjectResponse {
                if let errorData = cloudObjectResponse.body,
                   let validatationError = try? JSONDecoder().decode(ValidationError.self, from: errorData),
                   let issues = validatationError.issues {
                    onError(RioCloudObjectError(error: .validationError(validationIssues: issues), response: cloudObjectResponse))
                } else if let moyaError = error.moyaError {
                    onError(RioCloudObjectError(error: .moyaError(moyaError), response: cloudObjectResponse))
                } else {
                    onError(RioCloudObjectError(error: .methodReturnedError, response: cloudObjectResponse))
                }
            }
        }
    }
    
    public func unsubscribeStates() {
        state?.removeListeners()
    }
}

// MARK: - RioCloudObjectState

public class RioCloudObjectState {
    let projectID: String
    let classID: String
    let instanceID: String
    let userID: String
    let userIdentity: String
    let state: CloudObjectState
    weak var db: Firestore?
    var listener: ListenerRegistration?
    
    init(projectID: String, classID: String, instanceID: String, userID: String, userIdentity: String, state: CloudObjectState, db: Firestore?) {
        self.projectID = projectID
        self.classID = classID
        self.instanceID = instanceID
        self.state = state
        self.userID = userID
        self.userIdentity = userIdentity
        self.db = db
        
    }
    
    public func subscribe(
        onSuccess: @escaping ([String: Any]?) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        var path = "/projects/\(projectID)/classes/\(classID)/instances/\(instanceID)/"
        
        guard let database = db else {
            onError(RioError.cloudNotConfigured)
            return
        }
        
        switch state {
        case .user:
            path.append("userState/\(userID)")
            listener = database.document(path)
                .addSnapshotListener { (snap, error) in
                    guard error == nil else {
                        onError(error!)
                        return
                    }
                    
                    onSuccess(snap?.data())
                }
        case .role:
            path.append("roleState/\(userIdentity)")
            listener = database.document(path)
                .addSnapshotListener { (snap, error) in
                    guard error == nil else {
                        onError(error!)
                        return
                    }
                    
                    onSuccess(snap?.data())
                }
        case .public:
            listener = database.document(path).addSnapshotListener { (snap, error) in
                guard error == nil else {
                    onError(error!)
                    return
                }
                
                onSuccess(snap?.data())
            }
        }
    }
    
    public func unsubscribeState() {
        listener?.remove()
    }
}

enum CloudObjectState {
    case user,
         role,
         `public`
}

// MARK: - Cloud Models

public struct RioCloudObjectOptions {
    public var classID: String?
    public var instanceID: String?
    public var keyValue: (key: String, value: String)?
    public var method: String?
    public var headers: [String: String]?
    public var queryString: [String: Any]?
    public var httpMethod: Moya.Method?
    public var body: [String: Any]?
    public var useLocal: Bool?
    public var culture: String?
    
    public init(
        classID: String? = nil,
        instanceID: String? = nil,
        keyValue: (key: String, value: String)? = nil,
        method: String? = nil,
        headers: [String: String]? = nil,
        queryString: [String: Any]? = nil,
        httpMethod: Moya.Method? = nil,
        body: [String: Any]? = nil,
        useLocal: Bool? = nil,
        culture: String? = nil
    ) {
        self.classID = classID
        self.instanceID = instanceID
        self.keyValue = keyValue
        self.method = method
        self.headers = headers
        self.queryString = queryString
        self.httpMethod = httpMethod
        self.body = body
        self.useLocal = useLocal
        self.culture = culture == nil ? defaultCulture : culture
    }
}

struct RioCloudObjectInstanceResponse: Decodable {
    let isNewInstance: Bool?
    let methods: [RioCloudObjectMethod]?
    let instanceId: String?
}

public struct RioCloudObjectMethod: Decodable {
    public let name: String?
    let readOnly: Bool?
    let sync: Bool?
    let tag: String?
}

struct CloudOption: Decodable {
    var customToken: String?
    var projectId: String?
    var apiKey: String?
    var envs: RioFirebaseEnv?
}

struct RioFirebaseEnv: Decodable {
    var iosAppId: String?
    var gcmSenderId: String?
}


public struct RioCloudObjectResponse: Codable {
    public let statusCode: Int
    public let headers: [String:String]?
    public let body: Data?
}

public struct RioCloudObjectError: Error {
    public let error: RioError
    public let response: RioCloudObjectResponse?
}
