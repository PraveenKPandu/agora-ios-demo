//
//  Message.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 07/04/2022.
//

import Foundation
import MessageKit

class Message {    
    let user: ChatUser
    let text: String
    let messageId: String
    let sentDate: Date
    
    init(user: ChatUser, text: String, messageId: String, sentDate: Date) {
        self.user = user
        self.text = text
        self.messageId = messageId
        self.sentDate = sentDate
    }
}

extension Message: MessageType {
    
    var sender: SenderType {
        return Sender(id: user.senderId, displayName: user.displayName)
    }
    
    var kind: MessageKind {
        return .text(text)
    }
        
}
