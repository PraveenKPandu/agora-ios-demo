//
//  UserInfo.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 05/04/2022.
//

import Foundation
import MessageKit

struct User: Codable {
    let name : String
    let email : String
    let token : String
    let id : Int
}
