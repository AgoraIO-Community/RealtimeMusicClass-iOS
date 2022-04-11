//
//  ViewUtils.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/1/28.
//

import Foundation

extension UIImage {
    class func rmc_named(_ named: String) -> UIImage? {
        let b = Bundle.agoraMusicScene()
        return UIImage.init(named: named, in: b, compatibleWith: nil)
    }
}

extension String {
    func rmc_localized() -> Self {
        return self.ag_localizedIn("AgoraMusicScene")
    }
}

extension Bundle {
    class func agoraMusicScene() -> Bundle {
        return Bundle.ag_compentsBundleNamed("AgoraMusicScene") ?? Bundle.main
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

public extension String {
    
    func ag_localizedIn(_ bundleNamed: String) -> String {
        let bundle = Bundle.ag_compentsBundleNamed(bundleNamed) ?? Bundle.main
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
    
    func ag_localizedBy(_ cls: AnyClass) -> String {
        let bundle = Bundle.ag_compentsBundleWithClass(cls) ?? Bundle.main
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}

extension UIApplication {
    /// 返回当前的View Controller
    ///
    /// - Parameter base: 迭代起点
    /// - Returns: 当前的View Controller
    static func getCurrentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return getCurrentViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return getCurrentViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return getCurrentViewController(base: presented)
        }
        return base
    }
}
