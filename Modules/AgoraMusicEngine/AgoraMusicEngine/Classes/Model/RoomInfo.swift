//
//  RoomInfo.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/10.
//

import UIKit

public class RoomInfo: Decodable {
    
    public var className: String = ""
    
    public var creator: String = ""
    
    public var channelID: String = ""
    
    public var count: Int = 0
    
    public var ext: [String: Any]?
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        className = (try? container.decode(String.self, forKey: .className)) ?? ""
        channelID = (try? container.decode(String.self, forKey: .channelID)) ?? ""
        ext = try? container.decode([String: Any].self, forKey: .ext)
    }
    
    private enum CodingKeys: String, CodingKey {
        case className
        case creator
        case channelID
        case count
        case ext
    }
}
