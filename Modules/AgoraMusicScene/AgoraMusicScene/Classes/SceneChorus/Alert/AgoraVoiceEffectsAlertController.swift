//
//  AgoraSoundEffectAlertController.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/2/7.
//

import UIKit
import AgoraMusicEngine
import AgoraRtcKit

/** 音效弹窗*/
class AgoraVoiceEffectsAlertController: UIViewController {
    
    private var contentView: UIView!
    
    private var titleLabel: UILabel!
    
    private var tableView: UITableView!
    
    private var selectedIndexPath: IndexPath?
    
    private var selectedEffectIndex: ((Int) -> Void)?
    
    private var dataSource: [String] = [
        "默认(高保真)",
        "雄浑",
        "假音",
        "圆润",
        "低沉",
        "清澈",
        "高亢",
        "嘹亮",
        "男：小房间",
        "男：大房间",
        "男：大厅",
        "女：小房间",
        "女：大房间",
        "女：大厅",
    ]
    
    private var core: AgoraMusicCore
    
    deinit {
        print("\(self.classForCoder): \(#function)")
    }
    
    init(core: AgoraMusicCore) {
        self.core = core
        super.init(nibName: nil, bundle: nil)
        self.selectedIndexPath = IndexPath(row: 0, section: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createViews()
        self.createConstrains()
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
    
    fileprivate func convertIndexToEffect(with index: Int) -> AgoraVoiceBeautifierPreset {
        switch index {
        case 0:
            return .presetOff
        case 1:
            return .timbreTransformationVigorous
        case 2:
            return .timbreTransformationFalsetto
        case 3:
            return .timbreTransformationMellow
        case 4:
            return .timbreTransformationDeep
        case 5:
            return .timbreTransformationClear
        case 6:
            return .timbreTransformationResounding
        case 7:
            return .timbreTransformatRinging
        default:
            return .presetOff
        }
    }
    
    fileprivate func setEffect(with index: Int) {
        if index < 8 {
            let preset = convertIndexToEffect(with: index)
            self.core.engine.setVoiceBeautifierParameters(with: preset)
        } else {
            let offset = index - 7
            let gender: Int32 = offset > 3 ? 2 : 1
            let sound: Int = offset % 3 == 0 ? 3 : offset % 3
            self.core.engine.setVoiceBeautifierParameters(with: .presetSingingBeautifier, param1: gender, param2: Int32(sound))
        }
    }
}
// MARK: - TableViewCallBack
extension AgoraVoiceEffectsAlertController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: AgoraSoundEffectCell.self)
        let type = self.dataSource[indexPath.row]
        cell.infoLabel.text = type
        cell.aSelected = (self.selectedIndexPath == indexPath)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.dismiss(animated: true, completion: nil)
        self.tableView.reloadData()
        self.selectedEffectIndex?(indexPath.row)
        self.selectedIndexPath = indexPath
        
        setEffect(with: indexPath.row)
    }
}
// MARK: - Creations
private extension AgoraVoiceEffectsAlertController {
    func createViews() {
        contentView = UIView()
        contentView.backgroundColor = .white
        self.view.addSubview(contentView)
        
        titleLabel = UILabel()
        titleLabel.textColor = UIColor(hex: 0x1C004C)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.text = "人声效果"
        self.contentView.addSubview(titleLabel)
        
        tableView = UITableView.init(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView.init(frame: CGRect(x: 0, y: 0, width: 1, height: 0.01))
        tableView.rowHeight = 40
        tableView.separatorColor = UIColor(hex: 0xEEEEF7)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        tableView.register(cellWithClass: AgoraSoundEffectCell.self)
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
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(9)
            make.left.right.bottom.equalToSuperview()
        }
    }
}
// MARK: - AgoraSoundEffectCell
fileprivate class AgoraSoundEffectCell: UITableViewCell {
    
    public var infoLabel: UILabel!
    
    private var selectView: UIView!
    
    public var aSelected: Bool = false {
        didSet {
            if aSelected != oldValue {
                self.selectView.isHidden = !aSelected
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.createViews()
        self.createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createViews() {
        infoLabel = UILabel()
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.textColor = UIColor(hex: 0x1C004C)
        self.addSubview(infoLabel)
        
        selectView = UIView()
        selectView.borderWidth = 3
        selectView.borderColor = UIColor(hex: 0x9B44FD)
        selectView.layer.cornerRadius = 7
        selectView.isHidden = true
        self.addSubview(selectView)
    }
    
    func createConstrains() {
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        selectView.snp.makeConstraints { make in
            make.width.height.equalTo(14)
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
        }
    }
}
