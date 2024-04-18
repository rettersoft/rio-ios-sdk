//
//  SignInAnonymRequest.swift
//  RBS
//
//  Created by Baran Baygan on 19.11.2020.
//

import Foundation
import Moya

class GetAnonymTokenRequest: Codable {
    var projectId: String?
}

class RefreshTokenRequest: Codable {
    var projectId: String?
    var refreshToken: String?
    var userId: String?
}

class AuthWithCustomTokenRequest: Codable {
    var projectId: String?
    var customToken: String?
    var userId: String?
}

class SignOutRequest: Codable {
    var projectId: String?
    var accessToken: String?
    var userId: String?
    var type: String?
}

class ExecuteActionRequest {
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
    var path: String?
    var isStaticMethod: Bool?
}
