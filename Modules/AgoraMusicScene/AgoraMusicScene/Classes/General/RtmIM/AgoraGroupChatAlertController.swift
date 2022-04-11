//
//  AgoraGroupChatAlertController.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/2/16.
//

import UIKit
import AgoraMusicEngine
import AgoraViewKit

class AgoraGroupChatAlertController: UIViewController {
    
    private var contentView: UIView!
    
    private var topBar: AgoraRtmIMTopBar!
    
    private var messageList: AgoraRtmIMMessageListView!
    
    private var sendBar: AgoraRtmIMSendBar!
            
    private var fetchedHistory = false
    
    private var core: AgoraMusicCore
    
    deinit {
        print("\(self.classForCoder): \(#function)")
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
        
        self.core.chat.addListener(self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let point = touches.first?.location(in: self.view) else { return }
        let p = contentView.layer.convert(point, from: self.view.layer)
        if contentView.layer.contains(p) == false {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let maskPath = UIBezierPath(roundedRect: self.contentView.bounds, byRoundingCorners: [UIRectCorner.topRight, UIRectCorner.topLeft], cornerRadii: CGSize(width: 18, height: 18))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.contentView.bounds
        maskLayer.path = maskPath.cgPath
        self.contentView.layer.mask = maskLayer
    }
}
// MARK: - Private
private extension RMCRoleType {
    
    func roleName() -> String? {
        switch self {
        case .owner:
            return "rtm_role_teacher".rmc_localized()
        case .coHost:
            return "rtm_role_student".rmc_localized()
        case .audience:
            return "rtm_role_audience".rmc_localized()
        case .unknown:
            return nil
        }
    }
}
// MARK: - AgoraRtmIMInputViewDelegate
extension AgoraGroupChatAlertController: AgoraMusicChatHandler {
    func onReceiveGroupChatMessage(from: UserInfo, msg: String) {
        let model = AgoraRtmMessageModel()
//        model.timestamp = timestamp
        model.text = msg
        model.name = from.userName
        model.isMine = false
        model.roleName = from.role.roleName()
        self.messageList.appendMessage(message: model)
    }
}
// MARK: - AgoraRtmIMInputViewDelegate
extension AgoraGroupChatAlertController: AgoraRtmIMInputViewDelegate {
    func sendChatText(message: String) {
        guard let user = self.core.user.getLocalUser() else {
            return
        }
        self.core.chat.sendGroupChatMessage(msg: message) { isSuccess in
            if isSuccess {
                let model = AgoraRtmMessageModel()
        //        model.timestamp = timestamp
                model.text = message
                model.name = user.userName
                model.isMine = true
                model.roleName = user.role.roleName()
                self.messageList.appendMessage(message: model)
            } else {
                AgoraToast.toast(msg: "发送失败")
            }
        }
    }
}
// MARK: - AgoraRtmIMSendBarDelegate
extension AgoraGroupChatAlertController: AgoraRtmIMSendBarDelegate {
    func onClickInputMessage() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        let inputView = AgoraRtmIMInputView()
        inputView.delegate = self
        window.addSubview(inputView)
        inputView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        window.layoutIfNeeded()
        inputView.startInput()
    }

    func onClickInputEmoji() {
        
    }
}
// MARK: - Creations
private extension AgoraGroupChatAlertController {
    func createViews() {
        contentView = UIView()
        contentView.backgroundColor = .white
        self.view.addSubview(contentView)
        
        topBar = AgoraRtmIMTopBar(frame: .zero)
        self.contentView.addSubview(topBar)
        
        messageList = AgoraRtmIMMessageListView(frame: .zero)
        self.contentView.addSubview(messageList)
        
        sendBar = AgoraRtmIMSendBar(frame: .zero)
        sendBar.delegate = self
        self.contentView.addSubview(sendBar)
    }
    
    func createConstrains() {
        contentView.snp.makeConstraints { make in
            make.left.equalTo(6)
            make.right.equalTo(-6)
            make.bottom.equalToSuperview()
            make.height.equalTo(500)
        }
        topBar.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(34)
        }
        sendBar.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(54)
        }
        messageList.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topBar.snp.bottom)
            make.bottom.equalTo(sendBar.snp.top)
        }
    }
}

