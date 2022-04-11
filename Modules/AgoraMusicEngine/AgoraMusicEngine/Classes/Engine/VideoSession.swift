//
//  VideoSession.swift
//  OpenLive
//
//  Created by GongYuhua on 6/25/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import UIKit
import AgoraRtcKit

public class VideoSession: NSObject {
    
    @objc public enum SessionType: Int {
        case local
        case remote
    }
    
    var uid: String = ""
  
    public var canvas: AgoraRtcVideoCanvas
    var type: SessionType
    
    public init(uid: String, type: SessionType = .remote, videoView: UIView) {

        self.uid = uid
        self.type = type
        
        canvas = AgoraRtcVideoCanvas()
        canvas.uid = UInt(uid) ?? 0
        canvas.view = videoView
        
    }
}
