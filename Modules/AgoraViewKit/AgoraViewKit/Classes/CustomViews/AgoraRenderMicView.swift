//
//  AgoraRenderMicView.swift
//  AgoraEduUI
//
//  Created by Jonathan on 2021/12/8.
//

import UIKit

public class AgoraRenderMicView: UIView {
    
    public enum AgoraRenderMicViewState {
        case on, off, forbidden
    }
    
    private var imageView: UIImageView!
    
    private var animaView: UIImageView!
    
    private var progressLayer: CAShapeLayer!
    
    private var micState: AgoraRenderMicViewState = .off
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.createViews()
        self.createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.progressLayer.frame = bounds
        let path = UIBezierPath.init()
        path.move(to: CGPoint(x: bounds.midX, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.midX, y: bounds.minY))
        self.progressLayer.lineWidth = bounds.width
        self.progressLayer.path = path.cgPath
    }
        
    public func setVolume(_ value: Int) {
        guard micState == .on else {
            return
        }
        let floatValue = min(CGFloat(value), 200.00)
        self.progressLayer.strokeEnd = floatValue / 200.0
    }
    
    public func setState(_ state: AgoraRenderMicViewState) {
        guard micState != state else {
            return
        }
        self.micState = state
        switch state {
        case .on:
            self.imageView.image = UIImage.avk_named("ic_mic_status_on")
            self.animaView.isHidden = false
        case .off:
            self.imageView.image = UIImage.avk_named("ic_mic_status_off")
            self.animaView.isHidden = true
        case .forbidden:
            self.imageView.image = UIImage.avk_named("ic_mic_status_forbidden")
            self.animaView.isHidden = true
        }
    }
}

private extension AgoraRenderMicView {
    func createViews() {
        imageView = UIImageView()
        imageView.image = UIImage.avk_named("ic_mic_status_off")
        addSubview(imageView)
        
        animaView = UIImageView()
        animaView.image = UIImage.avk_named("ic_mic_status_volume")
        animaView.isHidden  = true
        addSubview(animaView)
        
        progressLayer = CAShapeLayer()
        progressLayer.lineCap = .square
        progressLayer.strokeColor = UIColor.white.cgColor
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = 0
        animaView.layer.mask = progressLayer
    }
    
    func createConstrains() {
        imageView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        animaView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
}
