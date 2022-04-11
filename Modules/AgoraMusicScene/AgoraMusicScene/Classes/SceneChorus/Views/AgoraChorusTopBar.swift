//
//  AgoraChorusTopBar.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/1/27.
//

import UIKit
import SwifterSwift

class AgoraChorusTopBar: UIView {
    
    public var backButton: UIButton!
    
    public var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        self.createViews()
        self.createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
// MARK: - Creations
private extension AgoraChorusTopBar {
    func createViews() {
        backButton = UIButton(type: .custom)
        backButton.setImage(UIImage.rmc_named("ic_navigation_back"), for: .normal)
        self.addSubview(backButton)
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = UIColor(hex: 0x1C004C)
        self.addSubview(titleLabel)
    }
    
    func createConstrains() {
        backButton.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(52)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right)
            make.width.lessThanOrEqualTo(220)
            make.centerY.equalToSuperview()
        }
    }
}
