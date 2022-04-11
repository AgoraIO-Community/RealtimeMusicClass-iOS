//
//  ViewUtils.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/1/28.
//

import Foundation

extension UIImage {
    class func avk_named(_ named: String) -> UIImage? {
        let b = Bundle.agoraViewKit()
        return UIImage.init(named: named, in: b, compatibleWith: nil)
    }
}

extension String {
    func avk_localized() -> Self {
        return self.ag_localizedIn("AgoraViewKit")
    }
}

extension Bundle {
    class func agoraViewKit() -> Bundle {
        return Bundle.ag_compentsBundleNamed("AgoraViewKit") ?? Bundle.main
    }
    
    class func ag_compentsBundleNamed(_ named: String) -> Bundle? {
        if let path = Bundle.main.path(forResource: "Frameworks/\(named).framework/\(named)",
                                       ofType: "bundle") {
            return Bundle.init(path: path)
        } else {
            return nil
        }
    }
}

extension String {
    func ag_localizedIn(_ bundleNamed: String) -> String {
        let bundle = Bundle.ag_compentsBundleNamed(bundleNamed) ?? Bundle.main
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}
