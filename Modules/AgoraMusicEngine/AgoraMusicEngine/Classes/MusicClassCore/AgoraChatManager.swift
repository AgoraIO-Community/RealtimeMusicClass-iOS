//
//  AgoraChatManager.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/17.
//

import Foundation

@objc public protocol AgoraMusicChatHandler: NSObjectProtocol {
    /** 收到了群聊消息*/
    @objc optional func onReceiveGroupChatMessage(from: UserInfo, msg: String)
}

public class AgoraChatManager {
        
    lazy var listeners: NSHashTable<AnyObject> = {
        let t = NSHashTable<AnyObject>.weakObjects()
        return t
    }()
    
    public func addListener(_ listener: AgoraMusicChatHandler) {
        self.listeners.add(listener)
    }
    
    public func removeListener(_ listener: AgoraMusicChatHandler) {
        self.listeners.remove(listener)
    }
    
    public func sendGroupChatMessage(msg: String, complete: ((Bool) -> Void)?) {
        guard let msg = AgoraMessageParser.buildMessage(type: .groupChat, payload: msg) else {
            assert(true, "local user not found")
            return
        }
        AgoraRealTimeEngine.getSharedInstance().sendChannelMessage(with: msg) { code in
            if code == .errorOk {
                complete?(true)
            } else {
                complete?(false)
            }
        }
    }
    
    func receiveGroupChat(from: UserInfo, msg: String) {
        self.dispatchReceiveGroupChatMessage(from: from, msg: msg)
    }
    
}
// MARK: - Dispatch Listener
private extension AgoraChatManager {
    func dispatchReceiveGroupChatMessage(from: UserInfo, msg: String) {
        self.listeners.objectEnumerator().forEach { listener in
            if let d = listener as? AgoraMusicChatHandler {
                d.onReceiveGroupChatMessage?(from: from, msg: msg)
            }
        }
    }
    
}

