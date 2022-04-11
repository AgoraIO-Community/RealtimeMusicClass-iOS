//
//  AgoraSoundsAlertController.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/2/7.
//

import UIKit

/** 音乐列表弹窗*/
class AgoraSoundsAlertController: UIViewController {
    
    public class func showInViewController(_ vc: UIViewController, list: [AgoraMusicModel], selected: AgoraMusicModel?, onSelected: @escaping (AgoraMusicModel)-> Void) {
        let alert = AgoraSoundsAlertController()
        alert.dataSource = list
        alert.selectedModel = selected
        alert.onSelected = onSelected
        vc.present(alert, animated: true, completion: nil)
    }
    
    private var contentView: UIView!
    
    private var titleLabel: UILabel!
    
    private var tableView: UITableView!
    
    private var selectedModel: AgoraMusicModel?
    
    private var dataSource = [AgoraMusicModel]()
    
    private var onSelected: ((AgoraMusicModel)-> Void)?
    
    deinit {
        print("\(self.classForCoder): \(#function)")
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
}
// MARK: - TableViewCallBack
extension AgoraSoundsAlertController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: AgoraChorusSoundCell.self)
        let music = self.dataSource[indexPath.row]
        cell.infoLabel.text = music.name
        cell.aSelected = (self.selectedModel == music)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let music = self.dataSource[indexPath.row]
        self.selectedModel = music
        self.tableView.reloadData()
        self.onSelected?(music)
    }
}
// MARK: - Creations
private extension AgoraSoundsAlertController {
    func createViews() {
        contentView = UIView()
        contentView.backgroundColor = .white
        self.view.addSubview(contentView)
        
        titleLabel = UILabel()
        titleLabel.textColor = UIColor(hex: 0x1C004C)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.text = "选择伴奏歌曲"
        self.contentView.addSubview(titleLabel)
        
        tableView = UITableView.init(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView.init(frame: CGRect(x: 0, y: 0, width: 1, height: 0.01))
        tableView.rowHeight = 40
        tableView.separatorColor = UIColor(hex: 0xEEEEF7)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        tableView.register(cellWithClass: AgoraChorusSoundCell.self)
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
// MARK: - AgoraChorusSoundCell
fileprivate class AgoraChorusSoundCell: UITableViewCell {
    
    public var infoLabel: UILabel!
    
    private var selectView: UIImageView!
    
    public var aSelected: Bool = false {
        didSet {
            infoLabel.textColor = aSelected ? UIColor(hex: 0x9B44FD) : UIColor(hex: 0x1C004C)
            selectView.isHidden = !aSelected
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
        
        selectView = UIImageView(image: UIImage.rmc_named("ic_chorus_sound"))
        selectView.isHidden = true
        self.addSubview(selectView)
    }
    
    func createConstrains() {
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        selectView.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
        }
    }
}

