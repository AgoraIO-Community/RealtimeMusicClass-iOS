//
//  AgoraMusicScene.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/1/30.
//

import UIKit
import AgoraViewKit

@objc public class AgoraMusicScene: NSObject {
    
    @objc public class func enterChorusSceneWithParams(className: String, userName: String) {
        let vc = AgoraChorusSceneViewController()
        vc.className = className
        vc.userName = userName
        vc.modalPresentationStyle = .fullScreen
        if let currentVC = UIApplication.getCurrentViewController() {
            currentVC.present(vc, animated: true, completion: nil)
        } else {
            assert(true, "can't get top view controller")
        }
    }
    
    @objc public class func enterEnsembleSceneWithParams() {
        AgoraToast.toast(msg: "功能开发中")
        return
        let vc = AgoraEnsembleSceneViewController()
        vc.modalPresentationStyle = .fullScreen
        if let currentVC = UIApplication.getCurrentViewController() {
            currentVC.present(vc, animated: true, completion: nil)
        } else {
            assert(true, "can't get top view controller")
        }
    }
    
    @objc public class func enterPracticeSceneWithParams() {
        AgoraToast.toast(msg: "功能开发中")
        return
        let vc = AgoraPracticeSceneViewController()
        vc.modalPresentationStyle = .fullScreen
        if let currentVC = UIApplication.getCurrentViewController() {
            currentVC.present(vc, animated: true, completion: nil)
        } else {
            assert(true, "can't get top view controller")
        }
    }
}
