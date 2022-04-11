//
//  AgoraMessageParser.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/16.
//

import Foundation

/** 消息类型定义*/
@objc public enum AgoraDataStreamMessageType: Int, Decodable {
    // 合唱发起对时消息
    case start_check_ts = 0
    // 主唱响应对时消息
    case check_ts_resp = 1
    // 歌曲播放的状态
    case play_status = 2
    // 歌曲暂停的状态
    case pause_status = 3
}
/** 用户消息*/
@objc public class AgoraDataStreamMessage:NSObject, Decodable {
    public var type: AgoraDataStreamMessageType?
    public var msg: String?
}

/** DataStream消息解析器*/
public class AgoraDataStreamMessageParser {

    public static func buildMessage<T: Codable>(type: AgoraDataStreamMessageType, payload: T) -> Data? {
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
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            return nil
        }

        return data
    }
    
    public static func decodeMessage<T: Decodable>(_ msg: String, type: T.Type) -> T? {
        guard let data = msg.data(using: .utf8) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        return try? decoder.decode(type.self, from: data)
    }
    
}
