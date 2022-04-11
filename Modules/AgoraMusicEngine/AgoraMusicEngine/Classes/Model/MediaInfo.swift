//
//  MediaInfo.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/10.
//

import UIKit

/** 硬件设备状态*/
public enum DeviceState: Int, Codable {
    case off = 0
    case on = 1
    case broken = 2
}
/** 流状态*/
public enum StreamState: Int, Codable {
    case mute = 0
    case publish = 1
}

public class MediaInfo: NSObject, Codable {
    
    public var index: Int = 0
    
    public var isOnline: Bool = false
    
    public var cameraDeviceState: DeviceState = .on
    
    public var micDeviceState: DeviceState = .on
    
    public var audioStreamState: StreamState = .publish
    
    public var videoStreamState: StreamState = .publish
    
    public var streamId: String?

    private enum CodingKeys: String, CodingKey {
        case index
        case cameraDeviceState
        case micDeviceState
        case audioStreamState
        case videoStreamState
        case streamId
    }
}
