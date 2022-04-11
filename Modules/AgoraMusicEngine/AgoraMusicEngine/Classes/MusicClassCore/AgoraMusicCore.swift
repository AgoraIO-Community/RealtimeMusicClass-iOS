//
//  AgoraMusicCore.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/17.
//

import Foundation
import AgoraRtcKit
import AgoraRtmKit

/** 音乐场景数据业务*/
public class AgoraMusicCore: NSObject {
    
    public var engine: AgoraRealTimeEngine = AgoraRealTimeEngine.getSharedInstance()
    
    private lazy var messageParser: AgoraMessageParser = {
        let p = AgoraMessageParser()
        p.delegate = self
        return p
    }()
    /** 房间数据*/
    public var room: AgoraRoomManager
    /** 用户数据*/
    public var user: AgoraUserManager
    /** 聊天数据*/
    public var chat: AgoraChatManager = AgoraChatManager()
    /** 在线RTC*/
    private var onLineRTCUser = Set<String>()
    
    deinit {
        print("\(self.classForCoder): \(#function)")
    }
    
    public init(className: String, userName: String) {
        self.room = AgoraRoomManager(className: className, userName: userName)
        self.user = AgoraUserManager(className: className, userName: userName)
        super.init()
        self.room.delegate = self
        self.engine.delegate = self
    }
}
// MARK: - AgoraRoomManagerActionDelegate
extension AgoraMusicCore: AgoraRoomManagerActionDelegate {
    
    func onStartJoinClass() {
        self.user.fetchUsers { isSuccess in
            if isSuccess,
               let u = self.user.getLocalUser(),
               let channelID = self.room.roomInfo?.channelID {
                self.engine.setClientRole(role: u.role)
                self.engine.joinChorsChannelWith(with: channelID, rtcUid: 0, rtmUid: u.userName)
            } else {
                let reason = LeaveClassReason(type: .error, msg: "初始化查询用户信息失败")
                self.room.leaveClass(reason: reason)
            }
        }
    }
    
    func onPrepareLeaveClass() {
        self.user.sendLocalUserLeave()
        self.engine.leaveChannel()
    }
}
// MARK: - AgoraMessageParserDelegate
extension AgoraMusicCore: AgoraMessageParserDelegate {
    
    func onReceiveSingleChatMessage(from: String, msg: String) {
        // Do Noting: 暂无1v1聊天需求
    }
    
    func onReceiveGroupChatMessage(from: String, msg: String) {
        guard let u = self.user.userList.first(where: {$0.userName == from}) else {
            return
        }
        self.chat.receiveGroupChat(from: u, msg: msg)
    }
    
    func onReceiveUserUpdateMessage(from: String, user: UserInfo) {
        if let streamId = user.media?.streamId,
           self.onLineRTCUser.contains(streamId) {
            user.media?.isOnline = true
        }
        self.user.receiveUserUpdate(user: user)
    }
    
    func onReceiveUserJoinMessage(from: String, user: UserInfo) {
        self.user.receiveUserJoined(user: user)
    }
    
    func onReceiveUserLeaveMessage(from: String, user: UserInfo) {
        self.user.receiveUserLeaved(user: user)
    }
    
    func onReceiveUserActionMessage(from: String, msg: String) {
        self.user.receiveUserActionMessage(msg: msg)
    }
    
    func onReceiveSyncUserExtMessage(from: String, msg: String) {
        guard let data = msg.data(using: .utf8),
              let ext = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
        else {
            return
        }
        self.user.receiveUserSyncExt(from: from, ext: ext)
    }
    
    func onReceiveSyncRoomExtMessage(from: String, msg: String) {
        guard let data = msg.data(using: .utf8),
              let ext = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
        else {
            return
        }
        self.room.receiveRoomSyncExt(from: from, ext: ext)
    }
}
// MARK: - RMCManagerDelegate
extension AgoraMusicCore: RMCManagerDelegate {
        
    public func didRealtimeuseruidreturn( total: [UInt]) {
        print("music core: \(#function) : \(total)")
    }
    
    public func didRtcLocalUserJoinedOfUid( uid: UInt) {
        print("music core: \(#function) : \(uid)")
        self.user.updateLocalStreamId(String(uid)) { isSuccess, erro in
            if isSuccess {
                
            } else {
                print("music core: \(#function) : failed")
            }
        }
    }
    /** RTC 用户加入*/
    public func didRtcRemoteUserJoinedOfUid( uid: UInt) {
        print("music core: \(#function) : \(uid)")
        let streamId = String(uid)
        self.onLineRTCUser.insert(streamId)
        self.user.setStreamOnline(streamId: streamId, isOnline: true)
    }
    /** RTC 用户离线*/
    public func didRtcUserOfflineOfUid( uid: UInt) {
        print("music core: \(#function) : \(uid)")
        let streamId = String(uid)
        self.onLineRTCUser.remove(streamId)
        self.user.setStreamOnline(streamId: streamId, isOnline: false)
    }
    public func didReceiveStreamMsgOfUid( uid: UInt, data: Data) {
        print("music core: \(#function) : \(uid)")
    }
    
    public func didRTMUserJoin(isSuccess: Bool) {
        if isSuccess {
            self.user.sendLocalUserJoined()
            self.room.didJoinedClass()
        } else {
            let reason = LeaveClassReason(type: .error, msg: "RTM 初始化失败")
            self.room.leaveClass(reason: reason)
        }
    }
    
    public func didRTMUserReJoined( isRejoined: Bool) {
        if isRejoined {
            // 本地踢出
            self.engine.leaveChannel()
            self.room.kickOff()
        }
    }
    
    public func didRtmMessageReceived( msg: AgoraRtmMessage, peerId: String) {
        print("music core: \(#function) : \(msg) from: \(peerId)")
        self.messageParser.parseMessage(msg.text, from: peerId)
    }
    
    public func didMPKChangedToPosition( position: Int) {
        print("music core: \(#function) : \(position)")
    }
    
    public func didMPKChangedTo( state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        print("music core: \(#function) : \(state)")
    }
    
    public func reportAudioVolumeIndicationOfSpeakers(speakers: [AgoraRtcAudioVolumeInfo]) {
        speakers.forEach { info in
            self.user.receiveUserVoiceUpdate(streamId: String(info.uid),
                                             value: Int(info.volume))
        }
    }
    
    public func didUserFirstVideoFrameWith(uid: UInt) {
        self.user.receiveUserFirstFrame(streamId: String(uid))
    }

}
