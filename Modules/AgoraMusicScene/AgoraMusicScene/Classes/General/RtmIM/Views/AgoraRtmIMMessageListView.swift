//
//  AgoraRtmIMMessageListView.swift
//  AgoraWidgets
//
//  Created by Jonathan on 2021/12/16.
//

import UIKit
import SwifterSwift

class AgoraRtmIMMessageListView: UIView {
    
    var emptyImage: UIImageView!
    
    var emptyLabel: UILabel!
    
    var tableView: UITableView!
    
    var dataSource = [AgoraRtmMessageModel]()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        
        createViews()
        createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupHistoryMessages(list: [AgoraRtmMessageModel]) {
        guard list.count > 0 else {
            return
        }
        self.dataSource = list + self.dataSource
        handleMessageList()
    }
    
    public func appendMessage(message: AgoraRtmMessageModel) {
        dataSource.append(message)
        handleMessageList()
    }
    
    private func handleMessageList() {
        self.tableView.isHidden = (dataSource.count == 0)
        guard self.dataSource.count > 0 else {
            return
        }
        if dataSource.count >= 150 {
            dataSource.removeSubrange(0..<50)
        }
        tableView.reloadData {
            let index = IndexPath(row: self.dataSource.count - 1, section: 0)
            self.tableView.scrollToRow(at: index, at: .bottom, animated: true)
        }
    }
    
}
// MARK: - Table View Call Back
extension AgoraRtmIMMessageListView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = dataSource[indexPath.row]
        if model.isMine {
            let cell = tableView.dequeueReusableCell(withClass: AgoraRtmIMSendCell.self)
            cell.messageModel = model
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withClass: AgoraRtmIMReceiveCell.self)
            cell.messageModel = model
            return cell
        }
    }
}
// MARK: - Creations
private extension AgoraRtmIMMessageListView {
    func createViews() {
        emptyImage = UIImageView(image: UIImage.rmc_named("ic_rtm_no_message"))
        self.addSubview(emptyImage)
        
        emptyLabel = UILabel()
        emptyLabel.font = UIFont.systemFont(ofSize: 12)
        emptyLabel.textColor = UIColor(hex: 0x7D8798)
        emptyLabel.textAlignment = .center
        emptyLabel.text = "rtm_no_message".rmc_localized()
        self.addSubview(emptyLabel)
        
        tableView = UITableView.init(frame: .zero,
                                     style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 60
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = false
        tableView.allowsSelection = false
        tableView.isHidden = true
        tableView.register(cellWithClass: AgoraRtmIMReceiveCell.self)
        tableView.register(cellWithClass: AgoraRtmIMSendCell.self)
        self.addSubview(tableView)
    }
    
    func createConstrains() {
        emptyImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
            make.width.height.equalTo(80)
        }
        emptyLabel.snp.makeConstraints { make in
            make.centerX.equalTo(emptyImage)
            make.top.equalTo(emptyImage.snp.bottom).offset(3)
        }
        tableView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
}
