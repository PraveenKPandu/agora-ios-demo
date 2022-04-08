//
//  ChatUser.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 07/04/2022.
//

import Foundation
import MessageKit

class ChatUser: SenderType {
    var senderId: String
    var displayName: String
    init(senderId: String, displayName: String) {
        self.senderId = senderId
        self.displayName = displayName
    }
    
}
