//
//  Session.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 06/04/2022.
//

import UIKit

extension UserDefaults
{
    enum UserDefaultsKeys : String
    {
        case isLoggedIn
        case userName
        case userEmail
        case token
        case userId
        case videoToken
        case msgToken
    }
        
        // MARK: - Set Functions
        func setisLoggedIn(value: Bool){
            set(value, forKey: UserDefaultsKeys.isLoggedIn.rawValue)
            synchronize()
        }
    
        func setUserName(value: String) {
            set(value, forKey: UserDefaultsKeys.userName.rawValue)
            synchronize()
        }

        func setUserEmail(value: String){
            set(value, forKey: UserDefaultsKeys.userEmail.rawValue)
            synchronize()
        }
    
        func setToken(value: String){
            set(value, forKey: UserDefaultsKeys.token.rawValue)
            synchronize()
        }

        func setUserId(value: Int) {
            set(value, forKey: UserDefaultsKeys.userId.rawValue)
            synchronize()
        }

        func setVideoToken(value: String) {
            set(value, forKey: UserDefaultsKeys.videoToken.rawValue)
            synchronize()
        }

        func setMsgToken(value: String) {
            set(value, forKey: UserDefaultsKeys.msgToken.rawValue)
            synchronize()
        }
    
        // MARK: - get Functions
        func getLoggedInStatus() -> Bool {
            return bool(forKey:  UserDefaultsKeys.isLoggedIn.rawValue)
        }
        
        func getUserName() -> String? {
            return value(forKey: UserDefaultsKeys.userName.rawValue) as? String
        }
    
        func getUserEmail() -> String? {
            return value(forKey: UserDefaultsKeys.userEmail.rawValue) as? String
        }
    
        func getToken() -> String? {
            return value(forKey: UserDefaultsKeys.token.rawValue) as? String
        }
    
        func getUserId() -> Int? {
            return value(forKey: UserDefaultsKeys.userId.rawValue) as? Int
        }

        func getVideoToken() -> String? {
            return value(forKey: UserDefaultsKeys.videoToken.rawValue) as? String
        }
    
        func getMsgToken() -> String? {
            return value(forKey: UserDefaultsKeys.msgToken.rawValue) as? String
        }
}

