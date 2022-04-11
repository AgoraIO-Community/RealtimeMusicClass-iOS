//
//  UserInfo.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/10.
//

import UIKit

public class UserInfo: NSObject, Codable {
        
    public var userName: String = ""
    
    public var role: RMCRoleType = .unknown
    /** 是否是本地用户*/
    public var isLocalUser: Bool = false
    
    public var avatar: String = ""
        
    public var gender: Int = 0
    
    public var media: MediaInfo?
    
    public var ext: [String: Any]?
    
    public override init() {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userName = (try? container.decode(String.self, forKey: .userName)) ?? ""
        role = (try? container.decode(RMCRoleType.self, forKey: .role)) ?? .unknown
        avatar = (try? container.decode(String.self, forKey: .avatar)) ?? ""
        gender = (try? container.decode(Int.self, forKey: .gender)) ?? 0
        media = try? container.decode(MediaInfo.self, forKey: .media)
        ext = try? container.decode([String: Any].self, forKey: .ext)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userName, forKey: .userName)
        try container.encode(role, forKey: .role)
        try container.encode(avatar, forKey: .avatar)
        try container.encode(gender, forKey: .gender)
        try container.encode(media, forKey: .media)
    }
    
    private enum CodingKeys: String, CodingKey {
        case userName
        case role
        case avatar
        case gender
        case media
        case ext
    }
}
