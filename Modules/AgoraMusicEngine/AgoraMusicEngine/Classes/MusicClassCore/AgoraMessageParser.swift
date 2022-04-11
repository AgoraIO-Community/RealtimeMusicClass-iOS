//
//  AgoraMessageParser.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/16.
//

import Foundation

/** 消息类型定义*/
enum AgoraMessageType: Int, Decodable {
    // 单聊
    case singleChat = 0
    // 群聊
    case groupChat = 1
    // 用户更新
    case userUpdate = 2
    // 用户加入
    case userJoin = 3
    // 用户退出
    case userLeave = 4
    // 用户控制
    case userAction = 5
    // 同步用户ext
    case syncUserExt = 6
    // 同步房间ext
    case syncRoomExt = 7
}
/** 用户消息*/
struct AgoraMessage: Decodable {
    var type: AgoraMessageType?
    var msg: String?
}
/** 消息解析结果回调*/
protocol AgoraMessageParserDelegate: NSObjectProtocol {
    /** 解析结果：收到单聊消息*/
    func onReceiveSingleChatMessage(from: String, msg: String)
    /** 解析结果：收到群聊消息*/
    func onReceiveGroupChatMessage(from: String, msg: String)
    /** 解析结果：收到用户更新消息*/
    func onReceiveUserUpdateMessage(from: String, user: UserInfo)
    /** 解析结果：收到用户加入消息*/
    func onReceiveUserJoinMessage(from: String, user: UserInfo)
    /** 解析结果：收到用户离开消息*/
    func onReceiveUserLeaveMessage(from: String, user: UserInfo)
    /** 解析结果：收到用户指令消息*/
    func onReceiveUserActionMessage(from: String, msg: String)
    /** 解析结果：收到同步用户扩展消息*/
    func onReceiveSyncUserExtMessage(from: String, msg: String)
    /** 解析结果：收到同步房间扩展消息*/
    func onReceiveSyncRoomExtMessage(from: String, msg: String)
}
/** RTM消息解析器*/
class AgoraMessageParser {
    
    public weak var delegate: AgoraMessageParserDelegate?
    
    public func parseMessage(_ msg: String, from: String) {
        print("Parser: parse message: \(msg)")
        guard let obj = self.decodeMessage(msg, type: AgoraMessage.self),
              let type = obj.type,
              let payload = obj.msg
        else {
            assert(true, "message type not found")
            return
        }
        switch type {
        case .singleChat:
            self.delegate?.onReceiveSingleChatMessage(from: from, msg: payload)
        case .groupChat:
            self.delegate?.onReceiveGroupChatMessage(from: from, msg: payload)
        case .userUpdate:
            guard let obj = self.decodeMessage(payload, type: UserInfo.self) else {
                assert(true, "message invalied")
                return
            }
            self.delegate?.onReceiveUserUpdateMessage(from: from, user: obj)
        case .userJoin:
            guard let obj = self.decodeMessage(payload, type: UserInfo.self) else {
                assert(true, "message invalied")
                return
            }
            self.delegate?.onReceiveUserJoinMessage(from: from, user: obj)
        case .userLeave:
            guard let obj = self.decodeMessage(payload, type: UserInfo.self) else {
                assert(true, "message invalied")
                return
            }
            self.delegate?.onReceiveUserLeaveMessage(from: from, user: obj)
        case .userAction:
            self.delegate?.onReceiveUserActionMessage(from: from, msg: payload)
        case .syncUserExt:
            self.delegate?.onReceiveSyncUserExtMessage(from: from, msg: payload)
        case .syncRoomExt:
            self.delegate?.onReceiveSyncRoomExtMessage(from: from, msg: payload)
        }
    }
    
    static func buildMessage<T: Codable>(type: AgoraMessageType, payload: T) -> String? {
        var msg = ""
        if let string = payload as? String {
            msg = string
        } else {
            let objEncoder = JSONEncoder()
            guard let objData = try? objEncoder.encode(payload),
                  let objJson = String(data: objData, encoding: .utf8)
            else {
                return nil
            }
            msg = objJson
        }
        let dict = [
            "type": type.rawValue,
            "msg": msg
        ] as [String: Any]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted),
              let string = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        print("Parser: build message: \(string)")
        return string
    }
    
    static func buildMessage(type: AgoraMessageType, dict: [String: Any]) -> String? {
        guard let dictData = try? JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted),
              let msg = String(data: dictData, encoding: .utf8)
        else {
            return nil
        }
        let payload = [
            "type": type.rawValue,
            "msg": msg
        ] as [String: Any]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions.prettyPrinted),
              let string = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        print("Parser: build message: \(string)")
        return string
    }
    
    private func decodeMessage<T: Decodable>(_ msg: String, type: T.Type) -> T? {
        guard let data = msg.data(using: .utf8) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        return try? decoder.decode(type.self, from: data)
    }
    
}
