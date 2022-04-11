//
//  MusicControlModel.swift
//  AgoraMusicScene
//
//  Created by CP on 2022/3/1.
//

import Foundation

enum CMDType: String, Codable {
    case Initiatetiming = "start_check_ts"
    case Responsetiming = "check_ts"
    case Playstatus = "play_status"
    case Pausestatus = "pause_status"
}

struct MusicControlModel: Codable {
    
    var cmdType: CMDType = .Playstatus
    var uid: Int?
    var startTs: CLongLong?
    var remoteUid: Int?
    var remoteTS: CLongLong?
    var broadTs: CLongLong?
    var position: CLongLong?
    var Duration: CLongLong?
    var bgmIdentifier: String?
    
}
