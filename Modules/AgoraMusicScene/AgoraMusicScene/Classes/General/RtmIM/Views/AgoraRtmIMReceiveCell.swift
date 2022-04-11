//
//  AgoraRtmIMReceiveCell.swift
//  AgoraWidgets
//
//  Created by Jonathan on 2021/12/17.
//

import UIKit

fileprivate let kRoleLabelHeight: CGFloat = 16
fileprivate let kAvatarHeight: CGFloat = 22
class AgoraRtmIMReceiveCell: UITableViewCell {
    
    var messageModel: AgoraRtmMessageModel? {
        didSet {
            if messageModel != oldValue {
                updateView()
            }
        }
    }

    private var avatarView: UIImageView!
    
    private var bubleView: UIView!
    
    private var nameLabel: UILabel!
    
    private var roleLabel: UILabel!
    
    private var messageLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        createViews()
        createConstrains()
    }
    
    public func setMessage(msg: String) {
        messageLabel.text = msg
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateView() {
        guard let model = messageModel  else {
            return
        }
        nameLabel.text = model.name
        messageLabel.text = model.text
        if let str = model.roleName,
           str.count > 0 {
            roleLabel.isHidden = false
            roleLabel.text = "  \(str)  "
        } else {
            roleLabel.isHidden = true
        }
    }
}
// MARK: - Creations
private extension AgoraRtmIMReceiveCell {
    func createViews() {
        avatarView = UIImageView()
        avatarView.image = UIImage.rmc_named("ic_rtm_avatar")
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = kAvatarHeight * 0.5
        contentView.addSubview(avatarView)
        
        nameLabel = UILabel()
        nameLabel.textColor = UIColor(hex: 0x191919)
        nameLabel.font = UIFont.systemFont(ofSize: 13)
        contentView.addSubview(nameLabel)
        
        roleLabel = UILabel()
        roleLabel.textColor = UIColor(hex: 0x586376)
        roleLabel.font = UIFont.systemFont(ofSize: 12)
        roleLabel.layer.borderWidth = 1
        roleLabel.layer.cornerRadius = kRoleLabelHeight * 0.5
        roleLabel.layer.borderColor = UIColor(hex: 0xABB1BA, transparency: 0.3)?.cgColor
        contentView.addSubview(roleLabel)
        
        bubleView = UIView()
        bubleView.backgroundColor = .white
        bubleView.layer.borderWidth = 1
        bubleView.layer.borderColor = UIColor(hex: 0xECECF1)?.cgColor
        bubleView.layer.cornerRadius = 4
        contentView.addSubview(bubleView)
        
        messageLabel = UILabel()
        messageLabel.textColor = UIColor(hex: 0x191919)
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 13)
        contentView.addSubview(messageLabel)
    }
    
    func createConstrains() {
        avatarView.snp.makeConstraints { make in
            make.top.equalTo(5)
            make.left.equalTo(14)
            make.width.height.equalTo(kAvatarHeight)
        }
        nameLabel.snp.makeConstraints { make in
            make.centerY.equalTo(avatarView)
            make.left.equalTo(avatarView.snp.right).offset(6)
        }
        roleLabel.snp.makeConstraints { make in
            make.height.equalTo(kRoleLabelHeight)
            make.left.equalTo(nameLabel.snp.right).offset(6)
            make.centerY.equalTo(nameLabel)
        }
        messageLabel.snp.makeConstraints { make in
            make.left.equalTo(25)
            make.top.equalTo(avatarView.snp.bottom).offset(17)
            make.right.lessThanOrEqualTo(-25)
            make.bottom.equalTo(self.contentView).offset(-15)
        }
        bubleView.snp.makeConstraints { make in
            make.left.equalTo(messageLabel).offset(-10)
            make.right.equalTo(messageLabel).offset(10)
            make.top.equalTo(messageLabel).offset(-9)
            make.bottom.equalTo(messageLabel).offset(9)
        }
    }
}
