//
//  InfoInputView.swift
//  AgoraSceneEntranceModule
//
//  Created by Jonathan on 2022/2/10.
//

import UIKit

class InfoInputView: UIView {
    
    public var isEnable: Bool = true {
        didSet {
            if isEnable {
                self.alpha = 1
            } else {
                self.alpha = 0
            }
        }
    }
    
    public var textField: UITextField!
        
    public var label: UILabel!
    
    private var line: UIView!
    
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
extension InfoInputView {
    func createViews() {
        textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 58, height: 40))
        textField.leftViewMode = .always
        textField.clearButtonMode = .whileEditing
        textField.autocorrectionType = .no
        self.addSubview(textField)
        
        label = UILabel()
        label.textColor = UIColor(hex: 0x1C004C)
        label.font = UIFont.systemFont(ofSize: 14)
        self.addSubview(label)
                
        let nameLine = UIView()
        nameLine.backgroundColor = UIColor(hex: 0xE3E3EC)
        textField.addSubview(nameLine)
        nameLine.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    func createConstrains() {
        textField.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        label.snp.makeConstraints { make in
            make.left.bottom.height.equalTo(textField)
            make.width.equalTo(58)
        }
    }
}
