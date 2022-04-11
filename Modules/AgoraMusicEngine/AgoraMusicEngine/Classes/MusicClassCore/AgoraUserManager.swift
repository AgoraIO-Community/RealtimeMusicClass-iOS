//
//  AgoraUserManager.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/17.
//

import Foundation

private enum UserCtrlType: String {
    case mic
    case camera
    case updateExt
    case deleteExt
}

fileprivate let kUserCtrlType = "ctrlType"
fileprivate let kUserCtrlAction = "action"
@objc public protocol AgoraMusicUserHandler: NSObjectProtocol {
    /** 远端用户加入
     */
    @objc optional func onRemoteUserJoined(user: UserInfo)
    /** 用户信息更新
     */
    @objc optional func onUserInfoUpdated(user: UserInfo)
    /** 远端用户退出
     */
    @objc optional func onRemoteUserLeaved(user: UserInfo)
    /** 用户声音状态值发生改变
     */
    @objc optional func onUserVoiceUpdate(user: UserInfo, value: Int)
    /** 用户收到首帧
     */
    @objc optional func onUserReceiveFirstFrame(user: UserInfo)
    /** 用户ext数据发生变化
     */
    @objc optional func onUserExtDataChanged(user: UserInfo, from: [String: Any]?, to: [String: Any]?)
}

public class AgoraUserManager {
    
    public var userList = [UserInfo]()
    
    private var className: String
    
    private var userName: String
    
    init(className: String, userName: String) {
        self.className = className
        self.userName = userName
    }
    
    lazy var listeners: NSHashTable<AnyObject> = {
        let t = NSHashTable<AnyObject>.weakObjects()
        return t
    }()
    /** 添加观察者
     */
    public func addListener(_ listener: AgoraMusicUserHandler) {
        self.listeners.add(listener)
    }
    /** 移除观察者
     */
    public func removeListener(_ listener: AgoraMusicUserHandler) {
        self.listeners.remove(listener)
    }
    /** 获取本地用户
     * 若在房间加入成功前获取本地用户，可能获取到一个空值
     */
    public func getLocalUser() -> UserInfo? {
        return self.userList.first(where: {$0.userName == self.userName})
    }
    /** 设置本地摄像头状态
     */
    public func setLocalCameraState(isOn: Bool, complete: ((Bool, Error?) -> Void)?) {
        let path = "/room/\(self.className)/user/\(self.userName)"
        let body = ["cameraDeviceState": isOn ? 1 : 0]
        AgoraRequest(path: path, body: body, method: .post).rmc_request { error, rsp in
            if let _ = rsp {
                guard let media = self.getLocalUser()?.media else {
                    complete?(false, nil)
                    return
                }
                media.cameraDeviceState = isOn ? .on : .off
                let engine = AgoraRealTimeEngine.getSharedInstance()
                engine.enableLocalVideo(enable: isOn)
                // 摄像头打开SDK会自动打开stream，需要对流状态进行修正
                engine.muteLocalVideoStream(mute: media.videoStreamState == .mute)
                self.sendLocalUserUpdate()
                complete?(true, nil)
            } else {
                complete?(false, nil)
            }
        }
    }
    /** 设置本地麦克风状态
     */
    public func setLocalMicState(isOn: Bool, complete: ((Bool, Error?) -> Void)?) {
        let path = "/room/\(self.className)/user/\(self.userName)"
        let body = ["micDeviceState": isOn ? 1 : 0]
        AgoraRequest(path: path, body: body, method: .post).rmc_request { error, rsp in
            if let _ = rsp {
                let u = self.getLocalUser()
                u?.media?.micDeviceState = isOn ? .on : .off
                AgoraRealTimeEngine.getSharedInstance().enableLocalAudio(enable: isOn)
                self.sendLocalUserUpdate()
                complete?(true, nil)
            } else {
                complete?(false, nil)
            }
        }
    }
    /** 控制某个用户的视频流开关
     */
    public func setVideoStreamOn(isOn: Bool,
                                 userName: String,
                                 complete: ((Bool, Error?) -> Void)?) {
        let dict = self.buildUserAction(with: .camera, action: isOn)
        guard let msg = AgoraMessageParser.buildMessage(type: .userAction, dict: dict) else {
            return
        }
        AgoraRealTimeEngine.getSharedInstance().sendP2PMessage(with: msg, toPeer: userName) { code in
            if code == .ok {
                complete?(true, nil)
            } else {
                complete?(false, nil)
            }
        }
    }
    /** 控制某个用户的音频流开关
     */
    public func setAudioStreamOn(isOn: Bool,
                                 userName: String,
                                 complete: ((Bool, Error?) -> Void)?) {
        let dict = self.buildUserAction(with: .mic, action: isOn)
        guard let msg = AgoraMessageParser.buildMessage(type: .userAction, dict: dict) else {
            return
        }
        AgoraRealTimeEngine.getSharedInstance().sendP2PMessage(with: msg, toPeer: userName) { code in
            if code == .ok {
                complete?(true, nil)
            } else {
                complete?(false, nil)
            }
        }
    }
    // 更新本地用户的ext数据
    public func setLocalExtDataUpdate(key: String, value: Any, complete: ((Bool)-> Void)?) {
        guard let user = self.getLocalUser() else {
            return
        }
        let path = "/room/\(self.className)/user/\(self.userName)"
        var ext = user.ext ?? [String: Any]()
        ext.updateValue(value, forKey: key)
        let body = [
            "ext": ext
        ]
        AgoraRequest(path: path, body: body, method: .post).rmc_request { error, rsp in
            if let _ = rsp {
                self.dispatchUserExtDataChanged(user: user, from: user.ext, to: ext)
                user.ext = ext
                guard let msg = AgoraMessageParser.buildMessage(type: .syncUserExt, dict: ext) else {
                    return
                }
                AgoraRealTimeEngine.getSharedInstance().sendChannelMessage(with: msg, callBack: nil)
                complete?(true)
            } else {
                complete?(false)
            }
        }
    }
    // 删除本地用户的ext数据
    public func setLocalExtDataDelete(key: String, complete: ((Bool)-> Void)?) {
        guard let user = self.getLocalUser() else {
            return
        }
        let path = "/room/\(self.className)/user/\(self.userName)"
        var ext = user.ext ?? [String: Any]()
        ext.removeValue(forKey: key)
        let body = [
            "ext": ext
        ]
        AgoraRequest(path: path, body: body, method: .post).rmc_request { error, rsp in
            if let _ = rsp {
                complete?(true)
            } else {
                complete?(false)
            }
        }
    }
    // 更新远端用户的ext数据
    public func setRemoteExtDataUpdate(with userName: String, key: String, value: Any, complete: ((Bool)-> Void)?) {
        let dict = self.buildUserAction(with: .updateExt, action: [key: value])
        guard let msg = AgoraMessageParser.buildMessage(type: .userAction, dict: dict) else {
            return
        }
        AgoraRealTimeEngine.getSharedInstance().sendP2PMessage(with: msg, toPeer: userName) { code in
            if code == .ok {
                complete?(true)
            } else {
                complete?(false)
            }
        }
    }
    // 删除远端用户的ext数据
    public func setRemoteExtDataDelete(width userName: String, key: String, complete: ((Bool)-> Void)?) {
        let dict = self.buildUserAction(with: .deleteExt, action: key)
        guard let msg = AgoraMessageParser.buildMessage(type: .userAction, dict: dict) else {
            return
        }
        AgoraRealTimeEngine.getSharedInstance().sendP2PMessage(with: msg, toPeer: userName) { code in
            if code == .ok {
                complete?(true)
            } else {
                complete?(false)
            }
        }
    }
    // 查询用户列表
    func fetchUsers(complete: ((Bool) -> Void)?) {
        let path = "/room/\(self.className)/users"
        AgoraRequest(path: path, method: .get).rmc_request(decodeTo: [UserInfo].self) { error, rsp in
            if let `rsp` = rsp {
                if let u = rsp.first(where: {$0.userName == self.userName}) {
                    u.isLocalUser = true
                }
                self.userList = rsp
                if let u = self.userList.last {
                    self.dispatchUserJoined(user: u)
                }
                complete?(true)
            } else {
                complete?(false)
            }
        }
    }
    // 更新本地streamId
    func updateLocalStreamId(_ streamId: String, result: ((Bool, Error?) -> Void)?) {
        guard let localUser = self.getLocalUser(),
              let media = localUser.media
        else {
            return
        }
        // 同步本地RTC状态
        let engine = AgoraRealTimeEngine.getSharedInstance()
        engine.muteLocalVideoStream(mute: media.videoStreamState == .mute)
        engine.muteLocalAudioStream(mute: media.audioStreamState == .mute)
        engine.enableLocalAudio(enable: media.micDeviceState == .on)
        engine.enableLocalVideo(enable: media.cameraDeviceState == .on)
        // 分发streamId到服务端
        let path = "/room/\(self.className)/user/\(self.userName)"
        let body = [
            "streamId": streamId
        ]
        AgoraRequest(path: path, body: body , method: .post).rmc_request { error, rsp in
            if let _ = rsp {
                media.isOnline = true
                media.streamId = streamId
                self.sendLocalUserUpdate()
                result?(true, nil)
            } else {
                result?(false, nil)
            }
        }
    }
    // 设置某个stream在线状态
    func setStreamOnline(streamId: String, isOnline: Bool) {
        guard let user = self.userList.first(where: {$0.media?.streamId == streamId}),
              let media = user.media
        else {
            return
        }
        if media.isOnline != isOnline {
            media.isOnline = isOnline
            self.dispatchUserInfoUpdate(user: user)
        }
    }
    // 对所有用户在线状态进行同步
    func syncUsersOnlineState(with streamIds: Set<String>) {
        for user in self.userList {
            if let streamId = user.media?.streamId,
               streamIds.contains(streamId) { // 该用户在线
                if user.media?.isOnline == false {
                    user.media?.isOnline = true
                    self.dispatchUserInfoUpdate(user: user)
                }
            } else { // 离线用户
                if user.media?.isOnline == true {
                    user.media?.isOnline = false
                    self.dispatchUserInfoUpdate(user: user)
                }
            }
        }
    }
    // 发送本地用户加入
    func sendLocalUserJoined() {
        guard let u = self.getLocalUser(),
              let msg = AgoraMessageParser.buildMessage(type: .userJoin, payload: u)
        else {
            assert(true, "local user not found")
            return
        }
        AgoraRealTimeEngine.getSharedInstance().sendChannelMessage(with: msg, callBack: nil)
    }
    // 发送本地用户离开
    func sendLocalUserLeave() {
        guard let u = self.getLocalUser(),
              let msg = AgoraMessageParser.buildMessage(type: .userLeave, payload: u)
        else {
            assert(true, "local user not found")
            return
        }
        AgoraRealTimeEngine.getSharedInstance().sendChannelMessage(with: msg, callBack: nil)
    }
    // 发送本地用户更新
    func sendLocalUserUpdate() {
        guard let u = self.getLocalUser(),
              let msg = AgoraMessageParser.buildMessage(type: .userUpdate, payload: u)
        else {
            assert(true, "local user not found")
            return
        }
        AgoraRealTimeEngine.getSharedInstance().sendChannelMessage(with: msg, callBack: nil)
        self.dispatchUserInfoUpdate(user: u)
    }
    // 收到远端用户加入
    func receiveUserJoined(user: UserInfo) {
        // 去重
        guard self.userList.contains(where: {$0.userName == user.userName}) == false else {
            assert(true, "user duplicate")
            return
        }
        self.userList.append(user)
        self.dispatchUserJoined(user: user)
    }
    // 收到远端用户更新
    func receiveUserUpdate(user: UserInfo) {
        if let index = self.userList.firstIndex(where: {$0.userName == user.userName}) {
            self.userList[index] = user
        } else {
            self.userList.append(user)
        }
        self.dispatchUserInfoUpdate(user: user)
    }
    // 收到远端用户离开
    func receiveUserLeaved(user: UserInfo) {
        self.userList.removeAll(where: {$0.userName == user.userName})
        self.dispatchUserLeaved(user: user)
    }
    // 收到用户动作消息
    func receiveUserActionMessage(msg: String) {
        self.executeUserActionMessage(msg: msg)
    }
    // 收到用户声音更新
    func receiveUserVoiceUpdate(streamId: String, value: Int) {
        let u = self.userList.first { user in
            guard let s = user.media?.streamId else {
                return false
            }
            return s == streamId
        }
        guard let user = u else {
            return
        }
        self.dispatchUserVoiceUpdate(user: user, value: value)
    }
    // 收到用户首帧渲染
    func receiveUserFirstFrame(streamId: String) {
        // 如果找到streamId则认为是远端用户，否则认为是本地用户
        if let user = self.userList.first(where: {$0.media?.streamId == streamId}) {
            self.dispatchUserReceiveFirstFrame(user: user)
        } else if let localUser = self.getLocalUser() {
            self.dispatchUserReceiveFirstFrame(user: localUser)
        }
    }
    // 收到用户ext更新
    func receiveUserSyncExt(from: String, ext: [String: Any]) {
        guard let user = self.userList.first(where: {$0.userName == from}) else {
            return
        }
        self.dispatchUserExtDataChanged(user: user, from: user.ext, to: ext)
        user.ext = ext
    }
}
// MARK: - User Action
private extension AgoraUserManager {
    /** 收到用户操作消息*/
    func executeUserActionMessage(msg: String) {
        guard let data = msg.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any],
              let typeStr = dict[kUserCtrlType] as? String,
              let ctrlType = UserCtrlType.init(rawValue: typeStr),
              let action = dict[kUserCtrlAction],
              let localMedia = self.getLocalUser()?.media
        else {
            assert(true, "message type not found")
            return
        }
        switch ctrlType {
        case .mic:
            guard let isOn = action as? Bool else {
                return
            }
            self.setLocalAudioStreamPublish(isPublish: isOn)
            if isOn {// stream打开SDK会自动打开采集，需要对设备状态进行修正
                let engine = AgoraRealTimeEngine.getSharedInstance()
                engine.enableLocalAudio(enable: localMedia.micDeviceState == .on)
            }
        case .camera:
            if let isOn = action as? Bool {
                self.setLocalVideoStreamPublish(isPublish: isOn)
            }
        case .updateExt:
            guard let dict = action as? [String: Any],
                  let (key, value) = dict.first
            else {
                return
            }
            self.setLocalExtDataUpdate(key: key, value: value, complete: nil)
        case .deleteExt:
            guard let key = action as? String else {
                return
            }
            self.setLocalExtDataDelete(key: key, complete: nil)
        }
    }
    
    private func decodeMessage<T: Decodable>(_ msg: String, type: T.Type) -> T? {
        guard let data = msg.data(using: .utf8) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        return try? decoder.decode(type.self, from: data)
    }
    
    func setLocalVideoStreamPublish(isPublish: Bool) {
        AgoraRealTimeEngine.getSharedInstance().muteLocalVideoStream(mute: !isPublish)
        let path = "/room/\(self.className)/user/\(self.userName)"
        let body = ["videoStreamState": isPublish ? 1 : 0]
        AgoraRequest(path: path, body: body, method: .post).rmc_request { error, rsp in
            if let _ = rsp {
                let u = self.getLocalUser()
                u?.media?.videoStreamState = isPublish ? .publish : .mute
                self.sendLocalUserUpdate()
            } else {
                // Do Nothing
            }
        }
    }
    
    func setLocalAudioStreamPublish(isPublish: Bool) {
        AgoraRealTimeEngine.getSharedInstance().muteLocalAudioStream(mute: !isPublish)
        let path = "/room/\(self.className)/user/\(self.userName)"
        let body = ["audioStreamState": isPublish ? 1 : 0]
        AgoraRequest(path: path, body: body, method: .post).rmc_request { error, rsp in
            if let _ = rsp {
                let u = self.getLocalUser()
                u?.media?.audioStreamState = isPublish ? .publish : .mute
                self.sendLocalUserUpdate()
            } else {
                // Do Nothing
            }
        }
    }
    
    func buildUserAction(with ctrlType: UserCtrlType, action: Any) -> [String: Any] {
        return [
            kUserCtrlType: ctrlType.rawValue,
            kUserCtrlAction: action
        ]
    }
}
// MARK: - Dispatch Listener
private extension AgoraUserManager {
    func dispatchUserJoined(user: UserInfo) {
        self.listeners.objectEnumerator().forEach { listener in
            if let d = listener as? AgoraMusicUserHandler {
                d.onRemoteUserJoined?(user: user)
            }
        }
    }
    
    func dispatchUserInfoUpdate(user: UserInfo) {
        self.listeners.objectEnumerator().forEach { listener in
            if let d = listener as? AgoraMusicUserHandler {
                d.onUserInfoUpdated?(user: user)
            }
        }
    }
    
    func dispatchUserLeaved(user: UserInfo) {
        self.listeners.objectEnumerator().forEach { listener in
            if let d = listener as? AgoraMusicUserHandler {
                d.onRemoteUserLeaved?(user: user)
            }
        }
    }
    
    func dispatchUserVoiceUpdate(user: UserInfo, value: Int) {
        self.listeners.objectEnumerator().forEach { listener in
            if let d = listener as? AgoraMusicUserHandler {
                d.onUserVoiceUpdate?(user: user, value: value)
            }
        }
    }
    
    func dispatchUserReceiveFirstFrame(user: UserInfo) {
        self.listeners.objectEnumerator().forEach { listener in
            if let d = listener as? AgoraMusicUserHandler {
                d.onUserReceiveFirstFrame?(user: user)
            }
        }
    }
    func dispatchUserExtDataChanged(user: UserInfo, from: [String: Any]?, to: [String: Any]?) {
        self.listeners.objectEnumerator().forEach { listener in
            if let d = listener as? AgoraMusicUserHandler {
                d.onUserExtDataChanged?(user: user, from: from, to: to)
            }
        }
    }
}
