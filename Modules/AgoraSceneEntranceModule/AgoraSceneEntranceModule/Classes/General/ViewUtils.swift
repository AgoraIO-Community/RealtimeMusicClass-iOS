//
//  ViewUtils.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/1/28.
//

import Foundation

extension UIImage {
    class func rmc_named(_ named: String) -> UIImage? {
        let b = Bundle.agoraMusicSceneEntrance()
        return UIImage.init(named: named, in: b, compatibleWith: nil)
    }
}

extension Bundle {
    class func agoraMusicSceneEntrance() -> Bundle {
        return Bundle.ag_compentsBundleNamed("AgoraSceneEntranceModule") ?? Bundle.main
    }
    
    class func ag_compentsBundleNamed(_ named: String) -> Bundle? {
        if let path = Bundle.main.path(forResource: "Frameworks/\(named).framework/\(named)",
                                       ofType: "bundle") {
            return Bundle.init(path: path)
        } else {
            return nil
        }
    }
    
    class func ag_compentsBundleWithClass(_ cls: AnyClass) -> Bundle? {
        let s = NSStringFromClass(cls)
        guard let named = s.components(separatedBy: ".").first else {
            return nil
        }
        return self.ag_compentsBundleNamed(named)
    }
}
