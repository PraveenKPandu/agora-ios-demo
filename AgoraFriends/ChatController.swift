//
//  ChatController.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 07/04/2022.
//

import Foundation


import AgoraRtmKit
import UIKit
import MessageKit
import InputBarAccessoryView

// MARK: - ChatController
class ChatController: MessagesViewController, ShowAlertProtocol, MessagesLayoutDelegate {
    
    var messageList: [Message] = []
    
    var friendName : String = ""
    var friendID : String = ""
    var rtmChannel: AgoraRtmChannel?
    let userDefaults = UserDefaults.standard
    var pickerData: [String] = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
            self.pickerData = ["Gift 1", "Gift 2", "Item 3"];

            messagesCollectionView.messagesDataSource = self
            messagesCollectionView.messagesLayoutDelegate = self
            messagesCollectionView.messagesDisplayDelegate = self
            messageInputBar.delegate = self
            login()
        addVideoButton()
        addGiftButton()

    }
    
    func addVideoButton() {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "video"), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.addTarget(self, action: #selector(videoButtonClicked), for: .touchUpInside)
        let barButtonItem = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(red: 0, green: 0.813, blue: 0.449, alpha: 1.0)
        
        self.navigationController?.navigationBar.topItem?.title = self.friendName;
        subscribeToStatus()

    }
    
    override func viewWillAppear(_ animated: Bool) {
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unSubscribeToUser()
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.backgroundColor = .clear
    }
    
    func subscribeToStatus() {
        
            AgoraRtm.kit?.subscribePeersOnlineStatus([String(friendID)]) { [unowned self] (errorCode) in
                guard errorCode == .ok else {
                 self.showAlert("login error: \(errorCode.rawValue)")
                 return
                }
        }
    }
    
    func unSubscribeToUser() {
        AgoraRtm.kit?.unsubscribePeersOnlineStatus([String(friendID)]) { [unowned self] (errorCode) in
            guard errorCode == .ok else {
//             self.showAlert("login error: \(errorCode.rawValue)")
             return
            }
        DispatchQueue.main.async { [unowned self] in
            setStatusOffline()
            }
    }
    }
    
    
    @objc func videoButtonClicked(_ sender: Any) {
        let storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let videoController = storyboard.instantiateViewController(withIdentifier: "VideoVC") as? VideoChatViewController {
            videoController.modalPresentationStyle = .fullScreen
            videoController.friendId = UInt(friendID)
           present(videoController, animated: true, completion: nil)
        }
    }
}

// MARK: - MessagesDataSource
extension ChatController: MessagesDataSource {
    
    func currentSender() -> SenderType {
        let id : String = String(userDefaults.getUserId() ?? 0)
        let name : String = userDefaults.getUserName() ?? ""
        return ChatUser(senderId: id, displayName: name)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    
}

// MARK: - InputBarAccessoryViewDelegate
extension ChatController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        let sent = { [unowned self] (state: Int) in
            guard state == 0 else {
                switch state
                {
                case 4:
                    self.showAlert("User is not online: \(state)", handler: { (_) in
                        self.view.endEditing(true)
                    })
                    return
                default:
                    self.showAlert("message send error: \(state)", handler: { (_) in
                        self.view.endEditing(true)
                    })
                    return
                }
            }
            
            let me = self.currentSender() as! ChatUser // currentSender()
            
            let newMessage = Message(user: me, text: text, messageId: UUID().uuidString, sentDate: Date())
            
            messageList.append(newMessage)
            self.messagesCollectionView.insertSections([self.messageList.count - 1])
            inputBar.inputTextView.text = ""
        }
        
        let rtmMessage = AgoraRtmMessage(text: text)

        let option = AgoraRtmSendMessageOptions()
        option.enableOfflineMessaging = (AgoraRtm.oneToOneMessageType == .offline ? true : false)
        
        AgoraRtm.kit?.send(rtmMessage, toPeer: String(friendID), sendMessageOptions: option, completion: { (error) in
            sent(error.rawValue)
        })
            
    }
    }

// MARK: - Custom delegate for Video VC
extension ChatController: VideoVCDelegate {
    func videoChat(_ vc: VideoChatViewController, didEndChatWith uid: UInt) {
        vc.dismiss(animated: true, completion: nil)
    }
}


// MARK: - MessagesDisplayDelegate

extension ChatController: MessagesDisplayDelegate {
    
    @objc private func giftButtonClicked() {
        
        let image = UIImage(named: "gift")
        guard let png = image!.pngData() else {
            // there is no PNG representation for the UIImage
            // you can also try jpegData
            return
        }
        // To be implemented
    }
    
    private func addGiftButton() {
        let cameraItem = InputBarButtonItem(type: .custom)
        cameraItem.image = UIImage(named: "gift")

      // 2
      cameraItem.addTarget(
        self,
        action: #selector(giftButtonClicked),
        for: .primaryActionTriggered)
      cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
      messageInputBar.leftStackView.alignment = .center
      messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)

      // 3
      messageInputBar
        .setStackViewItems([cameraItem], forStack: .left, animated: false)
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        if isFromCurrentSender(message: message) {
            return UIColor.init(red: 0.256, green: 0.351, blue: 0.418, alpha: 1.0)
        } else {
            return UIColor.init(red: 0.923, green: 0.938, blue: 0.946, alpha: 1.00)
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let userId : String = String(userDefaults.getUserId() ?? 0)
        switch message.sender.senderId {
        case userId:
            let avatar = Avatar(image: UIImage(named: "0"))
                avatarView.set(avatar: avatar)
        default:
            let avatar = Avatar(image: UIImage(named: "1"))
                avatarView.set(avatar: avatar)
        }
    }
    
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message) {
            return .white
        } else {
            return .black
        }
    }
}

// MARK: AgoraRtmDelegate
extension ChatController: AgoraRtmDelegate {
    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        switch reason {
            case .bannedByServer :
                self.showAlert("Banned by server: \(state.rawValue)")
            case .loginFailure:
                self.showAlert("Login failed. Try again: \(state.rawValue)") { [weak self] (_) in
                    getlogin()
                }
            default:
                print("Unknown error")
            }
        }
    
    func rtmKit(_ kit: AgoraRtmKit, messageReceived message: AgoraRtmMessage, fromPeer peerId: String) {
        let user = ChatUser(senderId: peerId, displayName: " ")
        let newMessage = Message(user: user, text: message.text, messageId: UUID().uuidString, sentDate: Date())
        messageList.append(newMessage)
    }
}


// MARK: AgoraRtmChannelDelegate
extension ChatController: AgoraRtmChannelDelegate {
    
    func channel(_ channel: AgoraRtmChannel, peersOnlineStatusChanged onlineStatus:[AgoraRtmPeerOnlineStatus] ) {
        let statuses : [AgoraRtmPeerOnlineStatus] = onlineStatus as [AgoraRtmPeerOnlineStatus]
        if (statuses[0].state == AgoraRtmPeerOnlineState.online) {
            setStatusOnline()
        } else{
            setStatusOffline()
        }
    }
    
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        let user = ChatUser(senderId: member.userId, displayName: " ")
        let newMessage = Message(user: user, text: message.text, messageId: UUID().uuidString, sentDate: Date())
        messageList.append(newMessage)
    }
}


// MARK: - ChatController extensions

private extension ChatController {
    
    func login() {
        AgoraRtm.updateKit(delegate: self)
        AgoraRtm.oneToOneMessageType = .offline
    }
    
    func setStatusOnline() {
        // This will change the navigation bar background color
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(red: 0, green: 0.813, blue: 0.449, alpha: 1.0)
    }
    
    func setStatusOffline() {
        // This will change the navigation bar background color
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(red: 0.917, green: 0.922, blue: 0.926, alpha: 1.0)
    }
    
}



