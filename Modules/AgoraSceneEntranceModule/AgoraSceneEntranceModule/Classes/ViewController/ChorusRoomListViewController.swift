//
//  ChorusRoomListViewController.swift
//  AgoraSceneEntranceModule
//
//  Created by Jonathan on 2022/2/8.
//

import UIKit
import AgoraMusicEngine
import AgoraViewKit
import MJRefresh

private let kPageStartIndex = 1
private let kPageCount = 10
class ChorusRoomListViewController: UIViewController {
    
    private var emptyView: ChorusRoomEmptyView!
    
    private var tableView: UITableView!
    
    private var dataSource = [ClassRoomInfoModel]() {
        didSet {
            if dataSource.count == 0 {
                self.tableView.isHidden = true
            } else {
                self.tableView.reloadData()
                self.tableView.isHidden = false
            }
        }
    }
    
    private var createButton: GradientButton!
    
    private var entranceModel: ClassEntranceModel
    
    private var page: Int = kPageStartIndex
    
    init(entranceModel: ClassEntranceModel) {
        self.entranceModel = entranceModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(hex: 0xF9F9FC)
        self.title = "选择加入的教室"
        
        self.createViews()
        self.createConstrains()
        
        if entranceModel.role != .owner {
            self.createButton.isHidden = true
            self.tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
                self?.fetchRoomsData(isRefresh: true)
            })
            self.tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
                self?.fetchRoomsData(isRefresh: false)
            })
            self.tableView.mj_footer?.isAutomaticallyChangeAlpha = true
            self.tableView.mj_header?.beginRefreshing()
        } else {
            self.createButton.isHidden = false
            self.tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(fetchMineData))
            self.tableView.mj_header?.beginRefreshing()
        }
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "remove All", style: .plain, target: self, action: #selector(deleteAll))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.mj_header?.beginRefreshing()
    }
    
    @objc func onClickCreate(_ sender: UIButton) {
        let vc = ChorusRoomCreateViewController(entranceModel: self.entranceModel)
        self.navigationController?.pushViewController(vc, completion: nil)
    }
    
    @objc private func fetchMineData() {
        let path = "/room/my/\(self.entranceModel.userName)"
        AgoraRequest(path: path, method: .get).rmc_request(decodeTo: [ClassRoomInfoModel].self) { error, rsp in
            self.tableView.mj_header?.endRefreshing()
            if let `rsp` = rsp {
                self.dataSource = rsp
                self.tableView.reloadData()
            } else {
                AgoraToast.toast(msg: error?.message)
            }
        }
    }
    
    @objc private func fetchRoomsData(isRefresh: Bool) {
        var targetPage = kPageStartIndex
        if isRefresh {
            targetPage = kPageStartIndex
        } else {
            targetPage = self.page + 1
        }
        let path = "/room/list/\(targetPage)"
        AgoraRequest(path: path, method: .get).rmc_request(decodeTo: [ClassRoomInfoModel].self) { error, rsp in
            if isRefresh {
                self.tableView.mj_header?.endRefreshing()
                if let `rsp` = rsp {
                    self.page = targetPage
                    if rsp.count < kPageCount {
                        self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                    } else {
                        self.tableView.mj_footer?.endRefreshing()
                    }
                    self.dataSource = rsp
                    self.tableView.reloadData()
                } else {
                    AgoraToast.toast(msg: error?.message)
                }
            } else {
                if let `rsp` = rsp {
                    self.page = targetPage
                    if rsp.count < kPageCount {
                        self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                    } else {
                        self.tableView.mj_footer?.endRefreshing()
                    }
                    self.dataSource.append(contentsOf: rsp)
                    self.tableView.reloadData()
                } else {
                    self.tableView.mj_footer?.endRefreshing()
                    AgoraToast.toast(msg: error?.message)
                }
            }
        }
    }
    
    private func joinClassRoom() {
        AgoraLoading.loading()
        let path = "/room/enter/\(self.entranceModel.className)"
        let body = [
            "name": self.entranceModel.userName,
            "role": self.entranceModel.role.rawValue,
            "avatar": "",
            "password": self.entranceModel.password
        ] as [String : Any]
        AgoraRequest(path: path, body: body, method: .post).rmc_request(complete: { error, rsp in
            AgoraLoading.hide()
            if let _ = rsp {
                self.entranceModel.onEnterClassRoom?()
            } else {
                AgoraToast.toast(msg: error?.message)
            }
        })
    }
    
    @objc private func deleteAll() {
        AgoraLoading.loading()
        for room in self.dataSource {
            let path = "/room/\(room.className)"
            AgoraRequest(path: path, method: .delete).rmc_request(complete: { error, rsp in
                AgoraLoading.hide()
                self.tableView.reloadData()
            })
        }
    }
    
}
// MARK: - TableViewCallBack
extension ChorusRoomListViewController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: ClassRoomItemCell.self)
        let info = self.dataSource[indexPath.row]
        cell.setupWith(name: info.className,
                       creator: info.creator,
                       num: info.channelID,
                       count: info.count)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let info = self.dataSource[indexPath.row]
        if info.hasPasswd {
            RoomPasswordAlertController.showInViewController(self) { password in
                self.entranceModel.password = password
                self.entranceModel.className = info.className
                self.joinClassRoom()
            }
        } else {
            self.entranceModel.password = ""
            self.entranceModel.className = info.className
            self.joinClassRoom()
        }
    }
    
}
// MARK: - Creations
extension ChorusRoomListViewController {
    func createViews() {
        emptyView = ChorusRoomEmptyView(frame: .zero)
        self.view.addSubview(emptyView)
        
        tableView = UITableView.init(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView.init(frame: CGRect(x: 0, y: 0, width: 1, height: 0.01))
        tableView.rowHeight = 114
        tableView.separatorColor = .clear
        tableView.allowsSelection = true
        tableView.register(cellWithClass: ClassRoomItemCell.self)
        self.view.addSubview(tableView)

        createButton = GradientButton(type: .system)
        createButton.cornerRadius = 22
        createButton.setGradient(from: UIColor(hex: 0x641BDF), to: UIColor(hex: 0xD07AF5))
        createButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        createButton.setTitleColor(.white, for: .normal)
        createButton.addTarget(self, action: #selector(onClickCreate(_:)), for: .touchUpInside)
        createButton.setTitle("创建新教室", for: .normal)
        createButton.backgroundColor = UIColor(hex: 0x641BDF)
        self.view.addSubview(createButton)
    }
    
    func createConstrains() {
        emptyView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        createButton.snp.makeConstraints { make in
            make.width.equalTo(280)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-50)
        }
    }
}
