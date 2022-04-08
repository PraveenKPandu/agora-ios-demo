//
//  AgoraRtm.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 06/04/2022.
//

import Foundation
import AgoraRtmKit

enum LoginStatus {
    case online, offline
}

enum OneToOneMessageType {
    case normal, offline
}

class AgoraRtm: NSObject {
    static let kit = AgoraRtmKit(appId: Keys.AppID, delegate: nil)
    static var current: String?
    static var status: LoginStatus = .offline
    static var oneToOneMessageType: OneToOneMessageType = .normal
    static var offlineMessages = [String: [AgoraRtmMessage]]()
    
    static func updateKit(delegate: AgoraRtmDelegate) {
        guard let kit = kit else {
            return
        }
        kit.agoraRtmDelegate = delegate
    }
    
    static func add(offlineMessage: AgoraRtmMessage, from user: String) {
        guard offlineMessage.isOfflineMessage else {
            return
        }
        var messageList: [AgoraRtmMessage]
        if let list = offlineMessages[user] {
            messageList = list
        } else {
            messageList = [AgoraRtmMessage]()
        }
        messageList.append(offlineMessage)
        offlineMessages[user] = messageList
    }
    
    static func getOfflineMessages(from user: String) -> [AgoraRtmMessage]? {
        return offlineMessages[user]
    }
    
    static func removeOfflineMessages(from user: String) {
        offlineMessages.removeValue(forKey: user)
    }
}

