//
//  AgoraRequest+RMC.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/10.
//

import Foundation

/** RealTimeMusicClass 服务端配置
 */
class RMCServerConfig: AgoraServerConfig {
    
    override var baseURL: String {
        return "https://rmc-api.gz3.agoralab.co"
    }
    
    override var acceptCodes: [Int] {
        return [0]
    }
    
    override func errorDescriptionForCode(_ code: Int) -> String {
        switch code {
        case -1201:
            return "教室已存在"
        case -1503:
            return "密码错误"
        case -1506:
            return "房间内存在该昵称"
        case -1504:
            return "房间角色人数超限"
        case -2:
            return "返回值解析错误"
        default:
            return "网络错误（\(code)）"
        }
    }
}

extension AgoraRequest {
    /** 向 RealTimeMusicClass 发送请求 全量返回请求后的Dictionary
     */
    public func rmc_request(complete: ((_ error: AgoraRequestError?, _ rsp: [String: Any]?) -> Void)?) {
        self.setTagetServer(RMCServerConfig())
        self.onSuccess = { rsp in
            complete?(nil, rsp)
        }
        self.onFailed = { error in
            complete?(error, nil)
        }
        AgoraNetwordAgent.shared.sendRequest(self)
    }
    /** 向 RealTimeMusicClass 发送请求
     *  将请求结果 解析成对象
     */
    public func rmc_request<T: Decodable>(decodeTo: T.Type, complete: ((_ error: AgoraRequestError?, _ rsp: T?) -> Void)?) {
        self.setTagetServer(RMCServerConfig())
        self.onSuccess = { [weak self] dict in
            if let obj = AgoraRequest.decodeResponse(dict, type: T.self) {
                complete?(nil, obj)
            } else {
                let msg = self?.server?.errorDescriptionForCode(-2) ?? ""
                let error = AgoraRequestError(code: -2,
                                              message: msg)
                complete?(error, nil)
            }
        }
        self.onFailed = { error in
            complete?(error, nil)
        }
        AgoraNetwordAgent.shared.sendRequest(self)
    }
}
