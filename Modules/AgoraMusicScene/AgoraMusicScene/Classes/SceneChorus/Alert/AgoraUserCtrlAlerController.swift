//
//  AgoraUserCtrlAlerController.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/2/25.
//

import UIKit
import AgoraMusicEngine
import AgoraViewKit

fileprivate protocol AgoraUserCtrlTypeCellDelegate: NSObjectProtocol {
    /** switch 选值改变*/
    func onChangeSwitchValue(isOn: Bool, at indexPath: IndexPath)
}

fileprivate class AgoraUserCtrlTypeCell: UITableViewCell {
    
    public weak var delegate: AgoraUserCtrlTypeCellDelegate?
    
    public var infoLabel: UILabel!
    
    public var indexPath: IndexPath?
    
    public var switchView: UISwitch!
    
    deinit {
        print("\(self.classForCoder): \(#function)")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.createViews()
        self.createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onClickSwitch(_ sender: UISwitch) {
        guard let indexPath = self.indexPath else {
            return
        }
        self.delegate?.onChangeSwitchValue(isOn: sender.isOn, at: indexPath)
    }
    
    func createViews() {
        infoLabel = UILabel()
        infoLabel.font = UIFont.systemFont(ofSize: 13)
        infoLabel.textColor = UIColor(hex: 0x191919)
        self.contentView.addSubview(infoLabel)
        
        switchView = UISwitch()
        switchView.onTintColor = UIColor(hex: 0x9B44FD)
        switchView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        switchView.addTarget(self, action: #selector(onClickSwitch(_:)), for: .touchUpInside)
        self.contentView.addSubview(switchView)
    }
    
    func createConstrains() {
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        switchView.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
        }
    }
}

private enum UserCtrlType: Int, CaseIterable {
    case camera
    case microPhone
}

class AgoraUserCtrlAlerController: UIViewController {
    
    public class func showInViewController(_ vc: UIViewController, user: UserInfo, core: AgoraMusicCore) {
        let alert = AgoraUserCtrlAlerController(core: core)
        alert.user = user
        alert.modalPresentationStyle = .overFullScreen
        alert.modalTransitionStyle = .crossDissolve
        vc.present(alert, animated: true, completion: nil)
    }
    
    private var contentView: UIView!
    
    private var closeButton: UIButton!
    
    private var titleLabel: UILabel!
    
    private var lineView: UIView!
        
    private var tableView: UITableView!
    
    private var user: UserInfo?
    
    private var core: AgoraMusicCore
    
    private var onSelected: ((UserInfo)-> Void)?
    
    init(core: AgoraMusicCore) {
        self.core = core
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(white: 0, alpha: 0.45)
        
        self.createViews()
        self.createConstrains()
        
        if let name = self.user?.userName {
            self.titleLabel.text = "学生\(name)的设备"
        }
    }
    
    @objc func onClickClose(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
// MARK: - AgoraUserCtrlTypeCellDelegate
extension AgoraUserCtrlAlerController: AgoraUserCtrlTypeCellDelegate {
    
    func onChangeSwitchValue(isOn: Bool, at indexPath: IndexPath) {
        guard let type = UserCtrlType.init(rawValue: indexPath.row),
              let userName = self.user?.userName
        else {
            return
        }
        switch type {
        case .camera:
            AgoraLoading.loading()
            self.core.user.setVideoStreamOn(isOn: isOn, userName: userName) { [weak self] isSuccess, ero in
                AgoraLoading.hide()
            }
        case .microPhone:
            AgoraLoading.loading()
            self.core.user.setAudioStreamOn(isOn: isOn, userName: userName) { isSuccess, ero in
                AgoraLoading.hide()
            }
        }
    }
}

// MARK: - TableViewCallBack
extension AgoraUserCtrlAlerController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserCtrlType.allCases.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: AgoraUserCtrlTypeCell.self)
        cell.delegate = self
        cell.indexPath = indexPath
        if let type = UserCtrlType.init(rawValue: indexPath.row),
           let user = self.user {
            switch type {
            case .camera:
                cell.infoLabel.text = "摄像头"
                cell.switchView.isOn = (user.media?.videoStreamState == .publish)
            case .microPhone:
                cell.infoLabel.text = "麦克风"
                cell.switchView.isOn = (user.media?.audioStreamState == .publish)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
// MARK: - Creations
private extension AgoraUserCtrlAlerController {
    
    func createViews() {
        contentView = UIView()
        contentView.backgroundColor = .white
        contentView.cornerRadius = 12
        self.view.addSubview(contentView)
        
        titleLabel = UILabel()
        titleLabel.textColor = UIColor(hex: 0x1C004C)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.text = "学生的设备"
        self.contentView.addSubview(titleLabel)
        
        closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage.rmc_named("ic_alert_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(onClickClose(_:)), for: .touchUpInside)
        self.contentView.addSubview(closeButton)
        
        lineView = UIView()
        lineView.backgroundColor = UIColor(hex: 0xECECF1)
        self.contentView.addSubview(lineView)
        
        tableView = UITableView.init(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = false
        tableView.tableFooterView = UIView.init(frame: CGRect(x: 0, y: 0, width: 1, height: 0.01))
        tableView.rowHeight = 40
        tableView.separatorColor = .clear
        tableView.register(cellWithClass: AgoraUserCtrlTypeCell.self)
        self.contentView.addSubview(tableView)
    }
    
    func createConstrains() {
        contentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(280)
            make.height.equalTo(164)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(17)
        }
        lineView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.height.equalTo(1)
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
        }
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.top.equalTo(4)
            make.right.equalTo(-4)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(lineView).offset(15)
            make.left.right.bottom.equalToSuperview()
        }
    }
}
