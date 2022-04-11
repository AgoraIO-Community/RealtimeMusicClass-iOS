//
//  AppDelegate.swift
//  RealtimeMusicClass
//
//  Created by Jonathan on 2022/1/26.
//

import UIKit
import SwifterSwift
import AgoraMusicScene
import AgoraSceneEntranceModule
import DoraemonKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // vendor monitor
#if DEBUG
        DoraemonManager.shareInstance().install()
#endif
        
        // launch app
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = .white
            appearance.backgroundImage = UIImage(color: .white, size: CGSize(width: 1, height: 1))
            appearance.shadowColor = .clear
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().standardAppearance = appearance
        } else {
            UINavigationBar.appearance().setBackgroundImage(UIImage(color: .white, size: CGSize(width: 1, height: 1)), for: .default)
            UINavigationBar.appearance().shadowImage = UIImage()
        }
        
        window = UIWindow.init(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()
        
        let vc = SceneEntranceViewController()
        vc.hidesBottomBarWhenPushed = true
        vc.delegate = self
        let navi = UINavigationController.init(rootViewController: vc)
        window?.rootViewController = navi
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

// MARK: - SceneEntranceViewControllerDelegate
extension AppDelegate: SceneEntranceViewControllerDelegate {
    /** 进入合唱场景*/
    func onEnterChorusSceneWithParams(className: String, userName: String) {
        AgoraMusicScene.enterChorusSceneWithParams(className: className, userName: userName)
    }
    /** 进入合奏场景*/
    func onEnterEnsembleSceneWithParams() {
        AgoraMusicScene.enterEnsembleSceneWithParams()
    }
    /** 进入陪练场景*/
    func onEnterPracticeSceneWithParams() {
        AgoraMusicScene.enterPracticeSceneWithParams()
    }
}

