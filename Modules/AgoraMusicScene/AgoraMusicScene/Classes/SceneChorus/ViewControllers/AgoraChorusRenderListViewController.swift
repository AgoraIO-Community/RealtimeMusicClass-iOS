//
//  AgoraChorusRenderListViewController.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/1/27.
//

import UIKit
import AgoraRtmKit
import AgoraRtcKit
import AGEVideoLayout
import AgoraMusicEngine

class AgoraChorusRenderListViewController: UIViewController {
    
    fileprivate var container: AGEVideoContainer!
    
    public lazy var suggestHeight: CGFloat = {
        let width = UIScreen.main.bounds.width
        if UIDevice.current.userInterfaceIdiom == .pad {
            let sigleWidth = (width - 14*2 - 10*5)/6.0
            let sigleHeight = sigleWidth * 145.0/109.0
            return sigleHeight + 10*2
        } else {
            let sigleWidth = (width - 14*2 - 10*2)/3.0
            let sigleHeight = sigleWidth * 145.0/109.0
            return sigleHeight*2 + 10*3
        }
    }()
    
    var videoViews: [VideoView] = [VideoView]() {
        didSet {
            if UIDevice.current.userInterfaceIdiom == .pad {
                container.layoutGrid(views: videoViews, row: 6, rank: 1, offSet: 10)
            } else {
                container.layoutGrid(views: videoViews, row: 3, rank: 2, offSet: 10)
            }
        }
    }
    
    var users: [UserInfo] = [UserInfo]()
    
    var videos: [VideoModel] = [VideoModel]()
    
    private var localUser: UserInfo?
    
    private var core: AgoraMusicCore
    
    //进入后台前，视频被关闭了 state off
    private var videoHasBeenStoped: Bool = false
    
    deinit {
        print("\(self.classForCoder): \(#function)")
        NotificationCenter.default.removeObserver(self)
    }
    
    init(core: AgoraMusicCore) {
        self.core = core
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createViews()
        self.createConstrains()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        let NotifyMsgName = NSNotification.Name(rawValue:"LOCALCAMARASTATE")
        NotificationCenter.default.addObserver(self, selector:#selector(notifiAction(notification:)),
                                                       name: NotifyMsgName, object: nil)
        
        self.core.room.addListener(self)
        self.core.user.addListener(self)
        loadSession()
        
    }
    
    private func loadSession() {
        for _ in 0..<6 {
            let hostingView = VideoView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            hostingView.closure = {[weak self] info in
                self?.showUserControl(with: info)
            }
            
            let user: UserInfo = UserInfo()
            let video: VideoModel = VideoModel()
            let userSession = VideoSession(uid: "0", type: .remote, videoView: hostingView)
            userSession.canvas.renderMode = .hidden
            hostingView.userInfo = user
            hostingView.state = .noMicState
            videoViews.append(hostingView)
            users.append(user)
            videos.append(video)
        }
    }
    
    private func showUserControl(with info: UserInfo) {
        
        guard let localUser = localUser else {
            return
        }
        
        guard let _ = info.media else {return}
        
        if localUser.role == .owner && info.isLocalUser == false{
            AgoraUserCtrlAlerController.showInViewController(self, user: info, core: self.core)
        }
    }
    
    @objc private func notifiAction(notification:NSNotification){
         
        guard let userinfo = notification.userInfo else {return}
        guard let state: Int = userinfo[AnyHashable("state")] as? Int else {return}
        
        videoHasBeenStoped = state == 0
             
     }
    
}

extension AgoraChorusRenderListViewController: AgoraMusicRoomHandler{
    
    func onClassJoined() {
        let userList: [UserInfo] = self.core.user.userList
        if userList.count == 0 {return}
        
        localUser = self.core.user.getLocalUser()
        
        for user in userList {
            if user.role == .audience {return}
            loadVideo(with: user)
        }
    }
    
}

extension AgoraChorusRenderListViewController: AgoraMusicUserHandler {
    
    func onRemoteUserJoined(user: UserInfo) {
        
        if user.role == .audience {return} //旁听不处理
        
        loadVideo(with: user)
        
    }
    
    func onUserInfoUpdated(user: UserInfo) {
        
        if user.role == .audience {return} //旁听不处理
        
        loadVideo(with: user)
        
    }
    
    func onRemoteUserLeaved(user: UserInfo) {
        
        if user.role == .audience {return} //旁听不处理
        
        guard let media = user.media else {return}
        if media.index >= videoViews.count {return}
        
        let videoView: VideoView = videoViews[media.index]
        users[media.index] = user
        videoView.userInfo = user
        videoView.state = .offline
        
        
        //恢复离开用户的渲染状态
//        var video: VideoModel = videos[media.index]
//        video.hasBeenRendered = false
//        videos[media.index] = video
    }
    
    func loadVideo(with userInfo: UserInfo) {
        
        guard let media = userInfo.media else {return}
        
        if media.index >= videoViews.count {return}
        
        let videoView: VideoView = videoViews[media.index]
        users[media.index] = userInfo
        videoView.state = media.isOnline == true ? .online : .offline
        videoView.userInfo = userInfo
        videoViews[media.index].userInfo = userInfo
        
//        let renderVideo: VideoModel = videos[userInfo.media!.index]
//        if renderVideo.hasBeenRendered == true {return} //已经渲染过的视频直接跳过
        
        if (media.streamId ?? "").isEmpty {return}
        
        let userSession = VideoSession(uid: media.streamId!, type: userInfo.isLocalUser ? .local : .remote, videoView: videoView.mainView)
        userSession.canvas.renderMode = .hidden
        
        if userInfo.isLocalUser {
            let _ = self.core.engine.setupLocalVideo(local: userSession.canvas)
        } else {
            let _ = self.core.engine.setupRemoteVideo(remote: userSession.canvas)
        }
        
//        var video: VideoModel = VideoModel()
//        video.Name = userInfo.userName
//        video.StreamID = media.streamId!
//        video.hasBeenRendered = true
//        videos[media.index] = video
    }
    
    func onUserVoiceUpdate(user: UserInfo, value: Int) {
        for i in videoViews {
            if i.userInfo?.userName == user.userName {
                i.volume = value
            }
        }
    }
    
    func onUserReceiveFirstFrame(user: UserInfo) {
        updateVideoState(with: user)
    }
    
    fileprivate func updateVideoState(with user: UserInfo) {
        
        guard let media = user.media else {return}
        let index = media.index
        if index >= videoViews.count {return}
        guard let userinfo = videoViews[index].userInfo else {return}
        guard let viewMedia = userinfo.media else {return}
        if viewMedia.streamId == media.streamId {
            videoViews[index].mainView.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {[weak self] in
                self?.videoViews[index].bgView.isHidden = true
            }
        }
    }
    
}

// MARK: - Creations
private extension AgoraChorusRenderListViewController {
    func createViews() {
        
        container = AGEVideoContainer()
        self.view.addSubview(container)
    }
    
    func createConstrains() {
        container.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
    
    // 将进入前台通知
    @objc func appWillEnterForeground(){
        if videoHasBeenStoped == true {
            return
        }

        self.core.user.setLocalCameraState(isOn: true, complete: nil)
    }
    //应用程序确实进入了后台
    @objc func appDidEnterBackground(){
        if videoHasBeenStoped == true {
            return
        }

        self.core.user.setLocalCameraState(isOn: false, complete: nil)
    }
}

extension AGEVideoContainer {
    
    func layoutGrid(views: [UIView], row: Int, rank: Int, offSet: CGFloat) {
        let count = views.count
        
        var layout: AGEVideoLayout
        
        if count > row * rank  {
            return
        } else {
            let realW: CGFloat = self.bounds.size.width - CGFloat(Int(offSet) * (row + 1))
            let realH: CGFloat = self.bounds.size.height - CGFloat(Int(offSet) * (rank + 1))
            let widthP: CGFloat = realW / CGFloat(row) / self.bounds.size.width
            let heightP: CGFloat =  realH  / CGFloat(rank) / self.bounds.size.height
            
            layout = AGEVideoLayout(level: 0)
                .startPoint(x: 0, y: 0)
                .itemSize(.scale(CGSize(width: widthP, height: heightP)))
                .interitemSpacing(offSet)
                .lineSpacing(offSet)
        }
        
        self.listCount { (level) -> Int in
            return views.count
        }.listItem { (index) -> UIView in
            return views[index.item]
        }
        
        self.removeAllLayouts()
        self.setLayouts([layout], animated: true)
    }
    
}
