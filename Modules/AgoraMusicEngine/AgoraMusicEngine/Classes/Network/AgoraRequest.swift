//
//  AgoraRequest.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/9.
//

import UIKit
import Alamofire

public struct AgoraRequestError: Error {
    var code: Int
    public let message: String
}

public class AgoraRequest {
    
    let path: String
    
    var url: URL?
    
    var body: [String: Any]?
    
    var method: HTTPMethod = .get
    
    var extraHeader: [String: String]?
    /** 请求成功*/
    var onSuccess: (([String: Any]?) -> Void)?
    /** 请求失败*/
    var onFailed: ((AgoraRequestError) -> Void)?
    
    private var decodeType: Decodable?
    
    var server: AgoraServerConfig?
    
    deinit {
        print("\(self): \(#function)")
    }
    
    public init(path: String, body: [String: Any]? = nil, method: HTTPMethod = .get) {
        self.path = path
        self.body = body
        self.method = method
    }
    
    public func config(extraHeader: [String: String]) -> Self {
        self.extraHeader = extraHeader
        return self
    }
    
    public func setTagetServer(_ server: AgoraServerConfig) {
        self.server = server
    }
    
    public static func decodeResponse<T: Decodable>(_ rsp: [String: Any]?, type: T.Type) -> T? {
        guard let response = rsp,
              let dataObject = response["data"],
              JSONSerialization.isValidJSONObject(dataObject),
              let data = try? JSONSerialization.data(withJSONObject: dataObject)
        else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        do {
            return try decoder.decode(type.self, from: data)
        } catch {
            print(error)
            return nil
        }
    }
    
}
