//
//  Message.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 07/04/2022.
//

import Foundation
import MessageKit


struct Msg {

    var messageId: String
    var sender: SenderType {
        return user
    }
//    var sentDate: Date
//    var kind: MessageKind

    var user: Sender
    
    
}
