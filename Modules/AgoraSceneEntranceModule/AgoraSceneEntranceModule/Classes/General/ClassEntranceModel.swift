//
//  ClassEntranceModel.swift
//  AgoraSceneEntranceModule
//
//  Created by Jonathan on 2022/2/10.
//

import UIKit
import AgoraMusicEngine

public class ClassEntranceModel {
    
    var className: String = ""
    
    var role: RMCRoleType = .owner
    
    var userName: String = ""
    
    var password: String = ""
    /** 点击了进入教室
     * 注意使用weak
     */
    var onEnterClassRoom: (() -> Void)?

}

