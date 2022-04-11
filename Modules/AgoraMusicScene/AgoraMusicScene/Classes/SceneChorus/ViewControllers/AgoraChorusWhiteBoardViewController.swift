//
//  AgoraChorusWhiteBoardViewController.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/1/28.
//

import UIKit
import Whiteboard
import AgoraMusicEngine
import Alamofire
import AgoraViewKit

fileprivate let kWhiteRegionDefault = "cn-hz";
fileprivate let kWhiteRegionCN = "cn-hz";
fileprivate let kWhiteRegionUS = "us-sv";
fileprivate let kWhiteRegionIN = "in-mum";
fileprivate let kWhiteRegionSG = "sg";
fileprivate let kWhiteRegionGB = "gb-lon";

fileprivate let kNetlessHost = "https://api.netless.link/v5"
fileprivate let kExtUUIDKey = "whiteBoardUUID"
fileprivate let kExtRoomTokenKey = "whiteBoardToken"

// 白板是合唱非必须功能，如果需要集成白板课件请移步官网获取对应ID和Token
// https://docs.agora.io/cn/Agora%20Platform/get_appid_token?platform=All%20Platforms#%E8%8E%B7%E5%8F%96-app-id
public let whiteBoardSDKToken: String = "NETLESSSDK_YWs9ejN6bFZsbXI2LUwtR2RhTCZub25jZT05NDkwZjk1MC05YTIxLTExZWMtOTgwOS00ZmRhZWU0ZWViYjYmcm9sZT0wJnNpZz03YjA4Nzc0MzQ3NzA0NDdlODZiZDE1YjJlNDRjNDAwMzg1M2RiNmQ3NmRmZDE3MmMwMWI2ZTEwZDdjMDZkZjU4>"
public let whiteBoardAppId = "kGoL8JohEeyYCU_a7k7rtg/TtrAAUJ8v33DqQ"
class AgoraChorusWhiteBoardViewController: UIViewController {
    
    var whiteBoardSDK: WhiteSDK!
    
    var whiteBoardView: WhiteBoardView!
    /** 课件加载按钮*/
    var loadButton: UIButton!
    
    private var ppts: [PPTModel]?
    
    private var pageView: WhiteBoardPageView!
    
    private var boardRoom: WhiteRoom?
    
    private enum BoardState {
        case loading
        case boardUnload
        case coursewareUnload
        case complete
    }
    
    private var state: BoardState = .complete {
        didSet {
            if state != oldValue {
                self.updateBoardState()
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
        
        self.createWhiteBoard()
        self.configWhiteBoard()
        self.whiteBoardView.backgroundColor = .white
        
        self.createViews()
        self.createConstrains()
        self.state = .boardUnload
        
        self.core.room.addListener(self)
    }
    
    func updateBoardState() {
        switch self.state {
        case .loading:
            self.loadButton.isHidden = true
        case .boardUnload:
            loadButton.setTitle("加载白板", for: .normal)
            self.loadButton.isHidden = false
        case .coursewareUnload:
            loadButton.setTitle("加载课件", for: .normal)
            self.loadButton.isHidden = false
        case .complete:
            self.loadButton.isHidden = true
        }
    }
    
    @objc func onClickLoadButton(_ sender: UIButton) {
        switch self.state {
        case .boardUnload:
            return
        case .coursewareUnload:
            self.loadCoursewareResource()
        case .complete:
            return
        default: break
        }
    }
}
// MARK: - WhiteBoardPageViewDelegate
extension AgoraChorusWhiteBoardViewController: WhiteBoardPageViewDelegate {
    func pageViewOnClickPreviousPage() {
        guard let boardRoom = boardRoom else {
            return
        }
        boardRoom.pptPreviousStep()
    }
    
    func pageViewOnClickNextPage() {
        guard let boardRoom = boardRoom else {
            return
        }
        boardRoom.pptNextStep()
    }
}
// MARK: - WhiteCommonCallbackDelegate
extension AgoraChorusWhiteBoardViewController: AgoraMusicRoomHandler {
    func onClassJoined() {
        guard let room = self.core.room.roomInfo,
              let user = self.core.user.getLocalUser()
        else {
            return
        }
        if let uuid = room.ext?[kExtUUIDKey] as? String,
           let token = room.ext?[kExtRoomTokenKey] as? String {
            self.joinRoomWith(uuid: uuid, roomToken: token)
        } else {
            if user.role == .owner {
                self.createWhiteBoardRoom()
            } else {
                // Do Noting
            }
        }
    }
    
    func onClassExtDataChanged(from: [String: Any]?, to: [String: Any]?) {
        guard let uuid = to?[kExtUUIDKey] as? String,
              let token = to?[kExtRoomTokenKey] as? String
        else {
            return
        }
        let fromUUID = (from?[kExtUUIDKey] as? String) ?? "No UUID"
        let fromToken = (from?[kExtRoomTokenKey] as? String) ?? "No Token"
        if fromUUID != uuid, fromToken != token {
            self.joinRoomWith(uuid: uuid, roomToken: token)
        }
    }
}
// MARK: - WhiteCommonCallbackDelegate
extension AgoraChorusWhiteBoardViewController: WhiteCommonCallbackDelegate {
    
}
// MARK: - WhiteRoomCallbackDelegate
extension AgoraChorusWhiteBoardViewController: WhiteRoomCallbackDelegate {
    
    func firePhaseChanged(_ phase: WhiteRoomPhase) {
        
    }
    
    func fireRoomStateChanged(_ modifyState: WhiteRoomState) {
        guard let boardRoom = boardRoom else {
            return
        }
        if let sceneState = modifyState.sceneState {
            self.pageView.updatePage(max: sceneState.scenes.count,
                                     current: sceneState.index + 1)
            boardRoom.scaleIframeToFit()
            boardRoom.scalePpt(toFit: .continuous)
        }
    }
    
    func fireDisconnectWithError(_ error: String) {
        
    }
    
    func fireKicked(withReason reason: String) {
        
    }
}
// MARK: - Whiteboard PPT
private extension AgoraChorusWhiteBoardViewController {
    // 设置角色权限及展示内容
    func setupLocalRoom() {
        guard let boardRoom = self.boardRoom,
              let localUser = self.core.user.getLocalUser()
        else {
            return
        }
        boardRoom.setWritable(localUser.role == .owner)
        self.pageView.viewType = (localUser.role == .owner) ? .pager : .number
    }
    // 检查课件状态
    func checkCoursewareResource() {
        guard let boardRoom = self.boardRoom else {
            return
        }
        print("white board scene path: \(boardRoom.sceneState.scenePath)")
        if boardRoom.sceneState.scenes.count != 1 {
            self.state = .complete
            self.pageView.updatePage(max: boardRoom.sceneState.scenes.count,
                                     current: boardRoom.sceneState.index + 1)
        } else {
            self.state = .coursewareUnload
        }
    }
    // 加载课件
    func loadCoursewareResource() {
        let path = "/api/whiteboard"
        AgoraRequest(path: path, method: .get).rmc_request(decodeTo: [PPTModel].self) { error, rsp in
            if rsp != nil {
                self.ppts = rsp
                self.setupWhiteBoardPPt()
                self.state = .complete
            } else {
                self.state = .coursewareUnload
            }
        }
    }
    // 设置白板PPT
    func setupWhiteBoardPPt() {
        guard let boardRoom = boardRoom else {
            return
        }
        var scenes = [WhiteScene]()
        self.ppts?.forEach({ model in
            scenes.append(
                WhiteScene(
                    name: model.name,
                    ppt: WhitePptPage(
                        src: model.src,
                        preview: model.preview,
                        size: CGSize(width: model.width, height: model.height)
                    )))
        })
        boardRoom.putScenes("/ppt", scenes: scenes, index: 0)
        boardRoom.setScenePath("/ppt/p1")
    }
}
// MARK: - Whiteboard Config
private extension AgoraChorusWhiteBoardViewController {
    func createWhiteBoard() {
        whiteBoardView = WhiteBoardView(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        self.view.addSubview(self.whiteBoardView)
        whiteBoardView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
    
    func configWhiteBoard() {
        let SDKconfig = WhiteSdkConfiguration(app: whiteBoardAppId)
        self.whiteBoardSDK = WhiteSDK(whiteBoardView: self.whiteBoardView, config: SDKconfig, commonCallbackDelegate: self)
    }
    // 创建白板房间
    func createWhiteBoardRoom() {
        guard let roomInfo = self.core.room.roomInfo else {
            return
        }
        let header = [
            "token": whiteBoardSDKToken,
            "region": kWhiteRegionCN
        ]
        let body = [
            "name": roomInfo.className,
            "limit": 110,
            "isRecord": false
        ] as [String: Any]
        let path = kNetlessHost + "/rooms"
        AF.request(path, method: .post, parameters: body, encoding: JSONEncoding.default, headers: HTTPHeaders(header), interceptor: nil, requestModifier: nil).responseData { response in
            guard response.error == nil,
                  let data = response.data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []),
                  let dictionary = json as? [String: Any],
                  let uuid = dictionary["uuid"] as? String
            else { // 白板创建失败
                self.state = .boardUnload
                print("white borad: 白板创建失败")
                return
            }
            // 保存白板的UUID
            self.core.room.setExtDataUpdate(key: kExtUUIDKey, value: uuid) { isSuccess in
                if isSuccess {
                    self.requestRoomToken(uuid: uuid)
                } else {
                    self.state = .boardUnload
                }
            }
        }
    }
    
    func requestRoomToken(uuid: String) {
        let path = kNetlessHost + "/tokens/rooms/\(uuid)"
        let header = [
            "token": whiteBoardSDKToken,
        ]
        let body = [
            "lifespan": 0,
            "role": "admin"
        ] as [String: Any]
        AF.request(path, method: .post, parameters: body, encoding: JSONEncoding.default, headers: HTTPHeaders(header), interceptor: nil, requestModifier: nil).responseData { response in
            guard response.error == nil,
                  let data = response.data,
                  let jsonStr = String(data: data, encoding: .utf8)
            else { // 白板创建失败
                self.state = .boardUnload
                print("white borad: 获取房间token失败")
                return
            }
            let userRoomToken = jsonStr.trimmingCharacters(in: .punctuationCharacters)
            // 保存白板的Token
            self.core.room.setExtDataUpdate(key: kExtRoomTokenKey, value: userRoomToken) { isSuccess in
                if isSuccess {
                    self.joinRoomWith(uuid: uuid, roomToken: userRoomToken)
                } else {
                    self.state = .boardUnload
                }
            }
        }
    }
    
    func joinRoomWith(uuid: String, roomToken: String) {
        guard let user = self.core.user.getLocalUser() else {
            return
        }
        let roomConfig = WhiteRoomConfig(uuid: uuid, roomToken: roomToken, uid: user.userName)
        self.whiteBoardSDK.joinRoom(with: roomConfig, callbacks: self) { isSuccess, room, error in
            if isSuccess {
                self.boardRoom = room
                self.setupLocalRoom()
                self.checkCoursewareResource()
            } else {
                self.state = .boardUnload
                // 加入白板房间失败
                AgoraToast.toast(msg: "加入白板房间失败，请重试")
            }
        }
    }
}
// MARK: - Creations
private extension AgoraChorusWhiteBoardViewController {
    func createViews() {
        loadButton = UIButton(type: .custom)
        loadButton.backgroundColor = .white
        loadButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        loadButton.setTitle("加载白板", for: .normal)
        loadButton.setTitleColor(.black, for: .normal)
        loadButton.layer.borderWidth = 1
        loadButton.layer.borderColor = UIColor.black.cgColor
        loadButton.layer.cornerRadius = 15
        loadButton.clipsToBounds = true
        loadButton.addTarget(self, action: #selector(onClickLoadButton(_:)), for: .touchUpInside)
        self.view.addSubview(loadButton)
        
        pageView = WhiteBoardPageView(type: .number)
        pageView.delegate = self
        self.view.addSubview(pageView)
    }
    
    func createConstrains() {
        loadButton.snp.makeConstraints { make in
            make.width.equalTo(80)
            make.height.equalTo(30)
            make.center.equalToSuperview()
        }
        pageView.snp.makeConstraints { make in
            make.right.bottom.equalTo(-8)
        }
    }
}
// MARK: - PPTModel
fileprivate struct PPTModel: Decodable {
    let name: String
    let src: String
    let preview: String
    let width: CGFloat
    let height: CGFloat
}
fileprivate protocol WhiteBoardPageViewDelegate: NSObjectProtocol {
    /** 点击了上一页*/
    func pageViewOnClickPreviousPage()
    /** 点击了下一页*/
    func pageViewOnClickNextPage()
}
// MARK: - WhiteBoardPageView
fileprivate class WhiteBoardPageView: UIView {
    
    public weak var delegate: WhiteBoardPageViewDelegate?
    
    public enum ViewType {
        case number
        case pager
    }
    
    private var pageLabel: UILabel!
    
    private lazy var prePageButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .disabled)
        button.setTitle("<", for: .normal)
        button.addTarget(self, action: #selector(onClickPrevious(_:)), for: .touchUpInside)
        self.addSubview(button)
        button.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(44)
        }
        return button
    }()
    
    private lazy var nextPageButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .disabled)
        button.setTitle(">", for: .normal)
        button.addTarget(self, action: #selector(onClickNext(_:)), for: .touchUpInside)
        self.addSubview(button)
        button.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
            make.width.equalTo(44)
        }
        return button
    }()
    
    public var viewType: ViewType = .number {
        didSet {
            guard viewType != oldValue else {
                return
            }
            if viewType == .number {
                self.prePageButton.isHidden = true
                self.nextPageButton.isHidden = true
                self.pageLabel.snp.updateConstraints { make in
                    make.width.equalTo(60)
                }
            } else {
                self.prePageButton.isHidden = false
                self.nextPageButton.isHidden = false
                self.updateView()
                self.pageLabel.snp.updateConstraints { make in
                    make.width.equalTo(120)
                }
            }
        }
    }
    
    private var maxPage: Int = 0
    
    private var currentPage: Int = 0
    
    init(type: ViewType = .number) {
        super.init(frame: .zero)
        
        self.createViews()
        self.createConstrains()
        self.updateView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        self.pageLabel.layer.cornerRadius = self.bounds.height * 0.5
    }
    
    @objc private func onClickPrevious(_ sender: UIButton) {
        self.delegate?.pageViewOnClickPreviousPage()
    }
    
    @objc private func onClickNext(_ sender: UIButton) {
        self.delegate?.pageViewOnClickNextPage()
    }
    
    public func updatePage(max: Int, current: Int) {
        self.maxPage = max
        self.currentPage = current
        self.updateView()
    }
    
    private func updateView() {
        self.pageLabel.text = "\(self.currentPage) / \(self.maxPage)"
        if self.viewType == .pager {
            self.nextPageButton.isEnabled = (self.currentPage < self.maxPage)
            self.prePageButton.isEnabled = (self.currentPage > 1)
        }
    }
    
    func createViews() {
        pageLabel = UILabel()
        pageLabel.textAlignment = .center
        pageLabel.textColor = .white
        pageLabel.font = UIFont.systemFont(ofSize: 12)
        pageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        pageLabel.clipsToBounds = true
        self.addSubview(pageLabel)
    }
    
    func createConstrains() {
        pageLabel.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(30)
            make.left.right.top.bottom.equalToSuperview()
        }
    }
}
