//
//  DataStreamInfo.swift
//  AgoraMusicEngine
//
//  Created by CP on 2022/3/4.
//

import Foundation

public class CheckReq: NSObject, Codable {
    public var uid: String = ""
    public var startTs: CLongLong = 0
}

public class CheckResp: NSObject, Codable {
    public var remoteUid: String = ""
    public var remoteTS: CLongLong = 0
    public var broadTs: CLongLong = 0
    public var position: CLongLong = 0
}

public class MusicState: NSObject, Codable {
    public var position: CLongLong = 0
    public var bgmId: String = ""
    public var broadTs: CLongLong = 0
    public var Duration: CLongLong = 0
}
