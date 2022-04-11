//
//  AgoraUsersAlertController.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/2/8.
//

import UIKit
import AgoraMusicEngine
import AgoraViewKit

fileprivate let kAEC_MODE = "aecMode"
/** 用户列表弹窗*/
class AgoraUsersListController: UIViewController {
    
    private var contentView: UIView!
    
    private var titleLabel: UILabel!
    
    private var fnLabel: UILabel!
    
    private var fnStackView: UIStackView!
    
    private var tableView: UITableView!
    
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
        
        self.core.user.addListener(self)
        self.core.room.addListener(self)
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
}
// MARK: - TableViewCallBack
extension AgoraUsersListController: AgoraUserItemCellDelegate {
    
    func didSegmentValueChange(value: Int, at indexPath: IndexPath) {
        let user = self.core.user.userList[indexPath.row]
        if user.isLocalUser {
            // 本地设置回声消除
            let grade = AECGrade.gradeWithIndex(value)
            self.core.user.setLocalExtDataUpdate(key: kAEC_MODE, value: grade.rawValue, complete: nil)
        } else {
            self.core.user.setRemoteExtDataUpdate(with: user.userName, key: kAEC_MODE, value: AECGrade.gradeWithIndex(value).rawValue) { isSuccess in
                if isSuccess == false {
                    AgoraToast.toast(msg: "设置失败，请重试")
                }
            }
        }
    }
}
// MARK: - TableViewCallBack
extension AgoraUsersListController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.core.user.userList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: AgoraUserItemCell.self)
        cell.delegate = self
        cell.indexPath = indexPath
        let user = self.core.user.userList[indexPath.row]
        cell.infoLabel.text = user.nameRoleLabel()
        // segment settings
        var isShowEchoBar = false
        if let localUser = self.core.user.getLocalUser() {
            if (localUser.role == .owner && user.role != .audience) ||
                localUser.userName == user.userName {
                isShowEchoBar = true
            }
        }
        if isShowEchoBar {
            let mode = AECGrade.init(rawValue: (user.ext?[kAEC_MODE] as? Int) ?? 3) ?? .Standard
            cell.segmentView.isHidden = false
            cell.segmentView.index = mode.atIndex()
        } else {
            cell.segmentView.isHidden = true
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
    }
}
// MARK: - AgoraMusicRoomHandler
extension AgoraUsersListController: AgoraMusicRoomHandler {
    func onClassJoined() {
        guard let user = self.core.user.getLocalUser() else {
            return
        }
        if user.role == .audience {
            self.fnLabel.isHidden = true
            self.fnStackView.isHidden = true
        } else {
            self.fnLabel.isHidden = false
            self.fnStackView.isHidden = false
        }
        if let aec = user.ext?[kAEC_MODE] as? Int,
           let grade = AECGrade.init(rawValue: aec) {
            self.core.engine.enableAEC(with: grade)
        }
    }
}

// MARK: - AgoraMusicUserHandler
extension AgoraUsersListController: AgoraMusicUserHandler {
    func onRemoteUserJoined(user: UserInfo) {
        self.tableView.reloadData()
    }
    
    func onUserInfoUpdated(user: UserInfo) {
        self.tableView.reloadData()
    }
    
    func onRemoteUserLeaved(user: UserInfo) {
        self.tableView.reloadData()
    }
    
    func onUserExtDataChanged(user: UserInfo, from: [String: Any]?, to: [String: Any]?) {
        let fromAEC = from?[kAEC_MODE] as? Int ?? -1
        let toAEC = to?[kAEC_MODE] as? Int ?? 3
        guard fromAEC != toAEC,
              let localUser = self.core.user.getLocalUser()
        else {
            return
        }
        if user.isLocalUser,
           let grade = AECGrade.init(rawValue: toAEC) {
            self.core.engine.enableAEC(with: grade)
        }
        if localUser.role == .owner {
            self.tableView.reloadData()
        }
    }
}
// MARK: - Creations
private extension AgoraUsersListController {
    func createViews() {
        contentView = UIView()
        contentView.backgroundColor = .white
        self.view.addSubview(contentView)
        
        titleLabel = UILabel()
        titleLabel.textColor = UIColor(hex: 0x1C004C)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.text = "用户列表"
        self.contentView.addSubview(titleLabel)
        
        fnLabel = UILabel()
        fnLabel.textColor = UIColor(hex: 0x1C004C)
        fnLabel.font = UIFont.boldSystemFont(ofSize: 13)
        fnLabel.text = "（回声消除）"
        self.contentView.addSubview(fnLabel)
        
        fnStackView = UIStackView()
        fnStackView.backgroundColor = .clear
        fnStackView.axis = .horizontal
        fnStackView.spacing = 2
        fnStackView.distribution = .equalSpacing
        fnStackView.alignment = .fill
        view.addSubview(fnStackView)
        
        let zeroLabel = UILabel()
        zeroLabel.textColor = UIColor(hex: 0x1C004C)
        zeroLabel.font = UIFont.systemFont(ofSize: 13)
        zeroLabel.text = "零回声"
        fnStackView.addArrangedSubview(zeroLabel)
        
        let stdLabel = UILabel()
        stdLabel.textColor = UIColor(hex: 0x1C004C)
        stdLabel.font = UIFont.systemFont(ofSize: 13)
        stdLabel.text = "标准"
        fnStackView.addArrangedSubview(stdLabel)
        
        let fluencyLabel = UILabel()
        fluencyLabel.textColor = UIColor(hex: 0x1C004C)
        fluencyLabel.font = UIFont.systemFont(ofSize: 13)
        fluencyLabel.text = "流畅"
        fnStackView.addArrangedSubview(fluencyLabel)
        
        tableView = UITableView.init(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView.init(frame: CGRect(x: 0, y: 0, width: 1, height: 0.01))
        tableView.rowHeight = 40
        tableView.separatorColor = UIColor(hex: 0xEEEEF7)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        tableView.allowsSelection = false
        tableView.register(cellWithClass: AgoraUserItemCell.self)
        self.contentView.addSubview(tableView)
    }
    
    func createConstrains() {
        contentView.snp.makeConstraints { make in
            make.left.equalTo(6)
            make.right.equalTo(-6)
            make.bottom.equalToSuperview()
            make.height.equalTo(500)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.left.equalTo(18)
        }
        fnStackView.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.right.equalTo(-18)
            make.width.equalTo(120)
        }
        fnLabel.snp.makeConstraints { make in
            make.right.equalTo(fnStackView.snp.left).offset(-4)
            make.centerY.equalTo(fnStackView)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(9)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

fileprivate protocol AgoraUserItemCellDelegate: NSObjectProtocol {
    
    func didSegmentValueChange(value: Int, at indexPath: IndexPath)
}
// MARK: - AgoraUserItemCell
fileprivate class AgoraUserItemCell: UITableViewCell, AgoraSegmentViewDelegate {
    
    public var indexPath: IndexPath?
    
    public weak var delegate: AgoraUserItemCellDelegate?
    
    public var infoLabel: UILabel!
    
    public var segmentView: AgoraSegmentView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.createViews()
        self.createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func onClickSegment(at index: Int) {
        guard let indexPath = self.indexPath else {
            return
        }
        self.delegate?.didSegmentValueChange(value: index, at: indexPath)
    }
    
    func createViews() {
        infoLabel = UILabel()
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.textColor = UIColor(hex: 0x1C004C)
        self.contentView.addSubview(infoLabel)
        
        segmentView = AgoraSegmentView(count: 3, index: 1)
        segmentView.delegate = self
        self.contentView.addSubview(segmentView)
    }
    
    func createConstrains() {
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        segmentView.snp.makeConstraints { make in
            make.right.equalTo(-10)
            make.width.equalTo(120)
            make.top.bottom.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - AgoraUserItemCell
fileprivate protocol AgoraSegmentViewDelegate: NSObjectProtocol {
    func onClickSegment(at index: Int)
}

fileprivate class AgoraSegmentView: UIView {
    
    weak var delegate: AgoraSegmentViewDelegate?
    
    var contentView: UIStackView!
    
    var barView: UIView!
    
    var thumbView: UIView!
    
    var buttons = [UIButton]()
    
    public var maxCount: Int = 0 {
        didSet {
            if maxCount != oldValue {
                self.setupButtons()
            }
        }
    }
    
    public var index: Int = 0 {
        didSet {
            if index != oldValue {
                self.setupThumbView()
            }
        }
    }
    
    private let kBarHeight = 8
    
    private let kDefaultTag = 2341
    
    init(count: Int, index: Int) {
        super.init(frame: .zero)
        self.maxCount = count
        self.index = index
        
        self.createViews()
        self.createConstrains()
        self.setupButtons()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func onClickSegment(_ sender: UIButton) {
        let index = sender.tag - kDefaultTag
        self.index = index
        self.delegate?.onClickSegment(at: index)
    }
    
    private func setupButtons() {
        var temp = [UIButton]()
        for i in 0..<self.maxCount {
            let button = UIButton(type: .custom)
            button.tag = i + kDefaultTag
            button.addTarget(self, action: #selector(onClickSegment(_:)), for: .touchUpInside)
            
            let point = UIView()
            point.backgroundColor = .white
            point.cornerRadius = 3
            button.addSubview(point)
            point.snp.makeConstraints { make in
                make.width.height.equalTo(6)
                make.center.equalTo(button)
            }
            temp.append(button)
        }
        self.buttons = temp
        self.contentView.addArrangedSubviews(temp)
        if let fristButton = buttons.first,
           let lastButton = buttons.last {
            self.barView.snp.remakeConstraints { make in
                make.left.equalTo(fristButton.snp.centerX).offset(-3)
                make.right.equalTo(lastButton.snp.centerX).offset(3)
                make.height.equalTo(kBarHeight)
                make.centerY.equalToSuperview()
            }
        }
        self.setupThumbView()
    }
    
    private func setupThumbView() {
        let button = self.buttons[self.index]
        self.thumbView.snp.remakeConstraints { make in
            make.width.height.equalTo(16)
            make.center.equalTo(button)
        }
        self.layoutIfNeeded()
    }
    
    private func createViews() {
        barView = UIView()
        barView.backgroundColor = UIColor(hex: 0xEEEEF7)
        barView.layer.cornerRadius = 4
        barView.clipsToBounds = true
        self.addSubview(barView)
        
        contentView = UIStackView()
        contentView.backgroundColor = .clear
        contentView.axis = .horizontal
        contentView.distribution = .fillEqually
        contentView.alignment = .fill
        self.addSubview(contentView)
        
        thumbView = UIView()
        thumbView.backgroundColor = .white
        thumbView.borderColor = UIColor(hex: 0x9B44FD)
        thumbView.layer.cornerRadius = 8
        thumbView.layer.borderWidth = 5
        thumbView.layer.borderColor = UIColor(hex: 0x9B44FD)?.cgColor
        thumbView.clipsToBounds = true
        self.addSubview(thumbView)
    }
    
    private func createConstrains() {
        contentView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
    
}
private extension UserInfo {
    func nameRoleLabel() -> String {
        if self.isLocalUser {
            return "(我)\(self.userName)"
        } else if self.role == .owner {
            return "(老师)\(self.userName)"
        } else if self.role == .coHost {
            return "(学生)\(self.userName)"
        } else if self.role == .audience {
            return "(观众)\(self.userName)"
        }
        return self.userName
    }
}

private extension AECGrade {
    func atIndex() -> Int {
        switch self {
        case .NoEcho:
            return 0
        case .Standard:
            return 1
        case .Fluent:
            return 2
        }
    }
    
    static func gradeWithIndex(_ index: Int) -> AECGrade {
        switch index {
        case 0:
            return .NoEcho
        case 1:
            return .Standard
        case 2:
            return .Fluent
        default:
            return .Fluent
        }
    }
}
