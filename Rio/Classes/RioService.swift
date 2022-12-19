//
//  RBSService.swift
//  RBS
//
//  Created by Baran Baygan on 19.11.2020.
//


import Foundation
import Moya
import ObjectMapper
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
            return "/\(request.projectId ?? "")/AUTH/refreshToken"
        case .authWithCustomToken(let request):
            return "/\(request.projectId ?? "")/AUTH/authWithCustomToken"
        case .signout(let request):
            return "/\(request.projectId ?? "")/AUTH/signOut"
        }
    }
    
    var body: [String:Any] {
        switch self {
        case .executeAction(let request):
            if let payload = request.payload {
                return payload
            }
            return [:]
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
        case .getAnonymToken(let request):
            return ["projectId": request.projectId ?? ""]
        case .refreshToken(let request):
            return ["refreshToken": request.refreshToken ?? ""]
        case .authWithCustomToken(let request):
            return ["customToken": request.customToken ?? ""]
        case .signout(let request):
            return ["_token": request.accessToken ?? ""]
            
        case .executeAction(let request):
            
            if cloudObjectActions.contains(request.actionName ?? "") {
                var parameters: [String: Any] = [:]
                if let token = request.accessToken {
                    parameters["_token"] = token
                }
                
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
                let accessToken = request.accessToken != nil ? request.accessToken! : ""
                if(self.isGetAction(action)) {
                    let payload: [String: Any] = request.payload == nil ? [:] : request.payload!
                    
                    var parameters =  [
                        "auth": accessToken,
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
                    var parameters = ["auth": accessToken]
                    if let culture = request.culture {
                        parameters["culture"] = culture
                    }
                    
                    return parameters
                }
            } else {
                return [:]
            }
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
        headers["rio-sdk-version"] = "0.0.46"
        
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
            
            headers["Content-Type"] = "application/json"
            break
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
    var dict: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
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
