//
//  ChorusRoomEmptyView.swift
//  AgoraSceneEntranceModule
//
//  Created by Jonathan on 2022/2/10.
//

import UIKit

class ChorusRoomEmptyView: UIView {
    
    var imageView: UIImageView!
    
    var infoLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.createViews()
        self.createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ChorusRoomEmptyView {
    func createViews() {
        imageView = UIImageView(image: UIImage.rmc_named("img_room_empty"))
        self.addSubview(imageView)
        
        infoLabel = UILabel()
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.textColor = UIColor(hex: 0x6A6670)
        infoLabel.textAlignment = .center
        infoLabel.text = "暂无教室"
        self.addSubview(infoLabel)
    }
    
    func createConstrains() {
        infoLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(128)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(infoLabel.snp.top).offset(-16)
        }
    }
}
