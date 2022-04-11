//
//  AgoraToneAlertController.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/2/7.
//

import UIKit
import AgoraMusicEngine
import AVFAudio

/** 音量调音台弹窗*/
fileprivate let kVolumeDefaultValue = 100
class AgoraVolumeCtrlViewController: UIViewController {
    
    private var contentView: UIView!
    
    private var titleLabel: UILabel!
    
    private var tableView: UITableView!
    
    private var volumeCases = [MineVolumeCtrlType]()
    
    private var dataSource = [UserInfo]()
    
    private var inputVolume: Int = kVolumeDefaultValue
    
    private var earBackVolume: Int = kVolumeDefaultValue
    
    private var musicVolume: Int = kVolumeDefaultValue
    
    private var valueDict = [UserInfo: Int]()
    
    private var isHeadPhoneInsert = false {
        didSet { // 目前只有非观众会改变该值
            if isHeadPhoneInsert {
                if self.volumeCases.contains(.earBack) == false {
                    self.volumeCases.insert(.earBack, at: 1)
                    self.tableView.reloadData()
                }
            } else {
                if self.volumeCases.contains(.earBack) {
                    self.volumeCases.removeAll(.earBack)
                    self.tableView.reloadData()
                }
            }
        }
    }
        
    private var core: AgoraMusicCore
    
    deinit {
        print("\(self.classForCoder): \(#function)")
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
        self.core.user.addListener(self)
        
        if let user = self.core.user.getLocalUser(),
           user.role == .owner || user.role == .coHost {
            NotificationCenter.default.addObserver(self, selector: #selector(onAudioRouteChanged(_:)), name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.core.user.removeListener(self)
        
        if let user = self.core.user.getLocalUser(),
           user.role == .owner || user.role == .coHost {
            NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let point = touches.first?.location(in: self.view) else { return }
        let p = contentView.layer.convert(point, from: self.view.layer)
        if contentView.layer.contains(p) == false {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let maskPath = UIBezierPath(roundedRect: self.contentView.bounds, byRoundingCorners: [UIRectCorner.topRight, UIRectCorner.topLeft], cornerRadii: CGSize(width: 18, height: 18))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.contentView.bounds
        maskLayer.path = maskPath.cgPath
        self.contentView.layer.mask = maskLayer
    }
    
    func fetchData() {
        // local user options
        if let user = self.core.user.getLocalUser(),
           user.role == .owner || user.role == .coHost {
            var temp = [MineVolumeCtrlType]()
            temp.append(.output)
            temp.append(.music)
            self.volumeCases = temp
            // ear back
            let audioSession = AVAudioSession.sharedInstance()
            let currentRoute = audioSession.currentRoute
            for output in currentRoute.outputs {
                if output.portType == .headphones || output.portType == .bluetoothA2DP {
                    self.isHeadPhoneInsert = true
                    break
                }
            }
        } else {
            var temp = [MineVolumeCtrlType]()
            temp.append(.music)
            self.volumeCases = temp
        }
        // users
        var temp = [UserInfo: Int]()
        self.dataSource = self.core.user.userList.filter({
            return $0.isLocalUser == false && $0.role != .audience
        })
        for user in self.dataSource {
            if let value = self.valueDict[user] {
                temp.updateValue(value, forKey: user)
            } else {
                temp.updateValue(kVolumeDefaultValue, forKey: user)
            }
        }
        self.valueDict = temp
        self.tableView.reloadData()
    }
    
    @objc func onAudioRouteChanged(_ noti: Notification) {
        guard let userInfo = noti.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue)
        else {
            return
        }
        switch reason {
        case .newDeviceAvailable:
            self.isHeadPhoneInsert = true
            break
        case .oldDeviceUnavailable:
            self.isHeadPhoneInsert = false
            break
        default: ()
        }
    }
}
// MARK: - AgoraVolumeSliderCellDelegate
extension AgoraVolumeCtrlViewController: AgoraVolumeSliderCellDelegate {
    
    func onChangedVolumeValue(_ value: Int, at indexPath: IndexPath) {
        if indexPath.section == 0 {
            let type = self.volumeCases[indexPath.row]
            switch type {
            case .output:
                self.core.engine.adjustRecordingSignalVolume(with: value)
                self.inputVolume = value
            case .earBack:
                self.core.engine.setInEarMonitoringVolume(with: value)
                self.earBackVolume = value
            case .music:
                guard let user = self.core.user.getLocalUser() else {
                    return
                }
                if user.role == .audience {
                    self.core.engine.adjustUserPlaybackSignalVolume(with:kMPK_RTC_UID, volume: Int32(value))
                } else {
                    self.core.engine.adjustPlayoutVolume(with: Int32(value))
                }
                self.musicVolume = value
            }
        } else {
            let user = self.dataSource[indexPath.row]
            if let streamId = user.media?.streamId,
               let uid = UInt(streamId) {
                self.valueDict.updateValue(value, forKey: user)
                self.core.engine.adjustUserPlaybackSignalVolume(with: uid, volume: Int32(value))
            }
        }
    }
}
// MARK: - AgoraMusicUserHandler
extension AgoraVolumeCtrlViewController: AgoraMusicUserHandler {
    
    func onRemoteUserJoined(user: UserInfo) {
        guard user.isLocalUser == false, user.role != .audience else {
            return
        }
        self.dataSource.append(user)
        self.valueDict.updateValue(kVolumeDefaultValue, forKey: user)
        self.tableView.reloadData()
    }
    
    func onRemoteUserLeaved(user: UserInfo) {
        self.dataSource.removeAll(user)
        self.valueDict.removeValue(forKey: user)
        self.tableView.reloadData()
    }
}
// MARK: - TableViewCallBack
extension AgoraVolumeCtrlViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.volumeCases.count
        } else {
            return self.dataSource.count
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: AgoraVolumeSliderCell.self)
        cell.delegate = self
        cell.indexPath = indexPath
        if indexPath.section == 0 {
            let type = self.volumeCases[indexPath.row]
            switch type {
            case .output:
                cell.titleLabel.text = "我"
                cell.setSliderValue(min: 0, max: 100, current: self.inputVolume)
            case .earBack:
                cell.titleLabel.text = "耳返"
                cell.setSliderValue(min: 0, max: 100, current: self.earBackVolume)
            case .music:
                cell.titleLabel.text = "伴奏"
                cell.setSliderValue(min: 0, max: 100, current: self.musicVolume)
            }
        } else {
            let user = self.dataSource[indexPath.row]
            cell.titleLabel.text = user.userName
            let value = self.valueDict[user] ?? kVolumeDefaultValue
            cell.setSliderValue(min: 0, max: 400, current: value)
        }
        return cell
    }
}
// MARK: - Creations
private extension AgoraVolumeCtrlViewController {
    
    func createViews() {
        contentView = UIView()
        contentView.backgroundColor = .white
        self.view.addSubview(contentView)
        
        titleLabel = UILabel()
        titleLabel.textColor = UIColor(hex: 0x1C004C)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.text = "调音台"
        self.contentView.addSubview(titleLabel)
        
        tableView = UITableView.init(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView.init(frame: CGRect(x: 0, y: 0, width: 1, height: 40))
        tableView.rowHeight = 40
        tableView.separatorColor = .clear
        tableView.allowsSelection = false
        tableView.register(cellWithClass: AgoraVolumeSliderCell.self)
        self.contentView.addSubview(tableView)
    }
    
    func createConstrains() {
        contentView.snp.makeConstraints { make in
            make.left.equalTo(6)
            make.right.equalTo(-6)
            make.bottom.equalToSuperview()
            make.height.equalTo(346)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.left.equalTo(18)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(9)
            make.left.right.bottom.equalToSuperview()
        }
    }
}
protocol AgoraVolumeSliderCellDelegate: NSObjectProtocol {
    
    func onChangedVolumeValue(_ value: Int, at indexPath: IndexPath)
}
// MARK: - AgoraVolumeSliderCell
fileprivate class AgoraVolumeSliderCell: UITableViewCell {
    
    public weak var delegate: AgoraVolumeSliderCellDelegate?
    
    public var titleLabel: UILabel!
    
    public var indexPath: IndexPath?
    
    private var sliderView: UISlider!
    
    private var valueLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.createViews()
        self.createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSliderValue(min: Int, max: Int, current: Int) {
        self.sliderView.minimumValue = min.float
        self.sliderView.maximumValue = max.float
        self.sliderView.value = current.float
        self.valueLabel.text = "\(self.sliderView.value.int)"
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        self.valueLabel.text = "\(sender.value.int)"
    }
    
    @objc func sliderTouched(_ sender: UISlider) {
        guard let indexPath = self.indexPath else {
            return
        }
        self.delegate?.onChangedVolumeValue(sender.value.int, at: indexPath)
    }
    
    private func createViews() {
        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor(hex: 0x1C004C)
        self.addSubview(titleLabel)
        
        sliderView = UISlider()
        sliderView.minimumValue = 0
        sliderView.maximumValue = 240
        sliderView.tintColor = UIColor(hex: 0x9B44FD)
        sliderView.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        sliderView.addTarget(self, action: #selector(sliderTouched(_:)), for: .touchUpInside)
        sliderView.addTarget(self, action: #selector(sliderTouched(_:)), for: .touchUpOutside)
        self.contentView.addSubview(sliderView)
        
        valueLabel = UILabel()
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        valueLabel.textAlignment = .right
        valueLabel.textColor = UIColor(hex: 0x586376)
        self.contentView.addSubview(valueLabel)
    }
    
    private func createConstrains() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.width.equalTo(64)
            make.centerY.equalToSuperview()
        }
        valueLabel.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.width.equalTo(30)
            make.centerY.equalToSuperview()
        }
        sliderView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right)
            make.right.equalTo(valueLabel.snp.left)
            make.centerY.equalToSuperview()
        }
    }
}

fileprivate enum MineVolumeCtrlType: Int, CaseIterable {
    // 输出
    case output
    // 耳返
    case earBack
    // 伴奏
    case music
}
