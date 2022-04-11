//
//  AgoraRtmIMSendBar.swift
//  AgoraWidgets
//
//  Created by Jonathan on 2021/12/16.
//

import UIKit

protocol AgoraRtmIMSendBarDelegate: NSObjectProtocol {
    
    func onClickInputMessage()
    
    func onClickInputEmoji()
}

class AgoraRtmIMSendBar: UIView {
    
    weak var delegate: AgoraRtmIMSendBarDelegate?
    
    private var topLine: UIView!
    
    private var infoLabel: UILabel!
    
    private var emojiButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createViews()
        createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func isMute(_ isMute: Bool) {
        if isMute {
            infoLabel.text = "ChatSilencedPlaceholderText".rmc_localized()
        } else {
            infoLabel.text = "ChatPlaceholderText".rmc_localized()
        }
        
        isUserInteractionEnabled = !isMute
    }
}
// MARK: - Actions
private extension AgoraRtmIMSendBar {
    
    @objc func onClickSendMessage() {
        self.delegate?.onClickInputMessage()
    }
    
    @objc func onClickSendEmoji(_ sender: UIButton) {
        self.delegate?.onClickInputEmoji()
    }
}
// MARK: - Creations
private extension AgoraRtmIMSendBar {
    func createViews() {
        backgroundColor = UIColor(hex: 0xF9F9FC)
        
        topLine = UIView()
        topLine.backgroundColor = UIColor(hex: 0xECECF1)
        self.addSubview(topLine)
        
        let tap = UITapGestureRecognizer.init(target: self,
                                              action: #selector(onClickSendMessage))
        self.addGestureRecognizer(tap)
        
        infoLabel = UILabel()
        infoLabel.font = UIFont.systemFont(ofSize: 13)
        infoLabel.textColor = UIColor(hex: 0x7D8798)
        infoLabel.text = "rtm_input_placeholder".rmc_localized()
        self.addSubview(infoLabel)
        
        emojiButton = UIButton(type: .custom)
        emojiButton.setImage(UIImage.rmc_named("ic_rtm_keyboard_emoji"), for: .normal)
        emojiButton.addTarget(self,
                              action: #selector(onClickSendMessage),
                              for: .touchUpInside)
        self.addSubview(emojiButton)
    }
    
    func createConstrains() {
        topLine.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(1)
        }
        emojiButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.height.equalTo(34)
            make.left.equalTo(7)
        }
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(emojiButton.snp.right).offset(2)
            make.centerY.equalTo(emojiButton)
        }
    }
}
