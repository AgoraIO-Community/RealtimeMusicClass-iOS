//
//  RoleSelectView.swift
//  AgoraMusicEngine
//
//  Created by Jonathan on 2022/2/11.
//

import UIKit

class RoleSelectView: UIView {
    
    public var button: UIButton!
    
    public var imageView: UIImageView!
    
    public var label: UILabel!
    
    private var selectImageView: UIImageView!
    
    private var selectedImage: UIImage?
    
    private var normaleImage: UIImage?
    
    public var isSelected: Bool = false {
        didSet {
            if isSelected {
                selectImageView.isHidden = false
                imageView.image = selectedImage
            } else {
                selectImageView.isHidden = true
                imageView.image = normaleImage
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.createViews()
        self.createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setImage(_ image: UIImage?, selectedImage: UIImage?) {
        self.normaleImage = image
        self.selectedImage = selectedImage
    }
}
// MARK: - Creations
private extension RoleSelectView {
    func createViews() {
        button = UIButton(type: .custom)
        self.addSubview(button)
        
        imageView = UIImageView()
        self.addSubview(imageView)
        
        selectImageView = UIImageView(image: UIImage.rmc_named("ic_role_check_box"))
        self.addSubview(selectImageView)
        
        label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(hex: 0x1C004C)
        label.textAlignment = .center
        self.addSubview(label)
    }
    
    func createConstrains() {
        button.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
        }
        selectImageView.snp.makeConstraints { make in
            make.centerY.equalTo(imageView.snp.bottom)
            make.centerX.equalToSuperview()
        }
        label.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
        }
    }
}
