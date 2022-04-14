//
//  VideoChatViewController.swift
//  Agora iOS Tutorial
//
//  Created by James Fang on 7/14/16.
//  Copyright © 2016 Agora.io. All rights reserved.
//

import UIKit
import AgoraRtcKit

// MARK: - VideoVC delegate implementation

protocol VideoVCDelegate: NSObjectProtocol {
    func videoChat(_ vc: VideoChatViewController, didEndChatWith uid: UInt)
}

// MARK: - UIViewController
class VideoChatViewController: UIViewController {
    @IBOutlet weak var localContainer: UIView!
    @IBOutlet weak var remoteContainer: UIView!
    @IBOutlet weak var remoteVideoMutedIndicator: UIImageView!
    @IBOutlet weak var localVideoMutedIndicator: UIView!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var incallStats : UILabel!
    weak var delegate: VideoVCDelegate?
    
    

    let userDefaults = UserDefaults.standard
    var friendId : UInt!
    
    var agoraKit: AgoraRtcEngineKit!
    var localVideo: AgoraRtcVideoCanvas?
    var remoteVideo: AgoraRtcVideoCanvas?
    
    var isRemoteVideoRender: Bool = true {
        didSet {
            if let it = localVideo, let view = it.view {
                if view.superview == localContainer {
                    remoteVideoMutedIndicator.isHidden = isRemoteVideoRender
                    remoteContainer.isHidden = !isRemoteVideoRender
                } else if view.superview == remoteContainer {
                    localVideoMutedIndicator.isHidden = isRemoteVideoRender
                }
            }
        }
    }
    
    var isLocalVideoRender: Bool = false {
        didSet {
            if let it = localVideo, let view = it.view {
                if view.superview == localContainer {
                    localVideoMutedIndicator.isHidden = isLocalVideoRender
                } else if view.superview == remoteContainer {
                    remoteVideoMutedIndicator.isHidden = isLocalVideoRender
                }
            }
        }
    }
    
    var isStartCalling: Bool = true {
        didSet {
            if isStartCalling {
                micButton.isSelected = false
            }
            micButton.isHidden = !isStartCalling
            cameraButton.isHidden = !isStartCalling
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // This is our usual steps for joining
        // a channel and starting a call.
        initializeAgoraEngine()
        setupVideo()
        setupLocalVideo()
        getToken()
        
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func initializeAgoraEngine() {
        // init AgoraRtcEngineKit
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: Keys.AppID, delegate: self)
    }

    func setupVideo() {
        // In simple use cases, we only need to enable video capturing
        // and rendering once at the initialization step.
        // Note: audio recording and playing is enabled by default.
        agoraKit.enableVideo()
        
        // Set video configuration
        // Please go to this page for detailed explanation
        // https://docs.agora.io/cn/Voice/API%20Reference/java/classio_1_1agora_1_1rtc_1_1_rtc_engine.html#af5f4de754e2c1f493096641c5c5c1d8f
        agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(size: AgoraVideoDimension640x360,
                                                                             frameRate: .fps15,
                                                                             bitrate: AgoraVideoBitrateStandard,
                                                                             orientationMode: .adaptative))
    }
    
    func setupLocalVideo() {
        // This is used to set a local preview.
        // The steps setting local and remote view are very similar.
        // But note that if the local user do not have a uid or do
        // not care what the uid is, he can set his uid as ZERO.
        // Our server will assign one and return the uid via the block
        // callback (joinSuccessBlock) after
        // joining the channel successfully.
        let view = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: localContainer.frame.size))
        localVideo = AgoraRtcVideoCanvas()
        localVideo!.view = view
        localVideo!.renderMode = .hidden
        localVideo!.uid = 0
    
        localContainer.addSubview(localVideo!.view!)
        agoraKit.setupLocalVideo(localVideo)
        agoraKit.startPreview()
    }
    
    func joinChannel() {
        // Set audio route to speaker
        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        
        guard let uid = userDefaults.getUserId() else{
            return
        }
        
        // 1. Users can only see each other after they join the
        // same channel successfully using the same app id.
        // 2. One token is only valid for the channel name that
        // you use to generate this token.
        agoraKit.joinChannel(byToken: userDefaults.getVideoToken() , channelId: "Meets", info: nil, uid: UInt(uid)) { [unowned self] (channel, uid, elapsed) -> Void in
            // Did join channel "demoChannel1"
            self.isLocalVideoRender = true
        }
        isStartCalling = true
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func getToken() {
        let userAcc = userDefaults.getUserId() ?? 00
        
        let api = RESTHandler<FriendsService>()
        api.load(REST: .getVideoToken(uid: String(userAcc) ,
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
                    guard let msgToken = token["token"] else{
                        return
                    }
                    
                    if (msgToken.count > 0) {
                        self.userDefaults.setVideoToken(value: msgToken)
                        //On successful registration
                        DispatchQueue.main.async {
                            self.joinChannel()
                        }
                    }
                    
                } catch {
                    print(error.localizedDescription)
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
    
    
    func leaveChannel() {
        // leave channel and end chat
        agoraKit.leaveChannel(nil)
        
        guard let remoteUid = friendId else {
            fatalError("remoteUid nil")
        }
        
        delegate?.videoChat(self, didEndChatWith: remoteUid)

        isRemoteVideoRender = false
        isLocalVideoRender = false
        isStartCalling = false
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    @IBAction func didClickHangUpButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            leaveChannel()
            _ = removeFromParent(localVideo)
            localVideo = nil
            _ = removeFromParent(remoteVideo)
            remoteVideo = nil
            
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: ( {
                }))
            }
        } else {
            setupLocalVideo()
            joinChannel()
        }
    }
    
    @IBAction func didClickMuteButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        // mute local audio
        agoraKit.muteLocalAudioStream(sender.isSelected)
    }
    
    @IBAction func didClickSwitchCameraButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        agoraKit.switchCamera()
    }
    
    @IBAction func didClickLocalContainer(_ sender: Any) {
        switchView(localVideo)
        switchView(remoteVideo)
    }
    
    func removeFromParent(_ canvas: AgoraRtcVideoCanvas?) -> UIView? {
        if let it = canvas, let view = it.view {
            let parent = view.superview
            if parent != nil {
                view.removeFromSuperview()
                return parent
            }
        }
        return nil
    }
    
    func switchView(_ canvas: AgoraRtcVideoCanvas?) {
        let parent = removeFromParent(canvas)
        if parent == localContainer {
            canvas!.view!.frame.size = remoteContainer.frame.size
            remoteContainer.addSubview(canvas!.view!)
        } else if parent == remoteContainer {
            canvas!.view!.frame.size = localContainer.frame.size
            localContainer.addSubview(canvas!.view!)
        }
    }
}

// MARK: - AgoraRtcEngineDelegate

extension VideoChatViewController: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        isRemoteVideoRender = true

        var parent: UIView = remoteContainer
        if let it = localVideo, let view = it.view {
            if view.superview == parent {
                parent = localContainer
            }
        }

        // Only one remote video view is available for this
        // tutorial. Here we check if there exists a surface
        // view tagged as this uid.
        if remoteVideo != nil {
            return
        }

        let view = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: parent.frame.size))
        remoteVideo = AgoraRtcVideoCanvas()
        remoteVideo!.view = view
        remoteVideo!.renderMode = .hidden
        remoteVideo!.uid = uid
        parent.addSubview(remoteVideo!.view!)
        agoraKit.setupRemoteVideo(remoteVideo!)
    }
    
    
    /// Occurs when a remote user (Communication)/host (Live Broadcast) leaves a channel.
    /// - Parameters:
    ///   - engine: RTC engine instance
    ///   - uid: ID of the user or host who leaves a channel or goes offline.
    ///   - reason: Reason why the user goes offline
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid:UInt, reason:AgoraUserOfflineReason) {
        isRemoteVideoRender = false
        if let it = remoteVideo, it.uid == uid {
            _ = removeFromParent(it)
            remoteVideo = nil
        }
        
        DispatchQueue.main.async {
            self.leaveChannel()
            _ = self.removeFromParent(self.localVideo)
            self.localVideo = nil
            _ = self.removeFromParent(self.remoteVideo)
            self.remoteVideo = nil
            self.dismiss(animated: true, completion: ( {
            }))
        }
        
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportRtcStats stats: AgoraChannelStats) {
        
        var statsMeans : (Float, Float, Float) = StatsInfo.addnewValueToList(tx: stats.txKBitrate, rx: stats.rxKBitrate, lastmile: stats.lastmileDelay)
        
        
        incallStats.text = "Tx video Bitrate :\(statsMeans.0)  Rx video Bitrate: \(statsMeans.1) lastMile : \(statsMeans.2)"

    }
    
    
    
    /// Occurs when a remote user’s video stream playback pauses/resumes.
    /// - Parameters:
    ///   - engine: RTC engine instance
    ///   - muted: YES for paused, NO for resumed.
    ///   - byUid: User ID of the remote user.
    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted:Bool, byUid:UInt) {
        isRemoteVideoRender = !muted
    }
    
    /// Reports a warning during SDK runtime.
    /// - Parameters:
    ///   - engine: RTC engine instance
    ///   - warningCode: Warning code
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
     print(warningCode)
    }
    
    /// Reports an error during SDK runtime.
    /// - Parameters:
    ///   - engine: RTC engine instance
    ///   - errorCode: Error code
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
    }
}
