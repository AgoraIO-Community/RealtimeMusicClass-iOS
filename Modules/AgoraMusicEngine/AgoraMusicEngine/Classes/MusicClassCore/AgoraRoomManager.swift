//
//  AgoraRoomManager.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/17.
//

import Foundation

@objc public class LeaveClassReason: NSObject {
    public var type: LeaveClassReasonType = .unknow
    public var msg: String = ""
    
    init(type: LeaveClassReasonType, msg: String) {
        self.type = type
        self.msg = msg
        super.init()
    }
}

@objc public enum LeaveClassReasonType: Int {
    case unknow
    case userLeave
    case kickOff
    case error
}

@objc public protocol AgoraMusicRoomHandler: NSObjectProtocol {
    /** 加入教室成功
     */
    @objc optional func onClassJoined()
    /** 课程停止
     */
    @objc optional func onClassLeaved(reason: LeaveClassReason?)
    /** 教室信息有更新
     */
    @objc optional func onClassInfoUpdated()
    /** 教室ext数据发生变化
     */
    @objc optional func onClassExtDataChanged(from: [String: Any]?, to: [String: Any]?)
}

protocol AgoraRoomManagerActionDelegate: NSObjectProtocol {
    /** 开始执行加入教室*/
    func onStartJoinClass()
    /** 开始执行离开教室*/
    func onPrepareLeaveClass()
}

public class AgoraRoomManager {
    
    weak var delegate: AgoraRoomManagerActionDelegate?
    
    public var roomInfo: RoomInfo?
    
    lazy var listeners: NSHashTable<AnyObject> = {
        let t = NSHashTable<AnyObject>.weakObjects()
        return t
    }()
    
    private var className: String
    
    private var userName: String
    
    private var timer: Timer?
    
    init(className: String, userName: String) {
        self.className = className
        self.userName = userName
    }
    /** 注册教室监听
     */
    public func addListener(_ listener: AgoraMusicRoomHandler) {
        listeners.add(listener)
    }
    /** 移除教室监听
     */
    public func removeListener(_ listener: AgoraMusicRoomHandler) {
        listeners.remove(listener)
    }
    /** 加入教室
     * 开启进入教室流程
     */
    public func joinClass() {
        let path = "/room/info/\(self.className)"
        AgoraRequest(path: path, method: .get).rmc_request(decodeTo: RoomInfo.self) { error, rsp in
            if let `rsp` = rsp {
                self.roomInfo = rsp
                self.dispatchClassInfoUpdate()
                self.delegate?.onStartJoinClass()
            } else {
                let reason = LeaveClassReason(type: .error, msg: "获取教室信息失败")
                self.leaveClass(reason: reason)
            }
        }
    }
    /** 离开教室
     * 开启离开教室流程
     * - Parameter reason 触发该动作的原因
     */
    public func leaveClass(reason: LeaveClassReason? = nil) {
        self.delegate?.onPrepareLeaveClass()
        self.endPing()
        let path = "/room/exit/\(self.className)/\(self.userName)"
        AgoraRequest(path: path, method: .get).rmc_request { error, rsp in
            if let `rsp` = rsp {
                print("room manager: leave class \(rsp)")
            } else {
                print("room manager: leave class request failed")
            }
        }
        self.dispatchClassLeave(reason: reason)
    }
    
    public func setExtDataUpdate(key: String, value: Any, complete: ((Bool)-> Void)?) {
        guard let room = self.roomInfo else {
            complete?(false)
            return
        }
        let path = "/room/\(self.className)"
        var ext = self.roomInfo?.ext ?? [String: Any]()
        ext.updateValue(value, forKey: key)
        let body = [
            "ext": ext
        ]
        AgoraRequest(path: path, body: body, method: .post).rmc_request { error, rsp in
            if let _ = rsp {
                self.dispatchClassExtDataChanged(from: room.ext, to: ext)
                self.roomInfo?.ext = ext
                guard let msg = AgoraMessageParser.buildMessage(type: .syncRoomExt, dict: ext) else {
                    return
                }
                AgoraRealTimeEngine.getSharedInstance().sendChannelMessage(with: msg, callBack: nil)
                complete?(true)
            } else {
                complete?(false)
            }
        }
    }
    
    public func setExtDataDelete(key: String, complete: ((Bool)-> Void)?) {
        guard let room = self.roomInfo else {
            complete?(false)
            return
        }
        let path = "/room/\(self.className)"
        var ext = self.roomInfo?.ext ?? [String: Any]()
        ext.removeValue(forKey: key)
        let body = [
            "ext": ext
        ]
        AgoraRequest(path: path, body: body, method: .post).rmc_request { error, rsp in
            if let _ = rsp {
                self.dispatchClassExtDataChanged(from: room.ext, to: ext)
                self.roomInfo?.ext = ext
                guard let msg = AgoraMessageParser.buildMessage(type: .syncRoomExt, dict: ext) else {
                    return
                }
                AgoraRealTimeEngine.getSharedInstance().sendChannelMessage(with: msg, callBack: nil)
                complete?(true)
            } else {
                complete?(false)
            }
        }
    }
    
    func didJoinedClass() {
        self.startPing()
        self.dispatchClassJoined()
    }
    
    private func startPing() {
        self.timer = Timer.scheduledTimer(timeInterval: 10 * 60, target: self, selector: #selector(ping), userInfo: nil, repeats: true)
    }
    
    private func endPing() {
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    @objc private func ping() {
        let path = "/room/\(self.className)/user/\(self.userName)"
        AgoraRequest(path: path, method: .put).rmc_request { error, rsp in
            if let `rsp` = rsp {
                print("room ping: \(rsp)")
            } else if let ero = error {
                print("room ping: error: \(ero)")
            }
        }
    }
    // 收到房间ext更新
    func receiveRoomSyncExt(from: String, ext: [String: Any]) {
        guard let room = self.roomInfo else {
            return
        }
        self.dispatchClassExtDataChanged(from: room.ext, to: ext)
        room.ext = ext
    }
    // 收到踢出房间事件
    func kickOff() {
        self.endPing()
        let reason = LeaveClassReason(type: .kickOff, msg: "用户在其他设备登录")
        self.dispatchClassLeave(reason: reason)
    }
}
// MARK: - Dispatch Listener
private extension AgoraRoomManager {
    func dispatchClassJoined() {
        self.listeners.objectEnumerator().forEach { listener in
            if let d = listener as? AgoraMusicRoomHandler {
                d.onClassJoined?()
            }
        }
    }
    
    func dispatchClassLeave(reason: LeaveClassReason?) {
        self.listeners.objectEnumerator().forEach { listener in
            if let d = listener as? AgoraMusicRoomHandler {
                d.onClassLeaved?(reason: reason)
            }
        }
    }
    
    func dispatchClassInfoUpdate() {
        self.listeners.objectEnumerator().forEach { listener in
            if let d = listener as? AgoraMusicRoomHandler {
                d.onClassInfoUpdated?()
            }
        }
    }
    
    func dispatchClassExtDataChanged(from: [String: Any]?, to: [String: Any]?) {
        self.listeners.objectEnumerator().forEach { listener in
            if let d = listener as? AgoraMusicRoomHandler {
                d.onClassExtDataChanged?(from: from, to: to)
            }
        }
    }
}
