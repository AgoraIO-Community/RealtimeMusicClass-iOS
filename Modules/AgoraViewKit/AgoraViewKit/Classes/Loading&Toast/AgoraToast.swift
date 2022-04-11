//
//  AgoraToast.swift
//  AgoraUIEduBaseViews
//
//  Created by Jonathan on 2021/11/16.
//

import UIKit
import SnapKit

public class AgoraToast: UIView {
    
    /// 弹出Message提醒
    /// - parameter msg: 提醒内容
    /// - parameter type: 提醒框的样式
    @objc public static func toast(msg: String?) {
        guard let window = UIApplication.shared.keyWindow,
              let `msg` = msg else {
            return
        }
        if let t = window.subviews.first(where: {$0.isKind(of: AgoraToast.self)}) as? AgoraToast {
            t.hideAndRemove()
        }
        let t = AgoraToast.init(frame: .zero)
        t.label.text = msg
        window.addSubview(t)
        t.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        t.showAnimation()
    }
    
    private var contentView: UIView!
    
    private var label: UILabel!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView = UIView()
        contentView.alpha = 0
        contentView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.addSubview(contentView)
        
        label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13)
        self.contentView.addSubview(label)
        label.snp.makeConstraints { make in
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-100)
            } else {
                make.bottom.equalTo(-100)
            }
            make.centerX.equalTo(self)
        }
        
        contentView.snp.makeConstraints { make in
            make.left.equalTo(label).offset(-30)
            make.right.equalTo(label).offset(30)
            make.top.equalTo(label).offset(-6)
            make.bottom.equalTo(label).offset(6)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.cornerRadius = self.contentView.height * 0.5
    }
    
    private func showAnimation() {
        self.contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       options: .curveLinear) {
            self.contentView.transform = .identity
            self.contentView.alpha = 1
        } completion: { finish in
            self.hideAfterDelay()
        }
    }
    
    func hideAfterDelay() {
        self.perform(#selector(hideAndRemove), with: nil, afterDelay: 2)
    }
    
    @objc private func hideAndRemove() {
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       options: .curveLinear) {
            self.contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.contentView.alpha = 0
        } completion: { finish in
            self.removeFromSuperview()
        }
    }
    
}
