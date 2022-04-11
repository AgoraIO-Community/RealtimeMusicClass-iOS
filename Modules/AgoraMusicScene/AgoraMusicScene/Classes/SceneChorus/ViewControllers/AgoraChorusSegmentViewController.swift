//
//  AgoraChorusSegmentView.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/1/27.
//

import UIKit
import AgoraMusicEngine
import CoreAudioTypes
import AgoraViewKit

protocol AgoraChorusSegmentViewDelegate: NSObjectProtocol {
    /** 选择中了音乐*/
    func didSelectMusicSegment()
    /** 选中了课件*/
    func didSelectBoardSegment()
}

fileprivate let kSegmentIndexKey = "segmentIndex"
class AgoraChorusSegmentViewController: UIViewController {
    
    weak var delegate: AgoraChorusSegmentViewDelegate?
    
    private var musicButton: UIButton!
    
    private var boardButton: UIButton!
    
    private var segmentLine: UIView!
    
    private var selectIndex: Int = 0 {
        didSet {
            if selectIndex != oldValue {
                self.updateSelectedSegment()
            }
        }
    }
    
    private var core: AgoraMusicCore
    
    deinit {
        print("\(self.classForCoder): \(#function)")
    }
    
    init(core: AgoraMusicCore) {
        self.core = core
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createViews()
        self.createConstrains()
        
        self.core.room.addListener(self)
    }
    
    @objc func onClickButton(_ sender: UIButton) {
        guard sender.isSelected == false else {
            return
        }
        guard let user = self.core.user.getLocalUser(),
              user.role == .owner
        else {
            AgoraToast.toast(msg: "只有老师才能切换音乐/课件")
            return
        }
        if sender == musicButton {
            self.core.room.setExtDataUpdate(key: kSegmentIndexKey, value: 0) { isSuccess in
                self.selectIndex = 0
            }
        } else if sender == boardButton {
            self.core.room.setExtDataUpdate(key: kSegmentIndexKey, value: 1) { isSuccess in
                self.selectIndex = 1
            }
        }
    }
    
    func updateSelectedSegment() {
        if self.selectIndex == 0 {
            self.musicButton.isSelected = true
            self.boardButton.isSelected = false
            self.delegate?.didSelectMusicSegment()
        } else {
            self.musicButton.isSelected = false
            self.boardButton.isSelected = true
            self.delegate?.didSelectBoardSegment()
        }
        let targetView: UIView = (selectIndex == 0) ? self.musicButton : self.boardButton
        self.view.layoutIfNeeded()
        self.segmentLine.snp.remakeConstraints { make in
            make.width.equalTo(16)
            make.height.equalTo(2)
            make.centerX.bottom.equalTo(targetView)
        }
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
}
// MARK: - AgoraMusicRoomHandler
extension AgoraChorusSegmentViewController: AgoraMusicRoomHandler {
    
    func onClassJoined() {
        guard let room = self.core.room.roomInfo,
              let index = room.ext?[kSegmentIndexKey] as? Int
        else {
            return
        }
        self.selectIndex = index
    }
    
    func onClassExtDataChanged(from: [String: Any]?, to: [String: Any]?) {
        guard let index = to?[kSegmentIndexKey] as? Int else {
            return
        }
        self.selectIndex = index
    }
}

// MARK: - Creations
private extension AgoraChorusSegmentViewController {
    func createViews() {
        musicButton = UIButton(type: .custom)
        musicButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        musicButton.setTitle("音乐", for: .normal)
        musicButton.isSelected = true
        musicButton.setTitleColor(UIColor(hex: 0x9B44FD), for: .selected)
        musicButton.setTitleColor(UIColor(hex: 0x443956), for: .normal)
        musicButton.addTarget(self, action: #selector(onClickButton(_:)), for: .touchUpInside)
        self.view.addSubview(musicButton)
        
        boardButton = UIButton(type: .custom)
        boardButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        boardButton.setTitle("课件", for: .normal)
        boardButton.setTitleColor(UIColor(hex: 0x9B44FD), for: .selected)
        boardButton.setTitleColor(UIColor(hex: 0x443956), for: .normal)
        boardButton.addTarget(self, action: #selector(onClickButton(_:)), for: .touchUpInside)
        self.view.addSubview(boardButton)
        
        segmentLine = UIView()
        segmentLine.backgroundColor = UIColor(hex: 0xBF6BF1)
        self.view.addSubview(segmentLine)
    }
    
    func createConstrains() {
        musicButton.snp.makeConstraints { make in
            make.left.equalTo(4)
            make.width.equalTo(52)
            make.top.bottom.equalTo(0)
        }
        boardButton.snp.makeConstraints { make in
            make.left.equalTo(musicButton.snp.right)
            make.width.equalTo(52)
            make.top.bottom.equalTo(0)
        }
        segmentLine.snp.makeConstraints { make in
            make.width.equalTo(16)
            make.height.equalTo(2)
            make.centerX.bottom.equalTo(musicButton)
        }
    }
}
