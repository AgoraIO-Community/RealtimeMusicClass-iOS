//
//  AgoraChorusToolBarViewController.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/1/27.
//

import UIKit
import AgoraMusicEngine
import AgoraViewKit
import AVFAudio

fileprivate class AgoraToolButton: UIButton {
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let space: CGFloat = 5
        let titleWidth = self.titleLabel?.bounds.size.width ?? 0
        let titleHight = self.titleLabel?.bounds.size.height ?? 0
        let imgWidth = self.imageView?.bounds.size.width ?? 0
        let imgHight = self.imageView?.bounds.size.height ?? 0
        
        let midX = self.bounds.midX
        let imageCenterX = midX - titleWidth/2
        self.titleEdgeInsets = UIEdgeInsets(top: imgHight/2 + space/2, left: -imgWidth, bottom: -(titleHight/2 + space/2), right: 0)
        self.imageEdgeInsets = UIEdgeInsets(top: -(titleHight/2 + space/2), left: midX - imageCenterX, bottom: titleHight/2 + space/2, right: -(midX - imageCenterX))
        self.imageView?.center.x = (self.titleLabel?.center.x)!
        self.titleLabel?.textAlignment = .center
    }
}

protocol AgoraChorusToolBarDelegate: NSObjectProtocol {
    /** 选择帮助*/
    func onClickHelp()
    /** 打开聊天*/
    func onClickGroupChat()
}
class AgoraChorusToolBarViewController: UIViewController {
    
    public weak var delegate: AgoraChorusToolBarDelegate?
    
    private var imageView: UIImageView!
    
    private var contentView: UIStackView!
    
    private var helpButton: UIButton!
    
    private var earButton: UIButton!
    
    private var cameraButton: UIButton!
    
    private var micButton: UIButton!
    
    private var chatButton: UIButton!
    
    private var isHeadPhoneInsert = false {
        didSet { // 目前只有非观众会改变该值
            self.updateEarBackButtonState()
        }
    }
    
    private var isEarBackOn: Bool = false {
        didSet {
            self.updateEarBackButtonState()
        }
    }
    
    private var core: AgoraMusicCore
    
    deinit {
        print("\(self.classForCoder): \(#function)")
        NotificationCenter.default.removeObserver(self)
    }
    
    init(core: AgoraMusicCore) {
        self.core = core
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createViews()
        self.createConstrains()
        
        self.core.room.addListener(self)
    }
    
    private func setupState() {
        guard let user = self.core.user.getLocalUser() else {
            return
        }
        if user.role == .audience { // 观众无法操作媒体按钮
            self.earButton.isSelected = true
            self.cameraButton.isSelected = true
            self.micButton.isSelected = true
        } else {
            guard let media = user.media else {
                return
            }
            self.micButton.isSelected = !(media.micDeviceState == .on)
            self.cameraButton.isSelected = !(media.cameraDeviceState == .on)
            
            let audioSession = AVAudioSession.sharedInstance()
            let currentRoute = audioSession.currentRoute
            for output in currentRoute.outputs {
                if output.portType == .headphones || output.portType == .bluetoothA2DP {
                    self.isHeadPhoneInsert = true
                    break
                }
            }
            NotificationCenter.default.addObserver(self, selector: #selector(onAudioRouteChanged(_:)), name: AVAudioSession.routeChangeNotification, object: audioSession)
        }
    }
    
    @objc func onAudioRouteChanged(_ noti: Notification) {
        guard let userInfo = noti.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue)
        else {
            return
        }
        switch reason {
        case .newDeviceAvailable:
            self.isHeadPhoneInsert = true
            break
        case .oldDeviceUnavailable:
            self.isHeadPhoneInsert = false
            break
        default: ()
        }
    }
    
    func updateEarBackButtonState() {
        if isEarBackOn, isHeadPhoneInsert, !self.micButton.isSelected {
            self.earButton.isSelected = false
        } else {
            self.earButton.isSelected = true
        }
    }
}
// MARK: - Actions
private extension AgoraChorusToolBarViewController {
    @objc func onClickHelp(_ sender: UIButton) {
        self.delegate?.onClickHelp()
    }
    
    @objc func onClickVoicePlayBack(_ sender: UIButton) {
        if let user = self.core.user.getLocalUser(),
           user.role == .audience {
            AgoraToast.toast(msg: "旁听时该功能不可用，请切换角色上课")
            return
        }
        if self.micButton.isSelected {
            AgoraToast.toast(msg: "需要打开麦克风")
            return
        }
        if self.isHeadPhoneInsert == false {
            AgoraToast.toast(msg: "该功能需要插入耳机")
            return
        }
        let next = !self.isEarBackOn
        self.core.engine.enableinearmonitoring(enable: next)
        self.isEarBackOn = next
    }
    
    @objc func onClickCamera(_ sender: UIButton) {
        guard let user = self.core.user.getLocalUser(),
              user.role != .audience
        else {
            AgoraToast.toast(msg: "观众无法使用多媒体输入")
            return
        }
        AgoraLoading.loading()
        let isOn = sender.isSelected
        self.core.user.setLocalCameraState(isOn: isOn) { isSuccess, ero in
            AgoraLoading.hide()
            
            let NotifyMsgName = NSNotification.Name(rawValue:"LOCALCAMARASTATE")
            NotificationCenter.default.post(name:NotifyMsgName, object: nil, userInfo: ["state":isOn == true ? 1 : 0 ])
            
            if isSuccess {
                sender.isSelected = !isOn
            } else {
                AgoraToast.toast(msg: "设置失败，请重试")
            }
        }
    }
    
    @objc func onClickMic(_ sender: UIButton) {
        guard let user = self.core.user.getLocalUser(),
              user.role != .audience
        else {
            AgoraToast.toast(msg: "观众无法使用多媒体输入")
            return
        }
        AgoraLoading.loading()
        let isOn = sender.isSelected
        self.core.user.setLocalMicState(isOn: isOn) { isSuccess, ero in
            AgoraLoading.hide()
            
            if isSuccess {
                sender.isSelected = !isOn
                self.updateEarBackButtonState()
                if isOn, self.isEarBackOn {
                    // 关闭麦克风SDK会关闭耳返，打开需要修正状态
                    self.core.engine.enableinearmonitoring(enable: true)
                }
            } else {
                AgoraToast.toast(msg: "设置失败，请重试")
            }
        }
    }
    
    @objc func onClickGroupChat(_ sender: UIButton) {
        self.delegate?.onClickGroupChat()
    }
}
// MARK: - AgoraMusicRoomHandler
extension AgoraChorusToolBarViewController: AgoraMusicRoomHandler {
    func onClassJoined() {
        self.setupState()
    }
}

// MARK: - Creations
private extension AgoraChorusToolBarViewController {
    func createViews() {
        imageView = UIImageView(image: UIImage.rmc_named("img_tool_bar_bg"))
        imageView.contentMode = .scaleToFill
        self.view.addSubview(imageView)
        
        contentView = UIStackView()
        contentView.backgroundColor = .clear
        contentView.axis = .horizontal
        contentView.spacing = 2
        contentView.distribution = .equalSpacing
        contentView.alignment = .fill
        view.addSubview(contentView)
        
        let buttonFrame = CGRect(x: 0, y: 0, width: 50, height: 50)
        helpButton = AgoraToolButton(type: .custom)
        helpButton.imageView?.contentMode = .scaleAspectFill
        helpButton.frame = buttonFrame
        helpButton.titleLabel?.textColor = .white
        helpButton.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        helpButton.setTitle("帮助", for: .normal)
        helpButton.setImage(UIImage.rmc_named("ic_toolbar_help"), for: .normal)
        helpButton.addTarget(self,
                             action: #selector(onClickHelp(_:)),
                             for: .touchUpInside)
        contentView.addArrangedSubview(helpButton)
        
        earButton = AgoraToolButton(type: .custom)
        earButton.isSelected = true
        earButton.imageView?.contentMode = .scaleAspectFill
        earButton.frame = buttonFrame
        earButton.titleLabel?.textColor = .white
        earButton.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        earButton.setTitle("耳返", for: .normal)
        earButton.setImage(UIImage.rmc_named("ic_toolbar_audio"), for: .normal)
        earButton.setImage(UIImage.rmc_named("ic_toolbar_audio_off"), for: .selected)
        earButton.addTarget(self,
                            action: #selector(onClickVoicePlayBack(_:)),
                            for: .touchUpInside)
        contentView.addArrangedSubview(earButton)
        
        cameraButton = AgoraToolButton(type: .custom)
        cameraButton.imageView?.contentMode = .scaleAspectFill
        cameraButton.frame = buttonFrame
        cameraButton.titleLabel?.textColor = .white
        cameraButton.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        cameraButton.setTitle("摄像头", for: .normal)
        cameraButton.setImage(UIImage.rmc_named("ic_toolbar_camera"), for: .normal)
        cameraButton.setImage(UIImage.rmc_named("ic_toolbar_camera_off"), for: .selected)
        cameraButton.addTarget(self,
                               action: #selector(onClickCamera(_:)),
                               for: .touchUpInside)
        contentView.addArrangedSubview(cameraButton)
        
        micButton = AgoraToolButton(type: .custom)
        micButton.imageView?.contentMode = .scaleAspectFill
        micButton.frame = buttonFrame
        micButton.titleLabel?.textColor = .white
        micButton.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        micButton.setTitle("麦克风", for: .normal)
        micButton.setImage(UIImage.rmc_named("ic_toolbar_mic"), for: .normal)
        micButton.setImage(UIImage.rmc_named("ic_toolbar_mic_off"), for: .selected)
        micButton.addTarget(self,
                            action: #selector(onClickMic(_:)),
                            for: .touchUpInside)
        contentView.addArrangedSubview(micButton)
        
        chatButton = AgoraToolButton(type: .custom)
        chatButton.imageView?.contentMode = .scaleAspectFill
        chatButton.frame = buttonFrame
        chatButton.titleLabel?.textColor = .white
        chatButton.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        chatButton.setTitle("聊天", for: .normal)
        chatButton.setImage(UIImage.rmc_named("ic_toolbar_chat"), for: .normal)
        chatButton.addTarget(self,
                             action: #selector(onClickGroupChat(_:)),
                             for: .touchUpInside)
        contentView.addArrangedSubview(chatButton)
    }
    
    func createConstrains() {
        imageView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.left.equalTo(11)
            make.right.equalTo(-11)
            make.top.equalTo(0)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            } else {
                make.bottom.equalTo(0)
            }
        }
    }
}

