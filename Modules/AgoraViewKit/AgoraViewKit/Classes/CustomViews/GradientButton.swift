//
//  GradientButton.swift
//  AgoraSceneEntranceModule
//
//  Created by Jonathan on 2022/2/9.
//

import UIKit

public class GradientButton: UIButton {
    
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
        if let v = self.imageView {
            self.bringSubviewToFront(v)
        }
    }

}
