//
//  CreateChorusViewController.swift
//  AgoraSceneEntranceModule
//
//  Created by Jonathan on 2022/2/9.
//

import UIKit
import AgoraMusicEngine
import AgoraViewKit

class ChorusRoomCreateViewController: UIViewController {
    
    private var roomInputView: InfoInputView!
    
    private var pwInputView: InfoInputView!
    
    private var checkBoxButton: UIButton!
    
    private var submitButton: GradientButton!
        
    private var entranceModel: ClassEntranceModel
    
    init(entranceModel: ClassEntranceModel) {
        self.entranceModel = entranceModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        self.title = "创建新教室"
        
        self.createViews()
        self.createConstrains()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.roomInputView.textField.becomeFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        self.roomInputView.textField.resignFirstResponder()
        self.pwInputView.textField.resignFirstResponder()
    }
    
    @objc func onClickCreate(_ sender: UIButton) {
        guard let roomName = self.roomInputView.textField.text,
              roomName.count != 0
        else {
            AgoraToast.toast(msg: "请输入教室名称")
            return
        }
        guard roomName.count <= 20 else {
            AgoraToast.toast(msg: "教室名称不能超过20个字符")
            return
        }
        if self.checkBoxButton.isSelected == true,
           let password = self.pwInputView.textField.text {
            if password.count == 0 {
                AgoraToast.toast(msg: "密码不能为空")
                return
            } else if password.count > 8 {
                AgoraToast.toast(msg: "密码不能超过8个字符")
                return
            }
        }
        AgoraLoading.loading()
        self.entranceModel.className = self.roomInputView.textField.text ?? ""
        if self.checkBoxButton.isSelected {
            self.entranceModel.password = self.pwInputView.textField.text ?? ""
        } else {
            self.entranceModel.password = ""
        }
        let path = "/room/create"
        let body = [
            "className": self.entranceModel.className,
            "creator": self.entranceModel.userName,
            "password": self.entranceModel.password
        ]
        AgoraRequest(path: path, body: body, method: .post).rmc_request { error, rsp in
            AgoraLoading.hide()
            if let `rsp` = rsp {
                print(rsp)
                self.entranceModel.onEnterClassRoom?()
                self.navigationController?.popToRootViewController(animated: false)
            } else {
                AgoraToast.toast(msg: error?.message)
            }
        }
    }
    
    @objc func onClickCheckBox(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.pwInputView.isEnable = sender.isSelected
        if sender.isSelected {
            self.pwInputView.becomeFirstResponder()
        }
    }
}

// MARK: - Creations
private extension ChorusRoomCreateViewController {
    func createViews() {
        roomInputView = InfoInputView()
        roomInputView.textField.placeholder = "请输入房间名"
        roomInputView.label.text = "教室名"
        self.view.addSubview(roomInputView)
        
        pwInputView = InfoInputView()
        pwInputView.textField.placeholder = "请输入密码"
        pwInputView.label.text = "密码"
        pwInputView.isEnable = false
        self.view.addSubview(pwInputView)
        
        checkBoxButton = UIButton(type: .custom)
        checkBoxButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        checkBoxButton.setTitleColor(UIColor(hex: 0x95909D), for: .normal)
        checkBoxButton.addTarget(self, action: #selector(onClickCheckBox(_:)), for: .touchUpInside)
        checkBoxButton.setTitle("启用密码", for: .normal)
        checkBoxButton.isSelected = false
        checkBoxButton.setImage(UIImage.rmc_named("ic_checkbox_unsel"), for: .normal)
        checkBoxButton.setImage(UIImage.rmc_named("ic_checkbox_sel"), for: .selected)
        checkBoxButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)
        self.view.addSubview(checkBoxButton)
        
        submitButton = GradientButton(type: .system)
        submitButton.cornerRadius = 22
        submitButton.setGradient(from: UIColor(hex: 0x641BDF), to: UIColor(hex: 0xD07AF5))
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.addTarget(self, action: #selector(onClickCreate(_:)), for: .touchUpInside)
        submitButton.setTitle("创建新教室", for: .normal)
        submitButton.backgroundColor = UIColor(hex: 0x641BDF)
        self.view.addSubview(submitButton)
    }
    
    func createConstrains() {
        roomInputView.snp.makeConstraints { make in
            make.top.equalTo(40)
            make.width.equalTo(280)
            make.height.equalTo(40)
            make.centerX.equalToSuperview()
        }
        pwInputView.snp.makeConstraints { make in
            make.top.equalTo(roomInputView.snp.bottom).offset(20)
            make.width.equalTo(280)
            make.height.equalTo(40)
            make.centerX.equalToSuperview()
        }
        checkBoxButton.snp.makeConstraints { make in
            make.top.equalTo(pwInputView.snp.bottom).offset(20)
            make.left.equalTo(pwInputView)
        }
        submitButton.snp.makeConstraints { make in
            make.width.equalTo(280)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-50)
        }
    }
}
