//
//  RoomPasswordAlertController.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/2/8.
//

import UIKit
import AgoraViewKit

class RoomPasswordAlertController: UIViewController {
    
    public class func showInViewController(_ vc: UIViewController, complete: ((String) -> Void)?) {
        let alert = RoomPasswordAlertController()
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        alert.onClickSubmit = complete
        vc.present(alert, animated: true, completion: nil)
    }
    
    private var containerView: UIView!
    
    private var titleLabel: UILabel!
    
    private var textField: UITextField!
    
    private var closeButton: UIButton!
    
    private var submitButton: GradientButton!
    
    private var onClickSubmit: ((String) -> Void)?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        self.createViews()
        self.createConstrains()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        textField.becomeFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        self.textField.resignFirstResponder()
    }
    
    @objc func onClickClose(_ sender: UIButton) {
        self.textField.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func onClickSubmit(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.onClickSubmit?(self.textField.text ?? "")
        }
    }
}

private extension RoomPasswordAlertController {
    func createViews() {
        containerView = UIView()
        containerView.backgroundColor = .white
        containerView.cornerRadius = 12
        self.view.addSubview(containerView)
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor(hex: 0x1C004C)
        titleLabel.text = "请输入密码"
        self.containerView.addSubview(titleLabel)
        
        textField = UITextField()
        textField.backgroundColor = UIColor(hex: 0xEEEEF7)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        textField.leftViewMode = .always
        textField.cornerRadius = 6
        textField.clearButtonMode = .whileEditing
        textField.textColor = UIColor(hex: 0x1C004C)
        textField.autocorrectionType = .no
        self.containerView.addSubview(textField)
        
        closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage.rmc_named("ic_alert_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(onClickClose(_:)), for: .touchUpInside)
        self.containerView.addSubview(closeButton)
        
        submitButton = GradientButton(type: .custom)
        submitButton.cornerRadius = 22
        submitButton.setGradient(from: UIColor(hex: 0xEE2CE8), to: UIColor(hex: 0xFF9754))
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.setTitle("进入教室", for: .normal)
        submitButton.backgroundColor = UIColor(hex: 0xEE2CE8)
        submitButton.addTarget(self, action: #selector(onClickSubmit(_:)), for: .touchUpInside)
        self.containerView.addSubview(submitButton)
    }
    
    func createConstrains() {
        containerView.snp.makeConstraints { make in
            make.width.equalTo(321)
            make.height.equalTo(200)
            make.center.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.top.left.equalTo(24)
        }
        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalTo(24)
            make.right.equalTo(-24)
            make.height.equalTo(44)
        }
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.top.equalTo(4)
            make.right.equalTo(-4)
        }
        submitButton.snp.makeConstraints { make in
            make.width.equalTo(160)
            make.height.equalTo(44)
            make.bottom.equalTo(-20)
            make.centerX.equalToSuperview()
        }
    }
}
