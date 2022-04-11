//
//  RMCManager.swift
//  RMCManager
//
//  Created by CP on 2022/1/27.
//

import UIKit
import AgoraRtcKit
import AgoraRtmKit

/**
 * 用户角色枚举
 * unknown 未知角色，异常
 * owner 主唱，老师
 * coHost 合唱 ，学生
 * audience  观众 ，旁听
 */
@objc public enum RMCRoleType: Int, Codable {
    case unknown = -1
    case owner = 0
    case coHost = 1
    case audience = 2
}

/**
 * 课程场景枚举
 * RealtimeChorus 实时合唱
 * Instrumentensemble 乐器陪练
 * PianoTeaching 钢琴教学
 */
@objc public enum RMCManagerType: Int {
    case RealtimeChorus
    case Instrumentensemble
    case PianoTeaching
}

/**
 * RTM消息类型枚举
 * p2p p2p消息
 * channel 频道消息
 */
@objc public enum RMCMessageType: Int {
    case p2p
    case channel
}

/**
 * 回声消除等级
 * NoEcho 对应UI上的零回声
 * Standard 对应UI上的标准
 * Fluent 对应UI上的流畅
 */
@objc public enum AECGrade: Int {
    // FIXME: 枚举值首字母小写
    case NoEcho = 1
    case Standard = 3
    case Fluent = 5
}

//MARK: - AgoraMusicPlayerDelegate
@objc public protocol AgoraMusicPlayerDelegate: NSObjectProtocol {
    
    /**
     * datastream消息消息回调
     * @param uid 用户的Uid
     * @param data 用户收到的消息
     */
    func didReceiveStreamMsgOfUid( uid: UInt, data: Data)
    
    /**
     * MPK的seek进度
     * @param position MPK当前修改的进度
     */
    func didMPKChangedToPosition( position: Int)
    
    /**
     * MPK 当前状态回调
     * @param state MPK当前的状态
     * @param error MPK当前的错误码
     */
    func didMPKChangedTo( state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) //MPK 状态回调
}

//MARK: - RMCManagerDelegate
@objc public protocol RMCManagerDelegate: NSObjectProtocol {
    
    /**
     * RTC远端用户下线
     * @param uid 远端下线用户Uid
     */
    func didRtcUserOfflineOfUid( uid: UInt)
    
    /**
     * RTC当前用户加入频道
     * @param uid 当前用户Uid
     */
    func didRtcLocalUserJoinedOfUid( uid: UInt)
    
    /**
     * RTC远端用户加入频道
     * @param uid 远端上线用户Uid
     */
    func didRtcRemoteUserJoinedOfUid( uid: UInt)
    
    /**
     * RTM加入成功
     */
    func didRTMUserJoin( isSuccess: Bool)
    
    /**
     * RTM重复加入
     */
    func didRTMUserReJoined( isRejoined: Bool)
    
    /**
     * RTM消息返回
     * @param msg 接收到的RTM消息
     * @param peerId 发送消息的用户Id
     */
    func didRtmMessageReceived( msg: AgoraRtmMessage, peerId: String)
    
    
    /**
     * 实时音量返回
     * @param speakers 返回的用户声音信息
     * @param totalVolume 返回当前的总音量
     */
    func reportAudioVolumeIndicationOfSpeakers( speakers: [AgoraRtcAudioVolumeInfo])
    
    /**
     * 用户视频第一帧
     * @param size 渲染的视频尺寸（宽度和高度）
     * @param elapsed 视频显示出来第一帧的时间
     */
    func didUserFirstVideoFrameWith(uid: UInt)
    
}

public let kMPK_RTC_UID: UInt = 1
@objc public class AgoraRealTimeEngine: NSObject {
    
    //init manager
    private static var _sharedInstance: AgoraRealTimeEngine?
    
    private var rtmChannel: AgoraRtmChannel?
    
    private var mediaPlayer: AgoraRtcMediaPlayerProtocol?
    
    private var role: RMCRoleType = .audience
    
    private var type: RMCManagerType = .RealtimeChorus
    
    private var channelName: String?
    
    private var streamId: Int = -1
    
    
    
    fileprivate var localRtcUid: UInt = 0
    
    @objc public weak var delegate: RMCManagerDelegate?
    
    @objc public weak var playerDelegate: AgoraMusicPlayerDelegate?
    
    //单例
    @objc public class func getSharedInstance() -> AgoraRealTimeEngine {
        guard let instance = _sharedInstance else {
            _sharedInstance = AgoraRealTimeEngine()
            return _sharedInstance!
        }
        return instance
    }
    
    //init rtc
    private let rtcKit: AgoraRtcEngineKit = AgoraRtcEngineKit.sharedEngine(withAppId: AgoraConfig.rtcId, delegate: nil)
    
    //init rtm
    private let rtmKit: AgoraRtmKit? = AgoraRtmKit(appId: AgoraConfig.rtmId, delegate: nil)
    private var rtmUid: String?
    
    /**
     * 设置RTC角色
     * @param role RMCRoleType
     */
    @objc public func setClientRole(role: RMCRoleType) {
        rtcKit.setClientRole(role == .audience ? .audience : .broadcaster)
        self.role = role
    }
    
    /**
     * 加入实时合唱频道
     * @param channelName 频道名称
     * @param rtcUid RTCUid 如果传0，大网会自动分配
     * @param rtmUid 可选，如果不使用RTM，使用自己的IM，这个值不用传
     */
    @objc public func joinChorsChannelWith(with channelName: String, rtcUid: Int, rtmUid: String?) {
        
        self.channelName = channelName
        self.type = .RealtimeChorus
        
        loadKit(with: channelName, rtcUid: rtcUid, rtmUid: rtmUid)
        
        // Support dynamic setting in the channel and real-time chorus scene
        rtcKit.setParameters("{\"rtc.audio_resend\":false}");
        rtcKit.setParameters("{\"rtc.audio_fec\":[3,2]}");
        rtcKit.setParameters("{\"rtc.audio.aec_length\":50}");
        rtcKit.setAudioProfile(.musicHighQualityStereo, scenario: .chorus);
        rtcKit.enableAudioVolumeIndication(200, smooth: 3)
        
        let config = AgoraVideoEncoderConfiguration(width: 120, height: 160, frameRate: .fps7, bitrate: AgoraVideoBitrateStandard, orientationMode: .adaptative, mirrorMode: .auto)
        rtcKit.setVideoEncoderConfiguration(config)
        
        if self.role != .audience {
            
            mediaPlayer = rtcKit.createMediaPlayer(with: self)
            
            if streamId == -1 {
                let config = AgoraDataStreamConfig()
                config.ordered = false
                config.syncWithAudio = false
                rtcKit.createDataStream(&streamId, config: config)
                if streamId == -1 {
                    return
                }
            }
        }
        
        if self.role == .owner {
            
            let option = AgoraRtcChannelMediaOptions()
            option.publishCameraTrack = .of(true)
            option.publishAudioTrack = .of(true)
            option.publishCustomAudioTrack = .of(false)
            option.autoSubscribeAudio = .of(true)
            option.autoSubscribeVideo = .of(true)
            option.clientRoleType = .of(Int32(AgoraClientRole.broadcaster.rawValue))
            rtcKit.setAudioProfile(.musicHighQuality, scenario: .chorus)
            rtcKit.joinChannel(byToken: nil, channelId: channelName, uid: UInt(rtcUid), mediaOptions: option)
            
            let connection = AgoraRtcConnection()
            connection.channelId = channelName
            connection.localUid = kMPK_RTC_UID
            
            let option2 = AgoraRtcChannelMediaOptions()
            option2.publishCameraTrack = .of(false)//取消发送视频流
            option2.publishAudioTrack = .of(false)//取消SDK采集音频
            option2.autoSubscribeAudio = .of(false)//取消订阅其他人的音频流
            option2.publishCustomAudioTrack = .of(false)//开启音频自采集，如果使用SDK采集，传入false。
            
            option2.enableAudioRecordingOrPlayout = .of(false);
            option2.publishMediaPlayerAudioTrack = .of(true);
            option2.publishMediaPlayerId = .of(Int32(mediaPlayer!.getMediaPlayerId()));
            option2.clientRoleType = .of((Int32)(AgoraClientRole.broadcaster.rawValue)) //设置角色为主播
            
            rtcKit.joinChannelEx(byToken: nil, connection: connection, delegate: nil, mediaOptions: option2) {[weak self] channel_name, user_uid, elapsed in
                self?.rtcKit.muteRemoteAudioStream(kMPK_RTC_UID, mute: true)
            }
            
        } else if self.role == .coHost{
            
            let option = AgoraRtcChannelMediaOptions()
            option.publishCameraTrack = .of(true)
            option.publishAudioTrack = .of(true)
            option.publishCustomAudioTrack = .of(false)
            option.autoSubscribeAudio = .of(true)
            option.autoSubscribeVideo = .of(true)
            option.clientRoleType = .of(Int32(AgoraClientRole.broadcaster.rawValue))
            rtcKit.setAudioProfile(.musicHighQuality, scenario: .chorus)
            rtcKit.joinChannel(byToken: nil, channelId: channelName, uid: UInt(rtcUid), mediaOptions: option)
            
        } else {
            
            let option = AgoraRtcChannelMediaOptions()
            option.publishCameraTrack = .of(false)//关闭视频采集
            option.publishAudioTrack = .of(false)//关闭音频采集
            option.autoSubscribeAudio = .of(true)
            rtcKit.setAudioProfile(.musicHighQuality, scenario: .chorus)//设置profile
            option.clientRoleType = .of((Int32)(AgoraClientRole.audience.rawValue))//设置观众角色
            rtcKit.joinChannel(byToken:nil, channelId:channelName, uid:0, mediaOptions: option)
            
        }
        
    }
    
    /**
     * 加入乐器陪练频道
     * @param channelName 频道名称
     * @param rtcUid RTCUid 如果传0，大网会自动分配
     * @param rtmUid 可选，如果不使用RTM，使用自己的IM，这个值不用传
     */
    private func joinMidiChannelWith(with channelName: String, rtcUid: Int?, rtmUid: String?) {
        
        self.type = .Instrumentensemble
        
        loadKit(with: channelName, rtcUid: rtcUid, rtmUid: rtmUid)
        
    }
    
    /**
     * 加入钢琴教学频道
     * @param channelName 频道名称
     * @param rtcUid RTCUid 如果传0，大网会自动分配
     * @param rtmUid 可选，如果不使用RTM，使用自己的IM，这个值不用传
     */
    private func joinPartnerChannel(with channelName: String, rtcUid: Int?, rtmUid: String?) {
        
        self.type = .Instrumentensemble
        
        loadKit(with: channelName, rtcUid: rtcUid, rtmUid: rtmUid)
        
    }
    
    /**
     * 加载RTC和RTM
     * @param channelName 频道名称
     * @param rtcUid RTCUid 如果传0，大网会自动分配
     * @param rtmUid 可选，如果不使用RTM，使用自己的IM，这个值不用传
     */
    private func loadKit(with channelName: String, rtcUid: Int?, rtmUid: String?) {
        
        if let rtmUid = rtmUid {
            self.rtmUid = rtmUid
            rtmKit?.agoraRtmDelegate = self
            loadRTM(with: channelName, uid: rtmUid)
        }
        
        rtcKit.delegate = self
        
        loadRTC(with: channelName, uid: rtcUid ?? 0)
        
    }
    
    /**
     * 加载RTM
     * @param channelName 频道名称
     * @param uid 如果使用RTM的话，这个一定要有，而且要确保不能重复
     */
    private func loadRTM(with channalName: String, uid: String) {
        var rtmLoginSuccess: Bool = false
        var createChannelSuccess: Bool = false
        guard let rtmKit = self.rtmKit else {
            return
        }
        
        let rtmGroup = DispatchGroup()
        let rtmQueue = DispatchQueue(label: "com.agora.rtm.www")
        
        rtmGroup.enter()
        rtmQueue.async {
            rtmKit.login(byToken: nil, user: uid) { code in
                print("rtm login--\(code.rawValue)")
                rtmLoginSuccess = code.rawValue == 0
                rtmGroup.leave()
            }
        }
        
        rtmGroup.enter()
        rtmQueue.async {[weak self] in
           
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                guard let rtmChannel = rtmKit.createChannel(withId: channalName, delegate: self) else {return}
                self?.rtmChannel = rtmChannel
                rtmChannel.join { code in
                    print("rtm create channel--\(code.rawValue)")
                    createChannelSuccess = code.rawValue == 0
                    rtmGroup.leave()
                }
            }
            
        }
        
        rtmGroup.notify(queue: rtmQueue){[weak self] in
            DispatchQueue.main.async {
                self?.delegate?.didRTMUserJoin(isSuccess: (rtmLoginSuccess && createChannelSuccess) == true)
            }
        }
        
    }
    
    /**
     * 加载RTC
     */
    private func loadRTC(with channalName: String, uid: Int) {
        
        rtcKit.enableVideo()
        rtcKit.startPreview()
    }
    
    /**
     * 开启/关闭 本地音频
     * @param enable 是否开启音频
     * @return 开启/关闭音频的结果
     */
    @discardableResult
    public func enableLocalAudio( enable: Bool) -> Int32 {
        return rtcKit.enableLocalAudio(enable)
    }
    
    /**
     * 开启/关闭 回声消除
     * @param enable 是否开启回声消除
     * @return 开启/关闭回声消除的结果
     */
    @discardableResult
    public func enableAEC(with grade: AECGrade) -> Int32 {
        return rtcKit.setParameters("{\"rtc.audio.music_mode\": \(grade.rawValue)}")
    }
    
    /**
     * 开启/关闭 本地视频
     * @param enable 是否开启视频
     * @return 开启/关闭视频的结果
     */
    @discardableResult
    public func enableLocalVideo( enable: Bool) -> Int32 {
        return rtcKit.enableLocalVideo(enable)
    }
    
    /**
     * 取消或恢复发布本地音频流
     * @param enable 是否发布本地音频流
     * @return 取消或恢复发布本地音频流的结果
     */
    @discardableResult
    public func muteLocalAudioStream( mute: Bool) -> Int32 {
        return rtcKit.muteLocalAudioStream(mute)
    }
    
    /**
     * 取消或恢复发布本地视频流
     * @param enable 是否发布本地视频流
     * @return 取消或恢复发布本地视频流的结果
     */
    @discardableResult
    public func muteLocalVideoStream( mute: Bool) -> Int32 {
        return rtcKit.muteLocalVideoStream(mute)
    }
    
    /**
     * 开启耳返
     * @param enable 是否开启耳返
     * @return 开启/关闭耳返的结果
     */
    @discardableResult
    public func enableinearmonitoring( enable: Bool) -> Int32 {
        return rtcKit.enable(inEarMonitoring: enable, includeAudioFilters: .builtInAudioFilters)
    }
    
    /**
     * 设置耳返音量
     * @param volume 耳返音量值
     * @return 设置耳返音量的结果
     */
    @discardableResult
    public func setInEarMonitoringVolume(with volume: Int) -> Int32 {
        return rtcKit.setInEarMonitoringVolume(volume)
    }
    
    /**
     * 设置用户本地采集音量
     * @param volume 音量值
     * @return 设置用户本地采集音量的结果
     */
    @discardableResult
    public func adjustRecordingSignalVolume(with volume: Int) -> Int32 {
        return rtcKit.adjustRecordingSignalVolume(volume)
    }
    
    /**
     * 设置本地播放的指定远端用户的音量
     * @param volume 音量值
     * @param uid 需要设置的用户的uid
     * @return 设置本地播放的指定远端用户的音量的结果
     */
    @discardableResult
    public func adjustUserPlaybackSignalVolume(with uid: UInt, volume: Int32) -> Int32 {
        return rtcKit.adjustUserPlaybackSignalVolume(uid, volume: volume)
    }
    
    /**
     * 设置美声
     * @param params 美声的参数配置
     * @return 设置美声的结果
     */
    @discardableResult
    public func setVoiceBeautifierParameters(with preset: AgoraVoiceBeautifierPreset) -> Int32 {
        return rtcKit.setVoiceBeautifierPreset(preset)
    }
    
    /**
     * 设置预设美声效果
     * @param preset 美声的参数配置
     * @param param1 歌声的性别特征：
        1: 男声
        2: 女声
     *  @param param2 歌声的混响效果：
        1: 歌声在小房间的混响效果。
        2: 歌声在大房间的混响效果。
        3: 歌声在大厅的混响效果。

     * @return 设置预设美声效果的结果
     */
    @discardableResult
    public func setVoiceBeautifierParameters(with preset: AgoraVoiceBeautifierPreset, param1: Int32, param2: Int32 ) -> Int32 {
        return rtcKit.setVoiceBeautifierParameters(.presetSingingBeautifier, param1: param1, param2: param2)
    }
    
    /**
     * 设置变声
     * @param params 变声的参数配置
     * @return 设置变声的结果
     */
    @discardableResult
    public func setLocalVoiceChanger(with voiceChanger: AgoraAudioVoiceChanger) -> Int32 {
        return rtcKit.setLocalVoiceChanger(voiceChanger)
    }
    
    /**
     * 设置本地视频视图
     * @param local 本地canvas的参数配置
     * @return 设置本地视频视图的结果
     */
    @discardableResult
    public func setupLocalVideo( local: AgoraRtcVideoCanvas?) -> Int32 {
        return rtcKit.setupLocalVideo(local ?? AgoraRtcVideoCanvas())
    }
    
    /**
     * 设置远端视频视图
     * @param remote 远端canvas的参数配置
     * @return 设置远端视频视图的结果
     */
    @discardableResult
    public func setupRemoteVideo( remote: AgoraRtcVideoCanvas?) -> Int32 {
        return rtcKit.setupRemoteVideo(remote ?? AgoraRtcVideoCanvas())
    }
    
    //钢琴教学屏幕裁剪设置试图需要使用Ex
    
    /**
     * 设置本地裁剪视图
     * @param local 本地裁剪canvas的参数配置
     * @return 设置本地裁剪视图
     */
    @discardableResult
    private func setupLocalVideoEx( local: AgoraRtcVideoCanvas) -> Int32 {
        return rtcKit.setupLocalVideo(local)
    }
    
    /**
     * 设置远端裁剪视图
     * @param remote 远端裁剪canvas的参数配置
     * @param connection 远端用户的connection
     * @return 设置远端裁剪视图的结果
     */
    @discardableResult
    private func setupRemoteVideoEx( remote: AgoraRtcVideoCanvas, connection: AgoraRtcConnection) -> Int32 {
        return rtcKit.setupRemoteVideoEx(remote, connection: connection)
    }
    
    /**
     * 发送dataStream消息
     * @param data 发送的data
     * @return 发送dataStream消息的结果
     */
    @discardableResult
    @objc public func sendStreamMessage(with data: Data) -> Int32 {
        return rtcKit.sendStreamMessage(streamId, data: data)
    }
    
    /**
     * 打开音乐
     * @param url 音乐的本地或者线上地址
     * @param startPos 音乐从哪里开始播放 毫秒
     * @return 打开音乐的结果
     */
    @discardableResult
    @objc public func open(with url: String, startPos: Int) -> Int32 {
        mediaPlayer?.setLoopCount(-1)
        return mediaPlayer?.open(url, startPos: startPos) ?? -1
        
    }
    
    /**
     * 播放音乐
     * @return 播放音乐的结果
     */
    @discardableResult
    @objc public func play() -> Int32 {
        return mediaPlayer?.play() ?? -1
    }
    
    /**
     * 暂停播放
     * @return 暂停播放的结果
     */
    @discardableResult
    @objc public func pause() -> Int32 {
        return mediaPlayer?.pause() ?? -1
    }
    
    /**
     * 停止播放
     * @return 停止播放的结果
     */
    @discardableResult
    @objc public func stop() -> Int32 {
        return mediaPlayer?.stop() ?? -1
    }
    
    /**
     * 设置音乐声道
     * @return 设置音乐声道的结果
     */
//    @discardableResult
//    @objc public func setAudioDualMonoMode(with mode: Int) -> Int {
//        return mediaPlayer?.setAudioDualMonoMode(mode)
//    }
    
    /**
     * 老师，学生设置伴奏音量
     * @param volume 伴奏音量值
     * @return 设置伴奏音量的结果
     */
    @discardableResult
    public func adjustPlayoutVolume(with volume: Int32) -> Int32 {
        return mediaPlayer?.adjustPlayoutVolume(volume) ?? -1
    }
    
    /**
     * 获取MPK的播放状态
     * @return MPK的播放状态的结果
     */
    @discardableResult
    public func getPlayerState() -> AgoraMediaPlayerState{
        return mediaPlayer?.getPlayerState() ?? .failed
    }
    
    /**
     * 获取播放进度
     * @return 获取播放进度的结果
     */
    @discardableResult
    public func getPosition() -> Int {
        return mediaPlayer?.getPosition() ?? 0
    }
    
    /**
     * 获取歌曲总时长
     * @return 获取歌曲总时长的结果
     */
    @discardableResult
    public func getDuration() -> Int {
        return mediaPlayer?.getDuration() ?? 0
    }
    
    /**
     * 设置歌曲播放进度
     * @return 设置歌曲播放进度的结果
     */
    @discardableResult
    public func seek(to position: Int) -> Int32 {
        return (mediaPlayer?.seek(toPosition: position))!
    }
    
    //设置鱼眼参数
    
    /**
     * RTM发送P2P消息
     * @param msg p2p消息
     * @param toPeer p2p消息需要发送给的用户
     * @param callBack p2p消息发送的结果闭包
     */
    @objc public func sendP2PMessage(with msg: String, toPeer: String, callBack: AgoraRtmSendPeerMessageBlock?) {
        
        let message: AgoraRtmMessage = AgoraRtmMessage(text: msg)
        
        rtmKit?.send(message, toPeer: toPeer, completion: callBack)
    }
    
    /**
     * RTM发送频道消息
     * @param msg 频道消息
     * @param callBack 频道消息发送的结果闭包
     */
    @objc public func sendChannelMessage(with msg: String, callBack: AgoraRtmSendChannelMessageBlock?) {
        
        let message: AgoraRtmMessage = AgoraRtmMessage(text: msg)
        
        rtmChannel?.send(message, completion: callBack)
    }
    
    /**
     * 离开频道，释放资源
     */
    @objc public func leaveChannel() {
        rtcKit.stopPreview()
        rtcKit.leaveChannel(nil)
        rtcKit.delegate = nil
        AgoraRtcEngineKit.destroy()
        
        if let _ = self.rtmUid {
            rtmKit?.agoraRtmDelegate = nil
            rtmChannel!.leave { code in
                print("RTM:离开频道的code:\(code.rawValue)")
            }
            rtmKit!.logout { code in
                print("RTM:登出的code:\(code.rawValue)")
            }
        }
        
        AgoraRealTimeEngine._sharedInstance = nil //释放单例
    }
}

//MARK: - AgoraRtcEngineDelegate
extension AgoraRealTimeEngine: AgoraRtcEngineDelegate {
    
    // remote joined
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        
        if role == .coHost &&  self.type == .RealtimeChorus && uid == kMPK_RTC_UID{
            
            let _ = rtcKit.muteRemoteAudioStream(kMPK_RTC_UID, mute: true)
            
        }
        
        guard let _ = delegate else {
            return
        }
        
        if uid == kMPK_RTC_UID {
            return
        }
        
        delegate?.didRtcRemoteUserJoinedOfUid(uid: uid)
        
    }
    
    //remote offline
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        
        guard let _ = delegate else {
            return
        }
        
        delegate?.didRtcUserOfflineOfUid(uid: uid)
        
    }
    
    // local joined
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        
        localRtcUid = uid
        
        //
        guard let _ = self.delegate else {
            return
        }
        
        if uid == kMPK_RTC_UID {
            return
        }
        
        delegate?.didRtcLocalUserJoinedOfUid(uid: uid)
        
    }
    
    // dataStream received
    public func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        self.playerDelegate?.didReceiveStreamMsgOfUid(uid: uid, data: data)
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        guard let _ = self.delegate else {
            return
        }
        
        //如果Uid = 0，表示是本地用户的声音
        var real_speakers: [AgoraRtcAudioVolumeInfo] = speakers
        for (index, value) in speakers.enumerated() {
            if value.uid == kMPK_RTC_UID {
                real_speakers.remove(at: index)
            }
            
            if value.uid == 0 {
                real_speakers[index].uid = localRtcUid
            }
        }
        delegate?.reportAudioVolumeIndicationOfSpeakers(speakers: real_speakers)
    }
    
    //本地用户视频第一帧
    public func rtcEngine(_ engine: AgoraRtcEngineKit, firstLocalVideoFrameWith size: CGSize, elapsed: Int) {
        guard let _ = self.delegate else {
            return
        }
        delegate?.didUserFirstVideoFrameWith(uid: localRtcUid)
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
        
        guard let _ = self.delegate else {
            return
        }
        delegate?.didUserFirstVideoFrameWith(uid: uid)
    }
    
}

//MARK: - AgoraRtmDelegate，AgoraRtmChannelDelegate
extension AgoraRealTimeEngine: AgoraRtmDelegate, AgoraRtmChannelDelegate {
    
    public func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        
    }
    
    //rtm p2p messageReceived
    public func rtmKit(_ kit: AgoraRtmKit, messageReceived message: AgoraRtmMessage, fromPeer peerId: String) {
        
        guard let _ = delegate else {
            return
        }
        
        delegate?.didRtmMessageReceived(msg: message, peerId: peerId)
    }
    
    //rtm channel messageReceived
    public func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        guard let _ = delegate else {
            return
        }
        
        delegate?.didRtmMessageReceived(msg: message, peerId: member.userId)
    }
    
    public func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        guard let _ = delegate else {
            return
        }
        if state.rawValue == 5 && reason.rawValue == 8 {
            delegate?.didRTMUserReJoined(isRejoined: true)
        }
    }
    
}

//MARK: - AgoraRtcMediaPlayerDelegate
extension AgoraRealTimeEngine: AgoraRtcMediaPlayerDelegate {
    
    // mpk didChangedToPosition
    public func agoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedToPosition position: Int) {
        guard let _ = delegate else {
            return
        }
        
        self.playerDelegate?.didMPKChangedToPosition(position: position)
    }
    
    // mpk didChangedTo
    public func agoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        
        guard let _ = delegate else {
            return
        }
        
        self.playerDelegate?.didMPKChangedTo(state: state, error: error)
    }
    
}
