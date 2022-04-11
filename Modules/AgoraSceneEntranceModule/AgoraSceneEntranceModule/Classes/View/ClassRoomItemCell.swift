//
//  ClassRoomItemCell.swift
//  AgoraSceneEntranceModule
//
//  Created by Jonathan on 2022/2/8.
//

import UIKit

struct ClassRoomInfoModel: Decodable {
    let channelID: String
    let className: String
    let count: Int
    let creator: String
    let hasPasswd: Bool
}

class ClassRoomItemCell: UITableViewCell {
    
    private var containerView: UIView!
    
    private var nameLabel: UILabel!
    
    private var creatorLabel: UILabel!
    
    private var numLabel: UILabel!
    
    private var countLabel: UILabel!
    
    private var countIcon: UIImageView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.createViews()
        self.createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupWith(name: String, creator: String, num: String, count: Int) {
        self.nameLabel.text = "教室名称：\(name)"
        self.creatorLabel.text = "创建人：\(creator)"
        self.numLabel.text = "频道ID：\(num)"
        self.countLabel.text = "\(count)"
    }
    
}
// MARK: - ClassRoomItemCell
private extension ClassRoomItemCell {
    func createViews() {
        contentView.layer.shadowColor = UIColor(hex: 0x2F4192,
                                                transparency: 0.15)?.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowOpacity = 1
        contentView.layer.shadowRadius = 6
        
        containerView = UIView()
        containerView.layer.cornerRadius = 12
        containerView.backgroundColor = .white
        containerView.clipsToBounds = true
        self.contentView.addSubview(containerView)
        
        nameLabel = UILabel()
        nameLabel.textColor = UIColor(hex: 0x1C004C)
        nameLabel.font = UIFont.systemFont(ofSize: 13)
        self.containerView.addSubview(nameLabel)
        
        creatorLabel = UILabel()
        creatorLabel.textColor = UIColor(hex: 0x1C004C)
        creatorLabel.font = UIFont.systemFont(ofSize: 13)
        self.containerView.addSubview(creatorLabel)
        
        numLabel = UILabel()
        numLabel.textColor = UIColor(hex: 0x1C004C)
        numLabel.font = UIFont.systemFont(ofSize: 13)
        self.containerView.addSubview(numLabel)
        
        countLabel = UILabel()
        countLabel.textColor = UIColor(hex: 0x1C004C)
        countLabel.font = UIFont.systemFont(ofSize: 13)
        countLabel.textAlignment = .center
        self.containerView.addSubview(countLabel)
        
        countIcon = UIImageView(image: UIImage.rmc_named("ic_room_user_count"))
        self.containerView.addSubview(countIcon)
    }
    
    func createConstrains() {
        containerView.snp.makeConstraints { make in
            make.top.equalTo(14)
            make.left.equalTo(14)
            make.right.equalTo(-14)
            make.bottom.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(14)
        }
        creatorLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        numLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.bottom.equalTo(-14)
            make.right.equalTo(-16)
        }
        countLabel.snp.makeConstraints { make in
            make.top.equalTo(14)
            make.right.equalTo(-14)
            make.height.equalTo(24)
            make.width.equalTo(20)
        }
        countIcon.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.centerY.equalTo(countLabel)
            make.right.equalTo(countLabel.snp.left)
        }
    }
}
