//
//  HomeController.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 04/04/2022.
//

import Foundation
import UIKit
import Lottie
import AgoraRtmKit

// MARK: - ShowAlertProtocol
protocol ShowAlertProtocol: UIViewController {
    func showAlert(_ message: String, handler: ((UIAlertAction) -> Void)?)
    func showAlert(_ message: String)
}

extension ShowAlertProtocol {
    func showAlert(_ message: String, handler: ((UIAlertAction) -> Void)?) {
        view.endEditing(true)
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
        present(alert, animated: true, completion: nil)
    }
    
    func showAlert(_ message: String) {
        showAlert(message, handler: nil)
    }
}

// MARK: - HomeController

class HomeController: UITableViewController, ShowAlertProtocol  {
    var data: String?

    let starAnimationView = AnimationView(name: "online")
    
    var onlineList : Set = Set<String>()
    let userDefaults = UserDefaults.standard
    var rtmChannel: AgoraRtmChannel?
    var friends : [Friend] = []

    override func viewWillAppear(_ animated: Bool) {
        //Check if the user is logged in
        if (!userDefaults.getLoggedInStatus()) {
            let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginController = storyBoard.instantiateViewController(withIdentifier: "LoginVC")
            loginController.modalPresentationStyle = .fullScreen
            self.present(loginController, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (AgoraRtm.status == .online) {
            
            AgoraRtm.updateKit(delegate: self)

            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            navigationController?.isNavigationBarHidden = false
            self.navigationController?.navigationBar.topItem?.title = "Friends List"
                    
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action:  #selector(getFriends), for: .valueChanged)
            self.tableView.refreshControl = refreshControl
            self.tableView.delegate = self
            self.tableView.dataSource = self
            guard let data = data else { return }
        } else{
            login()
            getToken()
        }
    }
    
    func generateChannelName () -> String {
        let uuid = UUID().uuidString
        return uuid
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
   override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = friends[indexPath.row].name
        
        if (onlineList.contains(String(self.friends[indexPath.row]._id))) {
            let starAnimationView = AnimationView(name: "online")
            starAnimationView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
            cell.accessoryView = starAnimationView
            starAnimationView.play()
            
        } else{
            cell.accessoryView = .none
      }
        return cell
    }
    
    override func tableView(_ tableView : UITableView, didSelectRowAt indexPath: IndexPath) {
        let chats = ChatController()
        chats.friendName = self.friends[indexPath.row].name
        chats.friendID = String(self.friends[indexPath.row]._id)
        self.navigationController?.pushViewController(chats, animated: true)
    }
    
    @IBAction func logoutButton(_ sender: UIBarButtonItem) {
        userDefaults.removeObject(forKey: UserDefaults.UserDefaultsKeys.userId.rawValue)
        userDefaults.removeObject(forKey: UserDefaults.UserDefaultsKeys.userName.rawValue)
        userDefaults.removeObject(forKey: UserDefaults.UserDefaultsKeys.userEmail.rawValue)
        userDefaults.removeObject(forKey: UserDefaults.UserDefaultsKeys.isLoggedIn.rawValue)
        self.friends.removeAll()
        self.tableView.reloadData()
        if (!userDefaults.getLoggedInStatus()) {
            let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginController = storyBoard.instantiateViewController(withIdentifier: "LoginVC")
            loginController.modalPresentationStyle = .fullScreen
            self.present(loginController, animated: true, completion: nil)
        }
    }

    // MARK: - Utilities

    func getToken() {
        let userAcc = userDefaults.getUserId() ?? 00
        
        let api = RESTHandler<FriendsService>()
        api.load(REST: .getMessageToken(account: String(userAcc) ,
                                        channelName: "Meets",
                                        role: "publisher",
                                        expiryTime: "10000"))
                                        { result in
            switch result {
            case .success(let resp):
                print(resp)
                let stringValue = String(decoding: resp, as: UTF8.self)
                let jsonData = Data(stringValue.utf8)
                let decoder = JSONDecoder()
                do {
                    let token = try decoder.decode([String : String].self, from: jsonData)
                    let msgToken = token["token"] ?? ""
                    if (msgToken.count > 0) {
                        self.userDefaults.setMsgToken(value: msgToken)
                        DispatchQueue.main.async {
                            self.getFriends()
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            case .failure(let error):
                print(error.localizedDescription)
            case .empty:
                print("No data")
            }
        }

    }
    
    @objc func getFriends() {
        
        let api = RESTHandler<FriendsService>()

        api.load(REST: .friends) { [self] result in
            switch result {
            case .success(let resp):
                print(resp)
                
                let stringValue = String(decoding: resp, as: UTF8.self)
                let jsonData = Data(stringValue.utf8)
                let decoder = JSONDecoder()
                do {
                    var people = try decoder.decode([Friend].self, from: jsonData)
                    
                    people.removeAll(where: { (item: Friend) -> Bool in
                       return item._id == self.userDefaults.getUserId()
                     })
                    
                    self.friends = people
                    print(people)
                } catch {
                    print(error.localizedDescription)
                }
                    //On successful registration
                    DispatchQueue.main.async {
                        if ( self.friends.count == 0) {
                            self.showAlert("Its empty here. Invite your friends to chat")
                        } else{
                            self.refreshControl?.endRefreshing()
                        }
                        self.tableView.reloadData()
                        checkPeerOnlineStatus()
                    }
                
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    
                }
            case .empty:
                print("No data")
            }
        }
    }
    
    // MARK: - RTM calls
    func login() {
        let userId = userDefaults.getUserId()
        let account = "\(userId ?? 0)"
        
        AgoraRtm.updateKit(delegate: self)
        AgoraRtm.current = account
        AgoraRtm.oneToOneMessageType = .offline

        AgoraRtm.kit?.login(byToken: userDefaults.getMsgToken(), user: account) { [unowned self] (errorCode) in
            guard errorCode == .ok else {
                self.showAlert("login error: \(errorCode.rawValue)")
                return
            }
            
            AgoraRtm.status = .online
            createChannel("Meets")

            DispatchQueue.main.async {
                self.setStatusOnline()
                self.getFriends();
            }
        }
    }
    
    func setStatusOnline() {
        // Create Animation object
        let jsonName = "online"
        let animation = Animation.named(jsonName)

        // Load animation to AnimationView
        let onlineView = AnimationView(animation: animation)
        onlineView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        onlineView.loopMode = .loop
        // Add animationView as subview
//        view.addSubview(onlineView)

        let statusView = UIView(frame: CGRect.init(x: 0, y: 0, width: 40, height: 40))
        statusView.addSubview(onlineView)

        let barButtonItem = UIBarButtonItem(customView: statusView)
        self.navigationItem.rightBarButtonItem = barButtonItem
        onlineView.play()
    }
    
    func logout() {
        guard AgoraRtm.status == .online else {
            return
        }
        
        AgoraRtm.kit?.logout(completion: { (error) in
            guard error == .ok else {
                return
            }
            AgoraRtm.status = .offline
        })
    }
    
}

// MARK: Home controller extension
private extension HomeController {
    func createChannel(_ channel: String) {
        let errorHandle = { [weak self] (action: UIAlertAction) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.navigationController?.popViewController(animated: true)
        }
        
        guard let rtmChannel = AgoraRtm.kit?.createChannel(withId: channel, delegate: self) else {
            showAlert("join channel fail", handler: errorHandle)
            return
        }
        
        rtmChannel.join { [weak self] (error) in
            if error != .channelErrorOk, let strongSelf = self {
                strongSelf.showAlert("join channel error: \(error.rawValue)", handler: errorHandle)
            }
        }
        
        self.rtmChannel = rtmChannel
    }
    
    func leaveChannel() {
        rtmChannel?.leave { (error) in
            print("leave channel error: \(error.rawValue)")
        }
    }
}

// MARK: AgoraRtmDelegate
extension HomeController: AgoraRtmDelegate {
    
    func checkPeerOnlineStatus() {
        for (index, element) in friends.enumerated() {
          print("Item \(index): \(element)")
            AgoraRtm.kit?.queryPeersOnlineStatus([String(element._id)], completion:{ (peerStatus, error)  in
                guard error == .ok else {
                    return
                }
                DispatchQueue.main.async { [unowned self] in
                    if (peerStatus![0].state == AgoraRtmPeerOnlineState.online) {
                        onlineList.insert(String(index))
                        let indexPath = IndexPath(row:(index ) as Int, section:0)
                        tableView.reloadRows(at: [indexPath] , with: .automatic)
                    }
                }
            })
        }
    }
}

// MARK: AgoraRtmCallDelegate
extension HomeController: AgoraRtmCallDelegate {
    // Todo: Handle the incoming calls using RTM Call Delegate
}

// MARK: AgoraRtmChannelDelegate
extension HomeController: AgoraRtmChannelDelegate {
    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        tableView.reloadData()
        let userId = Int(member.userId)
        let index = self.friends.firstIndex { $0._id == userId }
        onlineList.insert(member.userId)
        
        DispatchQueue.main.async { [unowned self] in
            let indexPath = IndexPath(row:(index ?? 0) as Int, section:0)
            tableView.reloadRows(at: [indexPath] , with: .automatic)
           
        }
    }
    
    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        let userId = Int(member.userId)
        let index = self.friends.firstIndex { $0._id == userId }

        if let elemIndex = onlineList.firstIndex(of: member.userId) {
            onlineList.remove(at: elemIndex)
        }

        DispatchQueue.main.async { [unowned self] in
            let indexPath = IndexPath(row:(index ?? 0) as Int, section:0)
            tableView.reloadRows(at: [indexPath] , with: .automatic)
        }
    }
    
}


