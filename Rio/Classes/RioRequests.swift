//
//  SignInAnonymRequest.swift
//  RBS
//
//  Created by Baran Baygan on 19.11.2020.
//

import Foundation
import ObjectMapper
import Moya

class GetAnonymTokenRequest : Mappable {
    var projectId: String?
    
    required init?(map: Map) { }
    
    init() { }
    
    func mapping(map: Map) {
        projectId <- map["projectId"]
    }
}

class RefreshTokenRequest : Mappable {
    var projectId: String?
    var refreshToken: String?
    var userId: String?
    
    required init?(map: Map) { }
    
    init() { }
    
    func mapping(map: Map) {
        projectId <- map["projectId"]
        refreshToken <- map["refreshToken"]
        userId <- map["userId"]
    }
}

class AuthWithCustomTokenRequest : Mappable {
    var projectId: String?
    var customToken: String?
    var userId: String?
    
    required init?(map: Map) { }
    
    init() { }
    
    func mapping(map: Map) {
        projectId <- map["projectId"]
        customToken <- map["customToken"]
        userId <- map["userId"]
    }
}

class SignOutRequest : Mappable {
    var projectId: String?
    var accessToken: String?
    var userId: String?
    
    required init?(map: Map) { }
    
    init() { }
    
    func mapping(map: Map) {
        projectId <- map["projectId"]
        accessToken <- map["accessToken"]
        userId <- map["userId"]
    }
}

class ExecuteActionRequest : Mappable {
    
    var projectId: String?
    var accessToken:String?
    var actionName:String?
    var payload: [String:Any]?
    var headers: [String:String]?
    var culture: String?
    var classID: String?
    var instanceID: String?
    var keyValue: (key: String, value: String)?
    var httpMethod: Moya.Method?
    var method: String?
    var queryString: [String: Any]?
    
    required init?(map: Map) { }
    
    init() {
    
    }
    
    func mapping(map: Map) {
        projectId <- map["projectId"]
        accessToken <- map["accessToken"]
        actionName <- map["actionName"]
        payload <- map["payload"]
        headers <- map["headers"]
        culture <- map["culture"]
    }
}
