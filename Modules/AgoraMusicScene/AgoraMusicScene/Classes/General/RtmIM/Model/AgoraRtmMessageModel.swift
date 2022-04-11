//
//  AgoraRtmMessageModel.swift
//  AgoraWidgets
//
//  Created by Jonathan on 2021/12/17.
//

import UIKit

class AgoraRtmMessageModel: NSObject {
    // 是不是我的消息
    var isMine: Bool = false
    // 角色名称
    var roleName: String?
    
    var name: String = ""
    
    var text: String = ""
    
    var avatar: String?
    
    var timestamp: Int = 0
}
