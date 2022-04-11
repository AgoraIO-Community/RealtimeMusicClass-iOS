//
//  AgoraChorusSceneViewController.swift
//  AgoraChorusScene
//
//  Created by Jonathan on 2022/1/27.
//

import UIKit
import SnapKit
import AgoraRtmKit
import AgoraRtcKit
import AGEVideoLayout
import AgoraMusicEngine
import AgoraViewKit

public class AgoraChorusSceneViewController: UIViewController {
    
    public var className: String?
    
    public var userName: String?
    /** 顶部栏*/
    private var topBar: AgoraChorusTopBar!
    /** 音乐、课件分页*/
    private var segmentController: AgoraChorusSegmentViewController!
    /** 歌词播放 控制器*/
    private var playerController: AgoraChorusPlayerViewController!
    /** 白板 控制器*/
    private var boardController: AgoraChorusWhiteBoardViewController!
    /** 视频渲染 控制器*/
    private var renderController: AgoraChorusRenderListViewController!
    /** 工具栏 控制器*/
    private var toolBarController: AgoraChorusToolBarViewController!
    /** 用户列表控制器*/
    private var userListController: AgoraUsersListController!
    /** 用户聊天控制器*/
    private var chatController: AgoraGroupChatAlertController!

    private var usersButton: GradientButton!
    
    private var core: AgoraMusicCore!
    
    deinit {
        print("\(self.classForCoder): \(#function)")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        if let className = self.className, let userName = self.userName {
            self.core = AgoraMusicCore(className: className, userName: userName)
        }
        
        self.createViews()
        self.createConstrains()
        
        self.core.room.addListener(self)
        self.core.user.addListener(self)
        self.core.room.joinClass()
    }
}

// MARK: - Private
extension AgoraChorusSceneViewController {
    @objc func onClickUserList(_ sender: UIButton) {
        self.present(self.userListController, animated: true, completion: nil)
    }
}
// MARK: - Actions
extension AgoraChorusSceneViewController {
    @objc func onClickBack() {
        self.core.room.leaveClass(reason: nil)
    }
}
// MARK: - AgoraChorusSegmentViewDelegate
extension AgoraChorusSceneViewController: AgoraChorusSegmentViewDelegate {
    func didSelectMusicSegment() {
        self.playerController.view.isHidden = false
        self.boardController.view.isHidden = true
    }
    func didSelectBoardSegment() {
        self.playerController.view.isHidden = true
        self.boardController.view.isHidden = false
    }
}
// MARK: - AgoraChorusToolBarDelegate
extension AgoraChorusSceneViewController: AgoraChorusToolBarDelegate {
    
    func onClickHelp() {
        AgoraToast.toast(msg: "功能开发中")
    }
    
    func onClickGroupChat() {
        self.present(self.chatController, animated: true, completion: nil)
    }
}

// MARK: - AgoraMusicRoomHandler
extension AgoraChorusSceneViewController: AgoraMusicRoomHandler {
    public func onClassInfoUpdated() {
        self.topBar.titleLabel.text = self.core.room.roomInfo?.className
    }
    
    public func onClassJoined() {
        let count = self.core.user.userList.count
        self.usersButton.setTitle(String(count), for: .normal)
    }
    
    public func onClassLeaved(reason: LeaveClassReason?) {
        guard let `reason` = reason else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        if reason.type == .kickOff {
            let alert = UIAlertController(title: "提示", message: "用户在其他设备登录", preferredStyle: .alert)
            let acton = UIAlertAction(title: "确定", style: .default) { alert in
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(acton)
            self.present(alert, animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
            AgoraToast.toast(msg: reason.msg)
        }
    }
}
// MARK: - AgoraMusicRoomHandler
extension AgoraChorusSceneViewController: AgoraMusicUserHandler {
    
    public func onRemoteUserJoined(user: UserInfo) {
        let count = self.core.user.userList.count
        self.usersButton.setTitle(String(count), for: .normal)
    }
    
    public func onRemoteUserLeaved(user: UserInfo) {
        let count = self.core.user.userList.count
        self.usersButton.setTitle(String(count), for: .normal)
    }
}

// MARK: - Creations
extension AgoraChorusSceneViewController {
    func createViews() {
        topBar = AgoraChorusTopBar(frame: .zero)
        topBar.backButton.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        self.view.addSubview(topBar)
        
        segmentController = AgoraChorusSegmentViewController(core: self.core)
        segmentController.delegate = self
        self.addChild(segmentController)
        self.view.addSubview(segmentController.view)
        
        playerController = AgoraChorusPlayerViewController(core: self.core)
        self.addChild(playerController)
        self.view.addSubview(playerController.view)
        
        boardController = AgoraChorusWhiteBoardViewController(core: self.core)
        boardController.view.isHidden = true
        self.addChild(boardController)
        self.view.addSubview(boardController.view)
        
        renderController = AgoraChorusRenderListViewController(core: self.core)
//        renderController.delegate = self
        self.addChild(renderController)
        self.view.addSubview(renderController.view)
        
        toolBarController = AgoraChorusToolBarViewController(core: self.core)
        toolBarController.delegate = self
        self.addChild(toolBarController)
        self.view.addSubview(toolBarController.view)
        
        chatController = AgoraGroupChatAlertController(core: self.core)
        chatController.view.isHidden = false
        
        userListController = AgoraUsersListController(core: self.core)
        userListController.view.isHidden = false
        
        usersButton = GradientButton(type: .custom)
        usersButton.setGradient(from: UIColor(hex: 0x641BDF), to: UIColor(hex: 0xD07AF5))
        usersButton.frame = CGRect(x: 0, y: 0, width: 77, height: 34)
        usersButton.cornerRadius = 17
        usersButton.backgroundColor = UIColor(hex: 0xD07AF5)
        usersButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        usersButton.setTitleColor(.white, for: .normal)
        usersButton.setImage(UIImage.rmc_named("ic_user_list"), for: .normal)
        usersButton.addTarget(self, action: #selector(onClickUserList(_:)), for: .touchUpInside)
        usersButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -22, bottom: 0, right: 0)
        usersButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        self.view.addSubview(self.usersButton)
    }
    
    func createConstrains() {
        topBar.snp.makeConstraints { make in
            if #available(iOS 11.0, *) {
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            } else {
                make.top.equalToSuperview()
            }
            make.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        segmentController.view.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(32)
        }
        toolBarController.view.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            if #available(iOS 11.0, *) {
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-50)
            } else {
                make.top.equalTo(-50)
            }
        }
        renderController.view.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(renderController.suggestHeight - 20)
            make.bottom.equalTo(toolBarController.view.snp.top).offset(-10)
        }
        playerController.view.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(segmentController.view.snp.bottom)
            make.bottom.equalTo(renderController.view.snp.top)
        }
        boardController.view.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(segmentController.view.snp.bottom)
            make.bottom.equalTo(renderController.view.snp.top)
        }
        usersButton.snp.makeConstraints { make in
            make.bottom.equalTo(toolBarController.view.snp.top).offset(-29)
            make.width.equalTo(77)
            make.height.equalTo(34)
            make.right.equalTo(17)
        }
    }
}
