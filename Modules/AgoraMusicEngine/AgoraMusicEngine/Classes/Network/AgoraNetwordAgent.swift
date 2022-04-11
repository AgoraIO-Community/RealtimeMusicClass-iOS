//
//  AgoraNetwordAgent.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/10.
//

import UIKit
import Alamofire

class AgoraNetwordAgent {
    
    static let shared: AgoraNetwordAgent = AgoraNetwordAgent()
    
    public func sendRequest(_ request: AgoraRequest) {
        let dict = request.extraHeader ?? [String: String]()
        let headers = HTTPHeaders(dict)
        if let baseURL = request.server?.baseURL {
            let fullPath = baseURL + request.path
            let urlPath = fullPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            request.url = URL(string: urlPath ?? fullPath)
        }
        guard let requestURL = request.url,
              let server = request.server
        else {
            let erro = AgoraRequestError(code: -1, message: "URL 参数无效")
            request.onFailed?(erro)
            return
        }
        AF.request(requestURL,
                   method: request.method,
                   parameters: request.body,
                   encoding: JSONEncoding.default,
                   headers: headers,
                   interceptor: nil,
                   requestModifier: { request in
            request.timeoutInterval = 10
        }).responseData(completionHandler: { response in
            print("----------------------------------------------------")
            debugPrint(response)
            print("----------------------------------------------------")
            guard response.error == nil else { // 网络错误
                let msg = server.errorDescriptionForCode(-1)
                let erro = AgoraRequestError(code: -1, message: msg)
                request.onFailed?(erro)
                return
            }
            guard let data = response.data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []),
                  let dictionary = json as? [String: Any]
            else { // 返回值解析错误
                let msg = server.errorDescriptionForCode(-1)
                let erro = AgoraRequestError(code: -1, message: msg)
                request.onFailed?(erro)
                return
            }
            // 是否需要解析code
            if server.acceptCodes.count > 0,
               let code = dictionary["code"] as? Int,
               server.acceptCodes.contains(code) == false {
                let msg = server.errorDescriptionForCode(code)
                let erro = AgoraRequestError(code: code, message: msg)
                request.onFailed?(erro)
                return
            }
            request.onSuccess?(dictionary)
        })
    }
}
