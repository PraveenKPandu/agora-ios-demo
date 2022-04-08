//
//  FriendsService.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 06/04/2022.
//

import Foundation

enum FriendsService {
    case register (name: String, email: String, password : String)
    case login (email: String, password : String)
    case friends
    case getVideoToken (uid: String,  channelName : String,role : String, expiryTime : String)
    case getMessageToken (account: String, channelName : String, role : String, expiryTime : String)

}

extension FriendsService: REST {
    var baseURL: String {
        return "https://agora.praveen.uk/api"
    }
    
    var path: String {
        switch self {
            case .register(_, _, _):
                return "/api/register"
            case .login(_, _):
                return "/api/login"
        case .friends:
            return "/api/friends"
        case .getVideoToken(_, _, _, _):
                return "/api/get_rtc_token"
        case .getMessageToken(_, _, _, _):
                return "/api/get_rtm_token"
            }
        }

        var parameters: [String: Any]? {
            // default params
            var params: [String: Any] = [:]
            
            switch self {
            case .register(let name, let email, let password):
                params["password"] = password
                params["email"] = email
                params["name"] = name
            case .login(let email, let password):
                params["email"] = email
                params["password"] = password
            case .friends:
                break
            case .getVideoToken(let uid, let channelName,let role, let expiryTime):
                params["uid"] = uid
                params["role"] = role
                params["expireTime"] = expiryTime
                params["channelName"] = channelName
            case .getMessageToken(let account, let channelName, let role, let expiryTime):
                params["account"] = account
                params["role"] = role
                params["expireTime"] = expiryTime
                params["channelName"] = channelName
            }
            return params
        }

        var method: APIMethod {
            switch self {
            case .register(_, _, _):
                return .get
            case .login(_, _):
                return .get
            case .friends:
                return .get
            case .getVideoToken(_, _, _, _):
                return .get
            case .getMessageToken(_, _, _, _):
                return .get
        }
    }
    
}
