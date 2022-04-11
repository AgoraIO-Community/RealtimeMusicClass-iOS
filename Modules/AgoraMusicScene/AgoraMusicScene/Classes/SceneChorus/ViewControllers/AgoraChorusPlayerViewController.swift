//
//  AgoraChorusPlayerViewController.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/1/27.
//

import UIKit
import AgoraRtcKit
import AgoraMusicEngine

class AgoraChorusPlayerViewController: UIViewController {
    
    private lazy var lrcScoreView: AgoraLrcScoreView = {
        let lrcScoreView = AgoraLrcScoreView(delegate: self)
        let config = AgoraLrcScoreConfigModel()
        config.isHiddenScoreView = true
        let lrcConfig = AgoraLrcConfigModel()
        lrcConfig.lrcFontSize = .systemFont(ofSize: 15)
        lrcConfig.tipsColor = .white

        lrcConfig.isHiddenWatitingView = true
        lrcConfig.isHiddenBottomMask = true
        config.lrcConfig = lrcConfig
        lrcScoreView.config = config
        return lrcScoreView
    }()
    
    private lazy var effectVC: AgoraVoiceEffectsAlertController = {
       weak var weakSelf = self
        return AgoraVoiceEffectsAlertController(core: weakSelf!.core)
    }()
    
    private var musicList: [AgoraMusicModel]?
    
    fileprivate var imageView: UIImageView!
    
    fileprivate var musicLabel: UILabel!
    
    fileprivate var musicStateBtn: UIButton!
    
    fileprivate var mixerBtn: UIButton!
    
    fileprivate var changeBtn: UIButton!
    
    fileprivate var effectBtn: UIButton!
    
    fileprivate var bgmTimer: DispatchSourceTimer?
    fileprivate var statusTimer: DispatchSourceTimer?
    
    fileprivate let start_check_ts = "start_check_ts"
    fileprivate let play_status = "play_status"
    fileprivate let pause_status = "pause_status"
    fileprivate let bgm_change = "bgm_change"
    fileprivate let check_ts_ret = "check_ts"
    fileprivate var delayWithBrod:CLongLong = 0
    fileprivate var lastSeekTime:CLongLong = 0
    fileprivate var lastExpectLocalPosition:CLongLong = 0
    fileprivate var seekTime:CLongLong = 0
    fileprivate var delay:CLongLong = 0
    fileprivate var needSeek = false
    fileprivate var musicLength:CLongLong = 0
    fileprivate var musicPosition:CLongLong = 0
    fileprivate var pauseTime = 0
    fileprivate let delayPlayTime = 500
    
    fileprivate var isPlayerPause: Bool = true
    fileprivate var isPlayComplete: Bool = false
    
    fileprivate var selectMusic: AgoraMusicModel?
    
    /** 歌曲获取工具*/
    private lazy var musicPresenter: AgoraMusicResourcePresenter = {
        let p = AgoraMusicResourcePresenter()
        p.fetchData()
        return p
    }()
    
    /** 用户音量控制器*/
    private lazy var volumeController: AgoraVolumeCtrlViewController = {
        weak var weakSelf = self
        let vc = AgoraVolumeCtrlViewController(core: weakSelf!.core)
        return vc
    }()
    
    fileprivate var localUser: UserInfo! = UserInfo() {
        didSet {
        }
    }
    
    private var currentTimeStr: String = "00:00"
    
    private var totalTimeStr: String = "00:00"
    
    fileprivate var currentTime: TimeInterval = 0 {
        didSet {
            let current = Int(currentTime)
            let sec = current % 60
            let min = current / 60
            let secStr: String = sec < 10 ? "0\(sec)" : "\(sec)"
            let minStr: String = min < 10 ? "0\(min)" : "\(min)"
            currentTimeStr = "\(minStr):\(secStr)"
            DispatchQueue.main.async {[weak self] in
                self?.musicStateBtn.setTitle("\(self?.currentTimeStr ?? "")/\(self?.totalTimeStr ?? "")", for: .normal)
            }
        }
    }
    
    fileprivate var totalTime: TimeInterval = 0 {
        didSet {
            let total = Int(totalTime)
            let sec = total % 60
            let min = total / 60
            let secStr: String = sec < 10 ? "0\(sec)" : "\(sec)"
            let minStr: String = min < 10 ? "0\(min)" : "\(min)"
            totalTimeStr = "\(minStr):\(secStr)"
            DispatchQueue.main.async {[weak self] in
                self?.musicStateBtn.setTitle("\(self?.currentTimeStr ?? "")/\( self?.totalTimeStr ?? "")", for: .normal)
            }
        }
    }
    
    fileprivate var lrcUrl: String = "" {
        didSet {
            lrcScoreView.setLrcUrl(url: lrcUrl)
        }
    }
    
    private var core: AgoraMusicCore
    
    deinit {
        print("\(self.classForCoder): \(#function)")
        lrcScoreView.stop()
        bgmTimer?.cancel()
        bgmTimer = nil
        statusTimer?.cancel()
        statusTimer = nil
        
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
        self.core.engine.playerDelegate = self
        
        DispatchQueue.global().async{[weak self] in
            guard let musicList = self?.musicPresenter.sounds else {
                return
            }

            self?.musicList = musicList
            
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    fileprivate func loadBGMTimer(){
        
        if bgmTimer != nil {
            bgmTimer?.cancel()
            bgmTimer = nil
        }

        bgmTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())

        bgmTimer?.schedule(deadline: .now() + .seconds(2), repeating: DispatchTimeInterval.seconds(1), leeway: DispatchTimeInterval.seconds(0))
     
        bgmTimer?.setEventHandler {[weak self] in
            self?.checkTS()
       }
        bgmTimer?.resume()

    }

    fileprivate func loadStatusTimer() {
        
        if statusTimer != nil {
            statusTimer?.cancel()
            statusTimer = nil
        }
        
        statusTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())

        statusTimer?.schedule(deadline: .now() + .milliseconds(100), repeating: DispatchTimeInterval.seconds(1), leeway: DispatchTimeInterval.seconds(0))

        statusTimer?.setEventHandler {[weak self] in
            self?.sendStatus()
        }
        statusTimer?.resume()
  
    }
    
    @objc fileprivate func checkTS(){
        if localUser?.role == .coHost {
            startCheckTs()
        }
    }
    
    @objc fileprivate func sendStatus() {
        if localUser?.role == .owner {
 
            var position: CLongLong = 0
            
            position = CLongLong(self.core.engine.getPosition())
            
            sendPlayStatus(position: position)
            
        }
    }
    
    
    //学生发送对时
    @objc private func startCheckTs(){
        if localUser!.role != .coHost {
            return
        }
        let ms = CLongLong(round(Date().timeIntervalSince1970*1000))
        let check: CheckReq = CheckReq()
        guard let uid = localUser.media?.streamId else {return}
        check.uid = uid
        check.startTs = ms
        
        guard let data = AgoraDataStreamMessageParser.buildMessage(type: .start_check_ts, payload: check) else {return}
        let _ = self.core.engine.sendStreamMessage(with: data)

    }
    
    //老师发送状态
    func sendPlayStatus(position:CLongLong){
        if localUser!.role != .owner {
            return
        }
        let ms = CLongLong(round(Date().timeIntervalSince1970*1000))
        
        guard let selectMusic = self.selectMusic else {return}
        
        let state: MusicState = MusicState()
        state.Duration = CLongLong(self.core.engine.getDuration())
        state.position = position
        state.bgmId = selectMusic.identifier
        state.broadTs = ms
        
        guard let data = AgoraDataStreamMessageParser.buildMessage(type: self.isPlayerPause == false ? .play_status : .pause_status, payload: state) else {return}
        let _ = self.core.engine.sendStreamMessage(with: data)
   
    }
    
    func changeBgm(with music: AgoraMusicModel) {
        if selectMusic == music  {return}
        selectMusic = music
        
        self.core.engine.stop()
        
        self.core.engine.open(with: music.musicPath, startPos: 0)
        
        musicLabel.text = "音乐: \(music.name)"
        
        if musicStateBtn.isHidden == true {
            musicStateBtn.isHidden = false
        }
        
        lrcScoreView.setLrcUrl(url: music.lrcPath)

        lrcScoreView.resetTime()
        lrcScoreView.scrollToTop()
        
    }
}


//MARK: - AgoraMusicRoomHandler
extension AgoraChorusPlayerViewController: AgoraMusicRoomHandler{
    
    func onClassJoined() {

        guard let local = self.core.user.getLocalUser() else {return}
        localUser = local
        
        lrcScoreView.isUserInteractionEnabled = local.role == .owner

        lrcScoreView.setLrcUrl(url: "https://github.com/cleven1/KTVLrcScore/blob/main/007.xml")

        guard let lrcConfig = lrcScoreView.config?.lrcConfig else{return}
        
        if local.role != .owner {
            musicStateBtn.setImage(UIImage(), for: .normal)
            musicStateBtn.isUserInteractionEnabled = false
            
            if local.role == .coHost {
                mixerBtn.isHidden = false
                effectBtn.isHidden = false
                mixerBtn.snp.remakeConstraints { make in
                    make.right.equalToSuperview().offset(-26)
                    make.bottom.equalToSuperview().offset(-20)
                    make.width.equalTo(70)
                    make.height.equalTo(30)
                }
            } else {
                mixerBtn.isHidden = false
                mixerBtn.snp.remakeConstraints { make in
                    make.right.equalToSuperview().offset(-26)
                    make.bottom.equalToSuperview().offset(-20)
                    make.width.equalTo(70)
                    make.height.equalTo(30)
                }
            }
            
            lrcConfig.tipsString = "老师尚未选择演唱歌曲"
            if local.role == .audience {
                
                lrcScoreView.updateLrcConfig = lrcConfig
                return
                
            }
            
        } else {
            mixerBtn.isHidden = false
            effectBtn.isHidden = false
            changeBtn.isHidden = false
            lrcConfig.tipsString = "请老师选择演唱歌曲"
            changeMusic()
        }
        
        lrcScoreView.updateLrcConfig = lrcConfig
        
        if local.role != .audience {
            loadBGMTimer()
            loadStatusTimer()
        }
        
    }
    
}

//MARK: - AgoraMusicPlayerDelegate
extension AgoraChorusPlayerViewController: AgoraMusicPlayerDelegate {
    
    func getJSONStringFromDictionary(dictionary:Dictionary<String, Any>) -> String {
        if (!JSONSerialization.isValidJSONObject(dictionary)) {
            return ""
        }
        let data : NSData! = try? JSONSerialization.data(withJSONObject: dictionary, options: []) as NSData?
        let JSONString = NSString(data:data as Data,encoding: String.Encoding.utf8.rawValue)
        return JSONString! as String
        
    }
    
    func didReceiveStreamMsgOfUid(uid: UInt, data: Data) {
        let ms = CLongLong(round(Date().timeIntervalSince1970*1000))
        guard let dict = dataToDictionary(data: data) else {return}
        
        let jsonStr = getJSONStringFromDictionary(dictionary: dict)
        
        guard let obj = AgoraDataStreamMessageParser.decodeMessage(jsonStr, type: AgoraDataStreamMessage.self) else {return}
        guard let type = obj.type else {return}
        guard let payload = obj.msg else {return}
        
        let state = self.core.engine.getPlayerState()
        
        if localUser?.role == .owner {//老师
            
            if selectMusic == nil {return}// 没有选择歌曲就不发送
            
            if type == .start_check_ts {
                
                guard let model: CheckReq = AgoraDataStreamMessageParser.decodeMessage(payload, type: CheckReq.self) else {return}
                
                let resp: CheckResp = CheckResp()
                resp.broadTs = ms
                resp.position = CLongLong(self.core.engine.getPosition())
                resp.remoteTS = model.startTs
                resp.remoteUid = model.uid
                
                guard let data = AgoraDataStreamMessageParser.buildMessage(type: .check_ts_resp, payload: resp) else {return}
                _ = self.core.engine.sendStreamMessage(with: data)
                
            }
            
        } else if localUser?.role == .coHost {//学生
            
            if type == .pause_status {
                
                guard let model: MusicState = AgoraDataStreamMessageParser.decodeMessage(payload, type: MusicState.self) else {return}
                
                guard let music = self.musicPresenter.musicWithID(identifer: model.bgmId) else {
                    return
                }
                
                if lrcScoreView.isStart {
                    lrcScoreView.stop()
                }
                
                changeBgm(with: music)
                
                self.core.engine.pause()
                
                if currentTime != (Double(model.position) / 1000.0) {
                    currentTime = (Double(model.position) / 1000.0)
                    lrcScoreView.scrollToTime(timestamp: currentTime)
                    self.core.engine.seek(to: Int(model.position))
                    
//                    guard let lrcConfig = lrcScoreView.config?.lrcConfig else{return}
//                    lrcConfig.lrcDrawingColor = .gray
//                    lrcScoreView.updateLrcConfig = lrcConfig
                }
                
                totalTime =  Double(model.Duration) / 1000.0
                
                self.isPlayerPause = true
                
            }
            
            
            if type == .play_status {
                
                if self.isPlayerPause == true {
                    
                    self.isPlayerPause = false
                    
                }
                
                guard let model: MusicState = AgoraDataStreamMessageParser.decodeMessage(payload, type: MusicState.self) else {return}
                
                guard let music = self.musicPresenter.musicWithID(identifer: model.bgmId) else {
                    return
                }
                
                changeBgm(with: music)
                
//                guard let lrcConfig = lrcScoreView.config?.lrcConfig else{return}
//                lrcConfig.lrcDrawingColor = .orange
//                lrcScoreView.updateLrcConfig = lrcConfig
                
                if model.position < 0 {
                    // stopPlay()
                } else if model.position == 0 {
                    if state == AgoraMediaPlayerState.openCompleted {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayPlayTime-Int(delay)) / 1000.0) {[weak self] in
                            self?.startPlayMusic(duration: model.Duration)
                        }
                    } else if state == .paused {
                        startPlayMusic(duration: model.Duration)
                    }
                }else {
                    let expLocalTs = model.broadTs - model.position - delayWithBrod
                    if (delayWithBrod == 0) {
                        
                    }
                    
                    if state == .playing {
                        let localPosition :CLongLong = CLongLong((self.core.engine.getPosition()))
                        if lastSeekTime != 0 {
                            seekTime = lastExpectLocalPosition + (ms-lastSeekTime) - localPosition
                            lastSeekTime = 0
                            lastExpectLocalPosition = 0
                        }
                        let errTime = abs(Int(ms-localPosition-expLocalTs))
                        if errTime > 40 {
                            print("player log1: \(errTime) delay: \(delay)")
                            var expSeek = ms-expLocalTs
                            expSeek += seekTime
                            needSeek = true
                        }
                    } else if state == .openCompleted {
                        self.core.engine.play()
                        lrcScoreView.start()
    
                        _ = self.core.engine.seek(to: Int(ms-expLocalTs))
                        
                        currentTime = (Double(ms-expLocalTs) / 1000.0)
                        totalTime =  Double(model.Duration) / 1000.0
                        
                    }
                    
                }
            }else if type == .check_ts_resp {
                
                if self.isPlayerPause == true {return}
                
                guard let model = AgoraDataStreamMessageParser.decodeMessage(payload, type: CheckResp.self) else {return}
                
                if model.remoteUid != localUser.media?.streamId {return}
                
                delay = (ms-model.remoteTS)/2

                delayWithBrod = model.broadTs + delay - ms
                if needSeek && state == AgoraMediaPlayerState.playing || state == .paused{
                    let expLocalTs = model.broadTs - model.position - delayWithBrod
                    let localPosition:CLongLong = CLongLong((self.core.engine.getPosition()))
                    if abs(ms-localPosition-expLocalTs) > 40 {
                        let expSeek = ms - expLocalTs + seekTime
                        lastExpectLocalPosition = expSeek
                        lastSeekTime = ms
                        
                        if state == .paused {
                            self.core.engine.play()
                            self.lrcScoreView.start()
                        }
                        
                        
                        let errTime = abs(Int(ms-localPosition-expLocalTs))
                        print("player log2: \(errTime) delay: \(delay)")
                        if errTime > 40 {
                           // print("player log2: \(errTime) delay: \(delay)")
                            var expSeek = ms-expLocalTs
                            expSeek += seekTime
                            needSeek = true
                        }
                        
                        _ = self.core.engine.seek(to: Int(expSeek))
                        
                        currentTime = (Double(expSeek) / 1000.0)
                    }
                }
                
            }
            
        }else {//观众
            if type == .play_status || type == .pause_status {
                
                guard let model: MusicState = AgoraDataStreamMessageParser.decodeMessage(payload, type: MusicState.self) else {return}
                
                guard let music = self.musicPresenter.musicWithID(identifer: model.bgmId) else {
                    return
                }
                
                if type == .pause_status {
                    if lrcScoreView.isStart {
                        lrcScoreView.stop()
                    }
                }
                
                changeBgm(with: music)
                
                if !lrcScoreView.isStart && model.position != 0 && type != .pause_status{
                    lrcScoreView.start()
                }

                currentTime = (CGFloat(model.position) / 1000.0)
                totalTime = (CGFloat(model.Duration) / 1000.0)
                
                if type == .pause_status {
                    lrcScoreView.scrollToTime(timestamp: currentTime)
                }
            }
        }
    }
    
    func startPlayMusic(duration: CLongLong) {
        self.core.engine.play()
        self.lrcScoreView.start()
        self.lrcScoreView.scrollToTop()
        self.currentTime = 0
        self.totalTime =  Double(duration) / 1000.0
    }
    
    func didMPKChangedToPosition(position: Int) {
        
    }
    
    func didMPKChangedTo(state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            
            DispatchQueue.global().async{[weak self] in
                self?.currentTime = 0
                self?.totalTime = Double((self?.core.engine.getDuration())!) / 1000.0
            }
            
            
        } else if state == .playBackCompleted {
            
            self.core.engine.pause()

            DispatchQueue.main.async { [weak self] in
                self?.currentTime = 0
                self?.lrcScoreView.stop()
                self?.lrcScoreView.resetTime()
                self?.lrcScoreView.scrollToTop()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.core.engine.pause()
            }
            
            if self.localUser.role != .owner {return}
            self.isPlayComplete = true
            self.isPlayerPause = true
            
            DispatchQueue.main.async {[weak self] in
                self?.musicStateBtn.isSelected = !(self?.musicStateBtn.isSelected)!
            }

        }
    }
 
}

//MARK: - AgoraLrcViewDelegate, AgoraLrcDownloadDelegate
extension AgoraChorusPlayerViewController: AgoraLrcViewDelegate, AgoraLrcDownloadDelegate {
    func getPlayerCurrentTime() -> TimeInterval {
        
        if localUser.role == .audience {
            return currentTime
        } else {
            
            if self.core.engine.getPosition() < 0 {return 0}
            currentTime = Double(self.core.engine.getPosition()) / 1000.0
            return currentTime
        }
        
    }
    
    func getTotalTime() -> TimeInterval {
        return totalTime
    }
    
    func seekToTime(time: TimeInterval) {
        currentTime = time
        let ts: CLongLong = CLongLong(time * 1000.0)
        self.core.engine.seek(to: Int(ts))
        
        sendPlayStatus(position: ts)
    }
    
    func downloadLrcFinished(url: String) {
        //歌词下载完毕，可以播放了
        
    }
    
}

private extension AgoraChorusPlayerViewController {
    func createViews() {
        imageView = UIImageView(image: UIImage.rmc_named("img_chorus_lyrics_bg"))
        imageView.contentMode = .scaleAspectFill
        imageView.cornerRadius = 4
        imageView.clipsToBounds = true
        self.view.addSubview(imageView)
        
        musicLabel = UILabel()
        musicLabel.text = ""
        musicLabel.textColor = .white
        musicLabel.font = UIFont.systemFont(ofSize: 15)
        musicLabel.backgroundColor = .clear
        view.addSubview(musicLabel)
        
        changeBtn = UIButton()
        changeBtn.setImage(UIImage.rmc_named("换歌"), for: .normal)
        changeBtn.setTitle("切歌", for: .normal)
        changeBtn.setupButtonImageAndTitlePossitionWith(padding: 3)
        changeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        changeBtn.addTarget(self, action: #selector(changeMusic), for: .touchUpInside)
        changeBtn.titleLabel?.textColor = .white
        view.addSubview(changeBtn)
        changeBtn.isHidden = true
        
        lrcScoreView.translatesAutoresizingMaskIntoConstraints = false
        lrcScoreView.cornerRadius = 4
        lrcScoreView.clipsToBounds = true
        lrcScoreView.downloadDelegate = self
        view.addSubview(lrcScoreView)
        
        musicStateBtn = UIButton()
        musicStateBtn.setImage(UIImage.rmc_named("暂停"), for: .selected)
        musicStateBtn.setImage(UIImage.rmc_named("开始"), for: .normal)
        musicStateBtn.setTitle("", for: .normal)
        musicStateBtn.setupButtonImageAndTitlePossitionWith(padding: 6)
        musicStateBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        musicStateBtn.addTarget(self, action: #selector(playMusic(btn:)), for: .touchUpInside)
        musicStateBtn.titleLabel?.textColor = .white
        view.addSubview(musicStateBtn)
        musicStateBtn.isHidden = true
        
        mixerBtn = UIButton()
        mixerBtn.setImage(UIImage.rmc_named("调音台"), for: .normal)
        mixerBtn.setTitle("调音台", for: .normal)
        mixerBtn.setupButtonImageAndTitlePossitionWith(padding: 3)
        mixerBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        mixerBtn.titleLabel?.textColor = .white
        mixerBtn.addTarget(self, action: #selector(mixChange), for: .touchUpInside)
        view.addSubview(mixerBtn)
        mixerBtn.isHidden = true
        
        effectBtn = UIButton()
        effectBtn.setImage(UIImage.rmc_named("音效"), for: .normal)
        effectBtn.setTitle("音效", for: .normal)
        effectBtn.setupButtonImageAndTitlePossitionWith(padding: 3)
        effectBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        effectBtn.titleLabel?.textColor = .white
        effectBtn.addTarget(self, action: #selector(changeEffect), for: .touchUpInside)
        view.addSubview(effectBtn)
        effectBtn.isHidden = true
    }
    
    @objc func playMusic(btn: UIButton) {
        btn.isSelected = !btn.isSelected
        self.isPlayerPause = !btn.isSelected
        
        var position: CLongLong = 0
        
        if self.isPlayComplete {
           
           lrcScoreView.scrollToTime(timestamp: currentTime)
            
            self.core.engine.seek(to: Int(currentTime * 1000.0))
            
            self.isPlayComplete = false
           
        }
        
        position = CLongLong(self.core.engine.getPosition())
        
        if !self.isPlayerPause {
            self.core.engine.play()
            lrcScoreView.start()
        } else {
            self.core.engine.pause()
            if lrcScoreView.isStart {
                lrcScoreView.stop()
            }
        }
        
        sendPlayStatus(position: position)
    }
    
    @objc func mixChange() {
        //调音台
        self.present(self.volumeController, animated: true, completion: nil)
    }
    
    @objc func changeMusic() {
        guard let musicList = self.musicList else {return}
        AgoraSoundsAlertController.showInViewController(self, list: musicList, selected: selectMusic) { music in
            if self.musicStateBtn.isHidden == true {
                self.musicStateBtn.isHidden = false
            }
            
            self.musicStateBtn.isSelected = false
            self.changeBgm(with: music)
            self.isPlayerPause = true
            self.sendPlayStatus(position: 0)
        }
    }
    
    @objc func changeEffect() {
        self.present(effectVC, animated: true, completion: nil)
    }
    
    func dataToDictionary(data:Data) ->Dictionary<String, Any>?{
        do{
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            let dic = json as! Dictionary<String, Any>
            return dic
        }catch _ {
            print("失败")
            return nil
        }
    }
    
    func createConstrains() {
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 10, left: 14, bottom: 14, right: 14))
        }
        
        musicLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(26)
            make.right.equalToSuperview().offset(-26)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(30)
        }
        
        changeBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(10)
            make.width.equalTo(60)
            make.height.equalTo(30)
        }
        
        lrcScoreView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 35, left: 14, bottom: 60, right: 14))
        }
        
        musicStateBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(26)
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(110)
            make.height.equalTo(30)
        }
        
        mixerBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(70)
            make.height.equalTo(30)
        }
        
        effectBtn.snp.makeConstraints { make in
            make.right.equalTo(mixerBtn.snp.left).offset(-20)
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(60)
            make.height.equalTo(30)
        }
        
    }
}

extension UIButton {
    
    func setupButtonImageAndTitlePossitionWith(padding: CGFloat){
        
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: padding / 2, bottom: 0, right: -padding / 2)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -padding / 2, bottom: 0, right: padding / 2)
        
    }
}

