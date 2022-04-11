//
//  AgoraServerConfig.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/10.
//

import UIKit

public class AgoraServerConfig {
    
    open var baseURL: String {
        return ""
    }
    
    open var defaultHeaders: [String: Any] {
        return [String: Any]()
    }
    
    open var defaultParams: [String: Any] {
        return [String: Any]()
    }
    
    open var acceptCodes: [Int] {
        return [0]
    }
    
    open func errorDescriptionForCode(_ code: Int) -> String {
        return "erro: \(code)"
    }
    
}
