//
//  RBSResponses.swift
//  RBS
//
//  Created by Baran Baygan on 19.11.2020.
//

import Foundation
import Moya


class GetTokenResponse: Decodable {
    
    var accessToken: String?
    var refreshToken: String?
    
    
    private enum CodingKeys: String, CodingKey { case accessToken, refreshToken }
    
    var tokenData:RioTokenData? {
        get {
            if let accessToken = self.accessToken, let refreshToken = self.refreshToken {
                return RioTokenData(JSON: [
                    "isAnonym": true,
                    "accessToken": accessToken,
                    "refreshToken": refreshToken
                ])
            } else {
                return nil
            }
            
        }
    }
}


class ExecuteActionResponse: Decodable {
    
    var accessToken: String?
    var refreshToken: String?
    
    
    private enum CodingKeys: String, CodingKey { case accessToken, refreshToken }
    
    var tokenData:RioTokenData? {
        get {
            if let accessToken = self.accessToken, let refreshToken = self.refreshToken {
                return RioTokenData(JSON: [
                    "isAnonym": true,
                    "accessToken": accessToken,
                    "refreshToken": refreshToken
                ])
            } else {
                return nil
            }
            
        }
    }
}


enum NetworkError : Error {
    case connection_lost
}


class BaseErrorResponse: Decodable, Error {
    
    var code: Int? // unknown
    var httpStatusCode: Int? // unknown
    var cloudObjectResponse: RioCloudObjectResponse?
    var moyaError: MoyaError?
    
    private enum CodingKeys: String, CodingKey { case code, message, httpStatusCode, moyaError }
    
    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.httpStatusCode = try? container.decode(Int.self, forKey: .httpStatusCode)
            self.code = try? container.decode(Int.self, forKey: .code)
        } catch (let error) {
            print(error)
        }
    }
    
    init() {
        
    }
    
}



//
//extension PrimitiveSequence where Trait == SingleTrait, Element == Response {
//
//    /// If the Response status code is in the 200 - 299 range, it lets the Response through.
//    /// If it's outside that range, it tries to map the Response into an BaseErrorResponse
//    /// object and throws an error with the appropriate message from BaseErrorResponse.
//    func catchBaseError() -> Single<Element> {
//        return flatMap { response in
//            if (200...299).contains(response.statusCode) {
//                if(response.data.count == 0) {
//                    // Empty respnse but status code is okay
//                    return .just(Element(statusCode: response.statusCode, data: "{}".data(using: .utf8)!))
//                }
//
//                return .just(response)
//            }
//
//            if response.statusCode == 401 {
//                // Unauthorized
//            }
//
//            do {
//                let baseErrorResponse = try response.map(BaseErrorResponse.self)
//                baseErrorResponse.httpStatusCode = response.statusCode
//
//                throw baseErrorResponse
//            }
//            catch let error as BaseErrorResponse {
//                throw error
//            }
//            catch let e {
//                throw e
//            }
//        }
//    }
//
//    func parseJSON() -> Single<[Any]?> {
//        return flatMap { response in
//
//            do {
//                // make sure this JSON is in the format we expect
//
//                if let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? [Any] {
//                    return .just(json)
//                }
//            } catch let error as NSError {
//                print("Failed to load: \(error.localizedDescription)")
//            }
//
//            let baseErrorResponse = try response.map(BaseErrorResponse.self)
//            baseErrorResponse.httpStatusCode = response.statusCode
//
//            throw baseErrorResponse
//
////            let errorResponse:[String:[Any]] = [
////                "Error": [[
////                    ["StatusCode": response.statusCode],
////                    ["Error": response.description]
////                ]]
////            ]
////
////            return .just(errorResponse)
//        }
//    }
//}
