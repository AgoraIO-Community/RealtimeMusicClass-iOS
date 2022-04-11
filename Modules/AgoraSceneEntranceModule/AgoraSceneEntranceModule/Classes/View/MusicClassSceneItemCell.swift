//
//  MusicClassSceneItemCell.swift
//  AgoraSceneEntranceModule
//
//  Created by Jonathan on 2022/2/8.
//

import UIKit

protocol MusicClassSceneItemCellDelegate: NSObjectProtocol {
    /** 点击进入体验*/
    func onClickEnterAt(indexPath: IndexPath)
    /** 点击了解更多*/
    func onClickSeeMoreAt(indexPath: IndexPath)
}

class MusicClassSceneItemCell: UITableViewCell {
    
    public weak var delegate: MusicClassSceneItemCellDelegate?
    
    public var indexPath: IndexPath?
    
    private var containerView: UIView!
    
    private var gradientView: GradientView!
    
    public var titleLabel: UILabel!
    
    public var infoLabel: UILabel!
    
    public var sceneimageView: UIImageView!
    
    private var gapLine: UIView!
    
    private var enterButton: UIButton!
    
    private var moreButton: UIButton!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.createViews()
        self.createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    public func setGradient(from: UIColor?, to: UIColor?) {
        self.gradientView.setGradient(from: from, to: to)
    }
    
    @objc func onClickEnter(_ sender: UIButton) {
        guard let i = self.indexPath else {
            return
        }
        self.delegate?.onClickEnterAt(indexPath: i)
    }
    
    @objc func onClickSeeMore(_ sender: UIButton) {
        guard let i = self.indexPath else {
            return
        }
        self.delegate?.onClickSeeMoreAt(indexPath: i)
    }
    
}
// MARK: - Creations
private extension MusicClassSceneItemCell {
    func createViews() {
        contentView.layer.shadowColor = UIColor(hex: 0x2F4192,
                                                  transparency: 0.15)?.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowOpacity = 1
        contentView.layer.shadowRadius = 12
        
        containerView = UIView()
        containerView.layer.cornerRadius = 12
        containerView.backgroundColor = .white
        containerView.clipsToBounds = true
        self.contentView.addSubview(containerView)
        
        gradientView = GradientView()
        self.containerView.addSubview(gradientView)
        
        sceneimageView = UIImageView()
        self.containerView.addSubview(sceneimageView)
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = .white
        self.containerView.addSubview(titleLabel)
        
        infoLabel = UILabel()
        infoLabel.font = UIFont.boldSystemFont(ofSize: 13)
        infoLabel.textColor = .white
        self.containerView.addSubview(infoLabel)
        
        gapLine = UIView()
        gapLine.backgroundColor = UIColor(hex: 0xEEEEF7)
        self.containerView.addSubview(gapLine)
        
        enterButton = UIButton(type: .system)
        enterButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        enterButton.setTitle("进入体验", for: .normal)
        enterButton.setTitleColor(UIColor(hex: 0x9B44FD), for: .normal)
        enterButton.addTarget(self, action: #selector(onClickEnter(_:)), for: .touchUpInside)
        self.containerView.addSubview(enterButton)
        
        moreButton = UIButton(type: .system)
        moreButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        moreButton.setTitle("了解更多", for: .normal)
        moreButton.setTitleColor(UIColor(hex: 0x1C004C), for: .normal)
        moreButton.addTarget(self, action: #selector(onClickSeeMore(_:)), for: .touchUpInside)
        self.containerView.addSubview(moreButton)
    }
    
    func createConstrains() {
        containerView.snp.makeConstraints { make in
            make.top.equalTo(14)
            make.left.equalTo(14)
            make.right.equalTo(-14)
            make.bottom.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(30)
            make.top.equalTo(27)
        }
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        gapLine.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(44)
            make.bottom.centerX.equalToSuperview()
        }
        enterButton.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview()
            make.right.equalTo(gapLine.snp.left)
            make.height.equalTo(gapLine)
        }
        moreButton.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.left.equalTo(gapLine.snp.right)
            make.height.equalTo(gapLine)
        }
        gradientView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(gapLine.snp.top)
        }
        sceneimageView.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.centerY.equalTo(gradientView)
        }
    }
}

fileprivate class GradientView: UIView {
    
    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.red.cgColor, UIColor.yellow.cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        self.layer.insertSublayer(layer, at: 0)
        return layer
    }()

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.frame = self.bounds
    }
    
    public func setGradient(from: UIColor?, to: UIColor?) {
        self.gradientLayer.colors = [(from ?? .clear).cgColor, (to ?? .clear).cgColor]
    }
}
