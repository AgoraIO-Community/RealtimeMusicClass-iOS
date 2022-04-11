//
//  SceneEntranceViewController.swift
//  AgoraSceneEntranceModule
//
//  Created by Jonathan on 2022/1/27.
//

import UIKit
import SwifterSwift
import SnapKit
import AgoraMusicEngine
import AgoraViewKit

public protocol SceneEntranceViewControllerDelegate: NSObjectProtocol {
    /** 进入合唱场景*/
    func onEnterChorusSceneWithParams(className: String, userName: String)
    /** 进入合奏场景*/
    func onEnterEnsembleSceneWithParams()
    /** 进入陪练场景*/
    func onEnterPracticeSceneWithParams()
}

enum SceneEntranceRowType: Int {
    case chorus = 0, ensemble = 1, practice = 2
}

public class SceneEntranceViewController: UIViewController {
    
    public weak var delegate: SceneEntranceViewControllerDelegate?
    
    private var tableView: UITableView!
    
    private var infoLabel: UILabel!
    
    private var contactButton: UIButton!

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "EDU demo all in one"
        self.view.backgroundColor = UIColor(hex: 0xF9F9FC)
        self.createViews()
        self.createConstrains()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isTranslucent = false
    }
    
    @objc func onClickContact(_ sender: UIButton) {
        AgoraToast.toast(msg: "功能开发中")
    }
}
extension SceneEntranceViewController: MusicClassSceneItemCellDelegate {
    func onClickEnterAt(indexPath: IndexPath) {
        let rowType = SceneEntranceRowType(rawValue: indexPath.row)
        switch rowType {
        case .chorus:
            let model = ClassEntranceModel()
            model.onEnterClassRoom = { [weak self] in
                self?.delegate?.onEnterChorusSceneWithParams(className: model.className, userName: model.userName)
            }
            let vc = ChorusRoomRoleViewController(entranceModel: model)
            self.navigationController?.pushViewController(vc, completion: nil)
        case .ensemble:
            delegate?.onEnterEnsembleSceneWithParams()
        case .practice:
            delegate?.onEnterPracticeSceneWithParams()
        default: break
        }
    }
    
    func onClickSeeMoreAt(indexPath: IndexPath) {
        let rowType = SceneEntranceRowType(rawValue: indexPath.row)
        switch rowType {
        case .chorus:
            AgoraToast.toast(msg: "功能开发中")
        case .ensemble:
            AgoraToast.toast(msg: "功能开发中")
        case .practice:
            AgoraToast.toast(msg: "功能开发中")
        default: break
        }
    }
}
// MARK: - TableViewCallBack
extension SceneEntranceViewController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: MusicClassSceneItemCell.self)
        cell.indexPath = indexPath
        cell.delegate = self
        let rowType = SceneEntranceRowType(rawValue: indexPath.row)
        switch rowType {
        case .chorus:
            cell.titleLabel.text = "在线多人合唱教学"
            cell.infoLabel.text = "6人合唱延迟低于100ms"
            cell.sceneimageView.image = UIImage.rmc_named("ic_scene_chorus")
            cell.setGradient(from: UIColor(hex: 0x575FFF), to: UIColor(hex: 0xFF91FC))
        case .ensemble:
            cell.titleLabel.text = "在线乐器合奏"
            cell.infoLabel.text = "电乐器合奏延迟低于50ms"
            cell.sceneimageView.image = UIImage.rmc_named("ic_scene_ensemble")
            cell.setGradient(from: UIColor(hex: 0xFF7A83), to: UIColor(hex: 0xFFE07C))
        case .practice:
            cell.titleLabel.text = "在线钢琴陪练"
            cell.infoLabel.text = "支持二分镜头画面分离矫正"
            cell.sceneimageView.image = UIImage.rmc_named("ic_scene_practice")
            cell.setGradient(from: UIColor(hex: 0x52B6FF), to: UIColor(hex: 0xC796FF))
        default: break
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
// MARK: - Creations
extension SceneEntranceViewController {
    func createViews() {
        tableView = UITableView.init(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView.init(frame: CGRect(x: 0, y: 0, width: 1, height: 0.01))
        tableView.rowHeight = 164
        tableView.separatorColor = .clear
        tableView.allowsSelection = false
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        tableView.register(cellWithClass: MusicClassSceneItemCell.self)
        self.view.addSubview(tableView)
        
        infoLabel = UILabel()
        infoLabel.textColor = UIColor(hex: 0x1C004C)
        infoLabel.textAlignment = .center
        infoLabel.text = "agora.io"
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        self.view.addSubview(infoLabel)
        
        contactButton = UIButton(type: .system)
        contactButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        contactButton.setTitleColor(UIColor(hex: 0x9B44FD), for: .normal)
        contactButton.setTitle("联系我们", for: .normal)
        contactButton.addTarget(self, action: #selector(onClickContact(_:)), for: .touchUpInside)
        self.view.addSubview(contactButton)
    }
    
    func createConstrains() {
        tableView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        contactButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(28)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            } else {
                make.bottom.equalTo(-20)
            }
        }
        infoLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(contactButton.snp.top)
        }
    }
}
