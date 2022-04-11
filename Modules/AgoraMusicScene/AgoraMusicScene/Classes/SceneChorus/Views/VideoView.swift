//
//  VideoView.swift
//  OpenVideoCall
//
//  Created by 陈攀 on 2/14/22.
//  Copyright © 2022 Agora. All rights reserved.
//

import UIKit
import AgoraMusicEngine
import AgoraViewKit

@objc public enum userState: Int {
    case online
    case offline
    case noMicState
}

public class VideoView: UIView {
    
    private enum audioType: Int {
        case unmute
        case muted
        case resume
    }
    
    private enum videoType: Int {
        case unmute
        case muted //没有给视频权限或者视频被mute了
    }
    
    private enum clientRole: Int {
        case teacher
        case student
    }
    
    @objc public var state: userState = .noMicState {
        didSet {
            
            guard let media = userInfo?.media else {return}
            if state != .online {
                roleView.isHidden = state == .noMicState
                mainView.isHidden = true
                audioView.isHidden = true
                audioMicView.isHidden = state == .noMicState
                micView.setState(.off)
                bgView.isHidden = false
                bgImgView.image = UIImage.rmc_named(state == .noMicState ? "空麦位" : "已离线")
                bgStateLabel.text = state == .noMicState ? "空麦位" : "已离线"
            }else {
                roleView.isHidden = false
                audioMicView.isHidden = false
//                if media.cameraDeviceState == .on {
//                    bgView.isHidden = true
//                }
            }
        }
    }
    
    @objc var mainView: UIView!
    @objc var uid: Int = 0
    private var audio_type: audioType = .muted {
        didSet {
            
            switch audio_type {
            case .unmute:
                micView.setState(.on)
            case .muted:
                micView.setState(.off)
            case .resume:
                micView.setState(.forbidden)
            }
            
        }
    }
    
    private var video_type: videoType = .muted {
        didSet {

            if video_type == .muted {
                bgImgView.image = UIImage.rmc_named("pic-cameraoff")
                bgStateLabel.text = "摄像头已关闭"
                mainView.isHidden = true
                audioView.isHidden = true
                bgView.isHidden = false
            }

        }
    }
    
    private var role: clientRole = .student {
        didSet {
            roleLabel.text = role == .student ? "学生" : "老师"
        }
    }
    
    private var name: String = "" {
        didSet {
            nameLabel.text = name
        }
    }
    
    private var oldStreamState: StreamState?
    
    var userInfo: UserInfo? {
        
        didSet {
            guard let info = userInfo else {return}
            guard let media = info.media else {return}
            
            if info.role == .owner{
                role = .teacher
            } else if info.role == .coHost {
                role = .student
            }

            if media.cameraDeviceState == .off {
                video_type = .muted
            }
            
            if media.videoStreamState == .mute {
                
                bgImgView.image = UIImage.rmc_named("pic-cameraoff")
                bgStateLabel.text = "摄像头被禁止"
                mainView.isHidden = true
                audioView.isHidden = true
                bgView.isHidden = false
                
            }
            
            if media.micDeviceState == .on && media.audioStreamState == .publish {
                audio_type = .unmute
            }
            
            if media.micDeviceState == .off && media.audioStreamState == .publish {
                audio_type = .muted
            }
            
            if media.audioStreamState == .mute {
                audio_type = .resume
            }
            
            if media.cameraDeviceState == .on && media.videoStreamState == .publish {
                video_type = .unmute
            }
            
             if oldStreamState != nil {
                 if oldStreamState == .mute && media.videoStreamState == .publish {
                     bgView.isHidden = true
                }
            }
            
            //暂时没有broken状态图片
            
//            if media.videoStreamState == .mute {
//                video_type = .muted
//            }
//
//            if media.micDeviceState == .broken {
//                audio_type = .muted
//            }
            
            name = info.userName
            oldStreamState = media.videoStreamState
        }
    }
    
    var volume: Int = 0 {
        didSet {
            guard let media = userInfo?.media else {return}
            
            if !media.isOnline || media.audioStreamState == .mute {
                micView.setState(.off)
                return
            }
            
            if audio_type == .resume {
                micView.setState(.forbidden)
                return
            }
            
            micView.setVolume(volume)
            
        }
    }
    
    public var bgView: UIView!
    fileprivate var bgImgView: UIImageView!
    fileprivate var bgStateLabel: UILabel!
    fileprivate var infoView: UIView!
    fileprivate var infoLabel: UILabel!
    fileprivate var videoMuteBtn: UIButton!
    fileprivate var audioMicView: UIView!
    fileprivate var micView: AgoraRenderMicView!
    fileprivate var nameLabel: UILabel!
    fileprivate var roleLabel: UILabel!
    var placeHolderView: UIButton!
    @objc var audioView: UIView!
    var audioBGIconView: UIImageView!
    var audioIconView: UIImageView!
    var effectView : UIVisualEffectView!
    var tap: UITapGestureRecognizer!
    
    var roleView: UIView!

    var closure:((UserInfo) ->())?
    
    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white
        
        self.layer.cornerRadius = 5;
        self.layer.masksToBounds = true
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = UIColor.lightGray.cgColor

        addVideoView()
        
        addBGView()
        
        //如果没有开启视频则使用音频模式
        addAudioView()
        
        addRoleView()
        
        addAudioMicView()
        
        //添加点击手势
        tap = UITapGestureRecognizer(target: self, action: #selector(click))
        addGestureRecognizer(tap)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func click() {
        guard let info = userInfo else {return}
        closure!(info)
    }
}

private extension VideoView {
    
    func addBGView() {

        let bgView: UIView = UIView()
        bgView.translatesAutoresizingMaskIntoConstraints = false
        bgView.backgroundColor = .white
        addSubview(bgView)
        self.bgView = bgView
        
        let bgImgView = UIImageView()
        bgImgView.image = UIImage.rmc_named("空麦位")
        bgImgView.contentMode = .scaleToFill
        bgImgView.translatesAutoresizingMaskIntoConstraints = false
        self.bgView.addSubview(bgImgView)
        self.bgImgView = bgImgView
        
        let bgStateLabel = UILabel()
        bgStateLabel.text = "空麦位"
        bgStateLabel.translatesAutoresizingMaskIntoConstraints = false
        bgStateLabel.font = .systemFont(ofSize: 11)
        bgStateLabel.textColor = UIColor(red: 123.0/255.0, green: 103.0 / 255.0, blue: 134.0 / 255.0, alpha: 1)
        bgStateLabel.textAlignment = .center
        self.bgView.addSubview(bgStateLabel)
        self.bgStateLabel = bgStateLabel
        
        bgView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        bgView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        bgView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bgView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        bgImgView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        bgImgView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        bgImgView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        bgImgView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        bgStateLabel.leftAnchor.constraint(equalTo: bgView.leftAnchor, constant: 10).isActive = true
        bgStateLabel.rightAnchor.constraint(equalTo: bgView.rightAnchor, constant: -10).isActive = true
        bgStateLabel.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -25).isActive = true
        bgStateLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true

    }
    
    func addVideoView() {
        mainView = UIView()
        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.backgroundColor = UIColor.clear
        addSubview(mainView)
        
        let videoViewH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[video]|", options: [], metrics: nil, views: ["video": mainView as Any])
        let videoViewV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[video]|", options: [], metrics: nil, views: ["video": mainView as Any])
        NSLayoutConstraint.activate(videoViewH + videoViewV)
        
        mainView.isHidden = true
        
    }
    
    func addAudioView() {
        
        audioView = UIView()
        audioView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(audioView)
        
        let audioViewH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[audio]|", options: [], metrics: nil, views: ["audio": audioView as Any])
        let audioViewV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[audio]|", options: [], metrics: nil, views: ["audio": audioView as Any])
        NSLayoutConstraint.activate(audioViewH + audioViewV)
        
        audioBGIconView = UIImageView()
        audioBGIconView.image = UIImage.rmc_named("longkui")
        audioBGIconView.isUserInteractionEnabled = false
        audioBGIconView.translatesAutoresizingMaskIntoConstraints = false
        audioView.addSubview(audioBGIconView)
        
        audioBGIconView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        audioBGIconView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        audioBGIconView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        audioBGIconView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        
        let effect = UIBlurEffect(style: .light)
        effectView = UIVisualEffectView.init(effect: effect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        audioBGIconView.addSubview(effectView)
        
        effectView.bottomAnchor.constraint(equalTo: audioBGIconView.bottomAnchor, constant: 0).isActive = true
        effectView.leftAnchor.constraint(equalTo: audioBGIconView.leftAnchor, constant: 0).isActive = true
        effectView.topAnchor.constraint(equalTo: audioBGIconView.topAnchor, constant: 0).isActive = true
        effectView.rightAnchor.constraint(equalTo: audioBGIconView.rightAnchor, constant: 0).isActive = true
        
        
        audioIconView = UIImageView()
        audioIconView.image = UIImage.rmc_named("longkui")
        audioIconView.isUserInteractionEnabled = false
        audioIconView.translatesAutoresizingMaskIntoConstraints = false
        audioView.addSubview(audioIconView)
        
        audioIconView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
        audioIconView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0).isActive = true
        audioIconView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        audioIconView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        audioIconView.layer.cornerRadius = 30
        audioIconView.layer.masksToBounds = true
        
        audioView.isHidden = true
        
    }
    
    func addRoleView() {
        
        roleView = UIView()
        roleView.backgroundColor = .black
        roleView.alpha = 0.6
        roleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(roleView)
        
        roleView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        roleView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
        roleView.widthAnchor.constraint(equalToConstant: 36).isActive = true
        roleView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        
        roleLabel = UILabel()
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        roleLabel.backgroundColor = UIColor(red: 28/255.0, green: 0, blue: 76/266.0, alpha: 0.7)
        roleLabel.textAlignment = .center
        roleLabel.textColor = .white
        roleLabel.font = UIFont.systemFont(ofSize: 12)
        roleView.addSubview(roleLabel)
        
        roleLabel.topAnchor.constraint(equalTo: roleView.topAnchor, constant: 0).isActive = true
        roleLabel.leftAnchor.constraint(equalTo: roleView.leftAnchor, constant: 0).isActive = true
        roleLabel.rightAnchor.constraint(equalTo: roleView.rightAnchor, constant: 0).isActive = true
        roleLabel.bottomAnchor.constraint(equalTo: roleView.bottomAnchor, constant: 0).isActive = true
        
        roleView.layer.cornerRadius = 9
        roleView.layer.masksToBounds = true
        
        roleView.isHidden = true
    }
    
    func addAudioMicView() {
        audioMicView = UIView()
        audioMicView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(audioMicView)
        
        let left: CGFloat = 6
        let bottom: CGFloat = 6
        
        audioMicView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -bottom).isActive = true
        audioMicView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: left).isActive = true
        audioMicView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        audioMicView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        micView = AgoraRenderMicView()
        audioMicView.addSubview(micView)
        audioMicView.isHidden = true
        
        micView.translatesAutoresizingMaskIntoConstraints = false
        micView.centerYAnchor.constraint(equalTo: audioMicView.centerYAnchor).isActive = true
        micView.leftAnchor.constraint(equalTo: audioMicView.leftAnchor).isActive = true
        micView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        micView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 12)
        nameLabel.textColor = .white
        nameLabel.layer.shadowColor = UIColor(hex: 0x0D1D3D,
                                              transparency: 0.8)?.cgColor
        nameLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        nameLabel.layer.shadowOpacity = 1
        nameLabel.layer.shadowRadius = 2
        audioMicView.addSubview(nameLabel)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.centerYAnchor.constraint(equalTo: audioMicView.centerYAnchor).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: micView.rightAnchor, constant: 5).isActive = true
        nameLabel.widthAnchor.constraint(equalToConstant: 85).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
}

extension Bundle {
    
    static func loadView<T>(fromNib name: String, withType type: T.Type) -> T {
        if let view = Bundle.main.loadNibNamed(name, owner: nil, options: nil)?.first as? T {
            return view
        }
        
        fatalError("Could not load view with type " + String(describing: type))
    }
    
}
