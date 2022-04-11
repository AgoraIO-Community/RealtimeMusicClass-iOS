//
//  AgoraRtmIMInputView.swift
//  AgoraWidgets
//
//  Created by Jonathan on 2021/12/17.
//

import UIKit

protocol AgoraRtmIMInputViewDelegate: NSObjectProtocol {
    
    func sendChatText(message: String)
    
}

class AgoraRtmIMInputView: UIView {
    
    public weak var delegate: AgoraRtmIMInputViewDelegate?
    
    private var contentView: UIView!
    
    private var textFiled: UITextField!
    
    private var sendButton: UIButton!
    
    private var emojiButton: UIButton!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createViews()
        createConstrains()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(noti:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(noti:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    public func startInput() {
        self.textFiled.becomeFirstResponder()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.textFiled.layer.cornerRadius = self.textFiled.frame.height * 0.5
        self.sendButton.layer.cornerRadius = self.sendButton.frame.height * 0.5
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        self.textFiled.resignFirstResponder()
    }
}
// MARK: - UITextFieldDelegate
extension AgoraRtmIMInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onClickSendMessage()
        return true
    }
}
// MARK: - Actions
private extension AgoraRtmIMInputView {
    @objc func keyboardWillShow(noti: Notification) {
        guard let duration = noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? CGFloat,
              let frame = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        self.layoutIfNeeded()
        self.contentView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(-frame.size.height)
            make.height.equalTo(44)
        }
        UIView.animate(withDuration: TimeInterval(duration)) {
            self.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(noti: Notification) {
        guard let duration = noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? CGFloat else {
            return
        }
        self.contentView.snp.remakeConstraints { make in
            make.left.right.equalTo(0)
            make.bottom.equalTo(0)
            make.height.equalTo(44)
        }
        UIView.animate(withDuration: TimeInterval(duration)) {
            self.layoutIfNeeded()
            self.alpha = 0
        } completion: { isFinish in
            self.removeFromSuperview()
        }
    }
    
    @objc func onClickSendMessage() {
        if let text = textFiled.text,
           text.count > 0 {
            delegate?.sendChatText(message: text)
            self.textFiled.resignFirstResponder()
        }
    }
}
// MARK: - Creations
private extension AgoraRtmIMInputView {
    func createViews() {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        
        self.contentView = UIView()
        self.contentView.backgroundColor = UIColor(hex: 0xF9F9FC)
        self.addSubview(self.contentView)
        
        self.sendButton = UIButton(type: .custom)
        self.sendButton.setTitleColor(.white, for: .normal)
        self.sendButton.clipsToBounds = true
        self.sendButton.setTitle("rtm_send_message".rmc_localized(),
                                 for: .normal)
        if let color = UIColor(hex: 0x357BF6) {
            self.sendButton.setBackgroundImage(UIImage.init(color: color, size: CGSize(width: 1, height: 1)), for: .normal)
        }
        self.sendButton.addTarget(self,
                                  action: #selector(onClickSendMessage),
                                  for: .touchUpInside)
        self.addSubview(self.sendButton)
        
        self.textFiled = UITextField()
        self.textFiled.backgroundColor = .white
        self.textFiled.delegate = self
        self.textFiled.returnKeyType = .send;
        self.textFiled.clipsToBounds = true
        self.textFiled.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
        self.textFiled.leftViewMode = .always
        self.addSubview(self.textFiled)
    }
    
    func createConstrains() {
        self.contentView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(frame.maxY)
            make.height.equalTo(44)
        }
        self.sendButton.snp.makeConstraints { make in
            make.height.equalTo(34)
            make.width.equalTo(66)
            make.centerY.equalTo(self.contentView)
            if #available(iOS 11.0, *) {
                make.right.equalTo(self.safeAreaLayoutGuide.snp.right).offset(-20)
            } else {
                make.right.equalTo(20)
            }
        }
        self.textFiled.snp.makeConstraints { make in
            make.height.equalTo(34)
            if #available(iOS 11.0, *) {
                make.left.equalTo(self.safeAreaLayoutGuide.snp.left).offset(20)
            } else {
                make.left.equalTo(20)
            }
            make.right.equalTo(self.sendButton.snp.left).offset(-10)
            make.centerY.equalTo(self.contentView)
        }
    }
}
 
