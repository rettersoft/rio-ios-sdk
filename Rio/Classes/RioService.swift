//
//  RBSService.swift
//  RBS
//
//  Created by Baran Baygan on 19.11.2020.
//


import Foundation
import Moya
import Alamofire


var globalRioRegion: RioRegion = .euWest1

let cloudObjectActions = ["rbs.core.request.INSTANCE", "rbs.core.request.CALL", "rio.core.request.LIST"]

enum RioService {
    
    case getAnonymToken(request: GetAnonymTokenRequest)
    case executeAction(request: ExecuteActionRequest)
    
    case refreshToken(request: RefreshTokenRequest)
    case authWithCustomToken(request: AuthWithCustomTokenRequest)
    case signout(request: SignOutRequest)
    
    var endPoint: String {
        switch self {
        case .getAnonymToken:
            return "/root/INSTANCE/ProjectUser"
        case .executeAction(let request):
            let isExcludedAction = cloudObjectActions.contains(request.actionName ?? "")
            
            if !isExcludedAction {
                return "/user/action/\(request.projectId!)/\(request.actionName!)"
            } else {
                if request.actionName == "rio.core.request.LIST" {
                    return "/\(request.projectId!)/LIST/\(request.classID ?? "")"
                }

                if request.actionName == "rbs.core.request.CALL" {
                    if request.isStaticMethod ?? false {
                        var thePath = "/\(request.projectId!)/CALL/\(request.classID ?? "")/\(request.method ?? "")"
                        if let endPath = request.path {
                            if endPath.first != "/" {
                                thePath.append("/")
                            }
                            thePath.append(contentsOf: endPath)
                        }
                        return thePath
                    } else {
                        var thePath = "/\(request.projectId!)/CALL/\(request.classID ?? "")/\(request.method ?? "")/\(request.instanceID ?? "")"
                        if let endPath = request.path {
                            if endPath.first != "/" {
                                thePath.append("/")
                            }
                            thePath.append(contentsOf: endPath)
                        }
                        return thePath
                    }
                }
        
                if let instanceID = request.instanceID {
                    return "/\(request.projectId!)/INSTANCE/\(request.classID ?? "")/\(instanceID)"
                } else if let keyValue = request.keyValue {
                    return "/\(request.projectId!)/INSTANCE/\(request.classID ?? "")/\(keyValue.key)!\(keyValue.value)"
                } else {
                    return "/\(request.projectId!)/INSTANCE/\(request.classID ?? "")"
                }
                
            }
        case .refreshToken(let request):
            return "/\(request.projectId ?? "")/TOKEN/refresh"
        case .authWithCustomToken(let request):
            return "/\(request.projectId ?? "")/TOKEN/auth"
        case .signout(let request):
            return "/\(request.projectId ?? "")/TOKEN/signOut"
        }
    }
    
    var body: [String:Any] {
        switch self {
        case .executeAction(let request):
            if let payload = request.payload {
                return payload
            }
            return [:]
        case .getAnonymToken(let request):
            return ["projectId": request.projectId ?? ""]
        case .refreshToken(let request):
            return [
                "refreshToken": request.refreshToken ?? "",
                "accessToken": request.accessToken ?? ""
            ]
        case .authWithCustomToken(let request):
            return ["customToken": request.customToken ?? ""]
        default: return [:]
        }
    }
    
    func isGetAction(_ action:String?) -> Bool {
        guard let actionName = action else { return false }
        let actionType = actionName.split(separator: ".")[2]
        return actionType == "get"
    }
    
    var urlParameters: [String: Any] {
        switch self {
            /*
        case .getAnonymToken(let request):
            return ["projectId": request.projectId ?? ""]
        case .refreshToken(let request):
            return ["refreshToken": request.refreshToken ?? ""]
        case .authWithCustomToken(let request):
            return ["customToken": request.customToken ?? ""]
             */
        case .signout(let request):
            return [
                //"_token": request.accessToken ?? "",
                "type": request.type ?? ""
            ]
        case .executeAction(let request):
            
            if cloudObjectActions.contains(request.actionName ?? "") {
                var parameters: [String: Any] = [:]
                /*
                if let token = request.accessToken {
                    parameters["_token"] = token
                }
                 */
                
                if let queryParameters = request.queryString {
                    for (key, value) in queryParameters {
                        parameters[key] = value
                    }
                }
                
                if let culture = request.culture {
                    parameters["__culture"] = culture
                }
                
                parameters["__platform"] = "IOS"
                
                if request.httpMethod == .get {
                    if let payload = request.payload, !payload.isEmpty {
                        let encodablePayload = payload.toEncodableDictionary().0
                        if let data = try? JSONSerialization.data(withJSONObject: encodablePayload, options: [.fragmentsAllowed, .sortedKeys]),
                           let base64 = data.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                            parameters["data"] = base64
                            parameters["__isbase64"] = true
                        }
                    } else {
                        parameters["__isbase64"] = false
                    }
                }
                
                return parameters
            }
            
            if let action = request.actionName {
                // let accessToken = request.accessToken != nil ? request.accessToken! : ""
                if(self.isGetAction(action)) {
                    let payload: [String: Any] = request.payload == nil ? [:] : request.payload!
                    
                    var parameters =  [
                        // "auth": accessToken,
                        "platform": "IOS"
                    ]
                    
                    if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
                       let dataBase64 = data.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                        parameters["data"] = dataBase64
                    }
                    
                    if let culture = request.culture {
                        parameters["culture"] = culture
                    }
                    
                    return parameters
                } else {
                    var parameters: [String: String] = [:] // ["auth": accessToken]
                    if let culture = request.culture {
                        parameters["culture"] = culture
                    }
                    
                    return parameters
                }
            } else {
                return [:]
            }
        default:
            return [:]
        }
    }
    
    var httpMethod: Moya.Method {
        switch self {
        case .executeAction(let request):

            let isExcludedAction = cloudObjectActions.contains(request.actionName ?? "")

            if !isExcludedAction {
                if(self.isGetAction(request.actionName)) {
                    return .get
                }
                
                return .post
            } else {
                return request.httpMethod ?? .post
            }
        case .authWithCustomToken, .refreshToken, .signout:
            return .post
        default: return .get
        }
    }
}


extension RioService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType? {
        switch self {
        default: return .none
        }
    }
    
    var baseURL: URL {
        switch self {
        case .executeAction(let request):
            
            let isExcludedAction = cloudObjectActions.contains(request.actionName ?? "")
            
            if !isExcludedAction {
                if(self.isGetAction(request.actionName)) {
                    return URL(string: globalRioRegion.getUrl)!
                }
                return URL(string: globalRioRegion.postUrl)!
            } else {
                switch globalRioRegion {
                case .euWest1, .euWest1Beta:
                    return URL(string: "https://\(request.projectId!).\(globalRioRegion.apiURL)")!
                case .customRegionWith(_, _):
                    return URL(string: "https://\(globalRioRegion.apiURL)")!
                }
            }
        default:
            switch globalRioRegion {
            case .euWest1, .euWest1Beta:
                return URL(string: "https://root.\(globalRioRegion.apiURL)")!
            case .customRegionWith(_, _):
                return URL(string: "https://\(globalRioRegion.apiURL)")!
            }
        }
    }
    var path: String { return self.endPoint }
    var method: Moya.Method { return self.httpMethod }
    var sampleData: Data {
        switch self {
        default:
            return Data()
        }
    }
    var task: Task {
        switch self {
        case .executeAction(let request):
            
            if isGetAction(request.actionName) || httpMethod == .get {
                return .requestParameters(parameters: self.urlParameters, encoding: URLEncoding(destination: .queryString, arrayEncoding: .noBrackets, boolEncoding: .literal))
            }
            
            return .requestCompositeParameters(bodyParameters: self.body,
                                               bodyEncoding: JSONEncoding.default,
                                               urlParameters: self.urlParameters)
        case .authWithCustomToken, .refreshToken, .signout:
            return .requestCompositeParameters(bodyParameters: self.body,
                                               bodyEncoding: JSONEncoding.default,
                                               urlParameters: self.urlParameters)
        default:
            return .requestParameters(parameters: self.urlParameters, encoding: URLEncoding.default)
        }
    }
    func getLanguageISO() -> String {
        let locale = Locale.current
        guard let languageCode = locale.languageCode,
              let regionCode = locale.regionCode else {
            return "en_US"
        }
        return languageCode + "_" + regionCode
    }
    var headers: [String : String]? {
        
        var headers: [String: String] = [:]
        headers["Content-Type"] = "application/json"
        headers["x-rio-sdk-client"] = "iOS"
        headers["rio-sdk-version"] = "0.0.62"
        headers["installationId"] = String.getInstallationId()
        
        switch self {
        case .executeAction(let request):
            if var reqHeaders = request.headers {
                if(!reqHeaders.keys.contains { $0 == "accept-language" || $0 == "Accept-Language" }) {
                    reqHeaders["accept-language"] = self.getLanguageISO()
                }
                for h in reqHeaders {
                    headers[h.key] = h.value
                }
            }
            
            if let token = request.accessToken {
                headers["Authorization"] = "Bearer \(token)"
            }
            
            headers["Content-Type"] = "application/json"
            break
        case .signout(let request):
            if let token = request.accessToken {
                headers["Authorization"] = "Bearer \(token)"
            }
        default:
            break
        }
        
        return headers
    }
}

extension RioService : CachePolicyGettable {
    var cachePolicy: URLRequest.CachePolicy {
        get {
            .reloadIgnoringLocalAndRemoteCacheData
        }
    }
}

protocol CachePolicyGettable {
    var cachePolicy: URLRequest.CachePolicy { get }
}

final class CachePolicyPlugin: PluginType {
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let cachePolicyGettable = target as? CachePolicyGettable {
            var mutableRequest = request
            mutableRequest.cachePolicy = cachePolicyGettable.cachePolicy
            return mutableRequest
        }
        
        return request
    }
}

extension Encodable {
    var dict: Any? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }

        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))
    }
}

extension Dictionary where Key == String {
    func toEncodableDictionary() -> ([String: Any], String?) {
        var newDict: [String: Any] = [:]
        var errorMessage: String?
        for (key, value) in self {
            if JSONSerialization.isValidJSONObject([key: value]) {
                newDict[key] = value
            } else if let encodableValue = value as? Encodable {
                newDict[key] = encodableValue.dict
            } else {
                errorMessage = "⚠️ An unencodable object (i.e., for the key '\(key)') exists in the payload, please make sure to pass encodable objects into the payload!"
            }
        }
        return (newDict, errorMessage)
    }
}

extension String {
    static func getInstallationId() -> String {
        if let id = UserDefaults.standard.string(forKey: RioUserDefaultsKey.installationId.keyName) {
            return id
        } else {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: RioUserDefaultsKey.installationId.keyName)
            return id
        }
    }
}

class PublicKeysPinningTrustEvaluator: ServerTrustEvaluating {
    let pinnedPublicKeys: [SecKey]

    init(publicKeys: [SecKey]) {
        self.pinnedPublicKeys = publicKeys
    }

    func evaluate(_ trust: SecTrust, forHost host: String) throws {
        guard SecTrustEvaluateWithError(trust, nil) else {
            throw AFError.serverTrustEvaluationFailed(reason: .noPublicKeysFound)
        }

        for index in 0..<SecTrustGetCertificateCount(trust) {
            if let certificate = SecTrustGetCertificateAtIndex(trust, index),
               let serverPublicKey = SecCertificateCopyKey(certificate) {
                for pinnedKey in pinnedPublicKeys {
                    if serverPublicKey == pinnedKey {
                        return // Success if any key matches
                    }
                }
            }
        }

        throw AFError.serverTrustEvaluationFailed(reason: .noPublicKeysFound)
    }
}

extension String {
    func base64DecodedData() -> Data? {
        let base64String = self
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        return Data(base64Encoded: base64String)
    }
}

class PublicKeyPinningServerTrustManager: ServerTrustManager {
    private let domainsToPublicKeyStrings: [String: [String]]
    
    init(domainsToPublicKeyStrings: [String: [String]]) {
        self.domainsToPublicKeyStrings = domainsToPublicKeyStrings
        super.init(evaluators: [:])
    }
    
    override func serverTrustEvaluator(forHost host: String) -> ServerTrustEvaluating? {
        guard let publicKeyStrings = domainsToPublicKeyStrings[host] else {
            return nil
        }
        return PublicKeysTrustEvaluator(keys: publicKeys(from: publicKeyStrings), performDefaultValidation: true, validateHost: true)
    }
    
    private func publicKeys(from publicKeyStrings: [String]) -> [SecKey] {
        return publicKeyStrings.compactMap { createSecKey(from: $0) }
    }
    
    func createSecKey(from base64String: String) -> SecKey? {
        guard let keyData = base64String.base64DecodedData() else { return nil }

        let options: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048
        ]
        
        var error: Unmanaged<CFError>?
        let secKey = SecKeyCreateWithData(keyData as CFData, options as CFDictionary, &error)
        
        if let error = error {
            print("Error creating public key: \(error.takeRetainedValue())")
        }
        
        return secKey
    }
}
