//
//  SkinVideoViewController.swift
//  polyv-ios-client-swift-demo
//
//  Created by R0uter on 2017/3/31.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit
enum panHandlerDirection:Int {
    case horizontal,vertical
}
let kPanPrecision:Double = 20
let USER_DICT_AUTOCONTINUE = "autoContinue"

class SkinVideoViewController:PLVMoviePlayerController {
    /// 播放器销毁回调
    var dimissCompleteBlock:()->() = {}
    /// 全屏回调
    var fullscreenBlock:()->() = {}
    /// 退出全屏回调
    var shrinkscreenBlock:()->() = {}
    /// 播放按钮点击回调
    var playButtonClickBlock:()->() = {}
    /// 暂停按钮点击回调
    var pauseButtonClickBlock:()->() = {}
    /// 观看结束回调
    var watchCompletedBlock:()->() = {}
    
    var frame:CGRect! {
        didSet {
            self.view.frame = frame
            self.videoControl.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            self.videoControl.setNeedsLayout()
            self.videoControl.layoutIfNeeded()
        }
    }
    var panHandler:panHandlerDirection?
    /// 开始播放时间
    var watchStartTime:TimeInterval = 0
    var autoContinue = false {        // 继续上一次的视频。如果设置为YES,视频将从上次播放停止的位置继续播放
        didSet {
            if autoContinue {
                var autoContinueDict:[String:Any] = UserDefaults.standard.dictionary(forKey: USER_DICT_AUTOCONTINUE) ?? [:]
                if let startTime = autoContinueDict[self.vid] as? Double {
                    if startTime > 0 {
                        self.watchStartTime = startTime
                    }
                }
            }
        }
    }
    var isWatchCompleted = false   // 播放是否完成
    
    /// 是否显示弹幕按钮，默认显示
    var enableDanmuDisplay = true {
        didSet {
            if enableDanmuDisplay {
                danmuEnabled = false
            }
        }
    }
    /// 是否显示播放速率按钮，默认显示
    var enableRateDisplay = true
    /// 问答开关，默认为关闭
    var enableExam = false {
        didSet {
            guard self.vid != nil && self.video.isInteractiveVideo else {
                return
            }
            if enableExam {// 开启问答
                videoExams = PolyvSettings.getVideoExams(self.vid)
                videoControl.pvExamView.resetExamHistory()//清空答题纪录，下次观看也会重新弹出问题
            }
        }
    }
    /// 截图开关，默认为关闭
    var enableSnapshot = false {
        didSet {
            videoControl.enableSnapshot = enableSnapshot
        }
    }
    fileprivate var volumeSlider:UISlider!
    /// 播放控制视图
    fileprivate (set) var videoControl:SkinVideoView!
    
    fileprivate (set) lazy var movieBackgroundView:UIView = {
       let v = UIView()
        v.alpha = 0.0
        v.backgroundColor = UIColor.black
        return v
    }()
    /// 当前播放时间
    var currentTime = 0.0
    
    
    var isFullscreenMode = false
    weak var parentViewController:UIViewController?
    weak var navigationController:UINavigationController? {
        didSet{
            if !keepNavigationBar {
                navigationController?.setNavigationBarHidden(true, animated: false)
            }
        }
    }
    /// 保留导航栏
    var keepNavigationBar = false {
        didSet{
            if keepNavigationBar {
                var frame = self.view.frame
                frame = CGRect(x: frame.origin.x, y: frame.origin.y - 20, width: frame.size.width, height: frame.size.height)
                self.view.frame = frame
                self.originFrame = frame
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.videoControl.backButton.isHidden = true
            }
        }
    }
    var isBitRateViewShowing = false
    var originFrame:CGRect!
    
    var durationTimer:Timer!
    var bufferTimer:Timer!
    /// 启用弹幕
    var danmuEnabled = false {
        didSet {
            let dmFrame = self.view.bounds
            self.danmuManager = PVDanmuManager(frame: dmFrame, withVid: self.vid, in: self.view, underView: self.videoControl, durationTime: 1)
            let color = danmuEnabled ? UIColor.yellow : UIColor.white
            self.videoControl.setDanmuButton(color:color)
        }
    }
    fileprivate var danmuManager:PVDanmuManager!
    fileprivate var danmuSendView:PvDanmuSendView?
    /// 设置播放器标题
    var headTitle = "" {
        didSet {
            self.videoControl.headTitle = headTitle
        }
    }
    var teaserURL = ""
    var videoContentURL:URL!
    var param1 = ""
    
    var startPoint:CGPoint!
    var curPosition:CGFloat!
    var curVoice:CGFloat!
    var curBrightness:CGFloat!
    
    var volumeEnable = true
    var timeLabel:String? {
        get {
            return self.videoControl.timeLabel.text
        }
        set {
            self.videoControl.timeLabel.text = newValue
        }
    }
    var position = 0
    var isPrepared = false
    var stallTimer:Timer!
    var firstLoadStartTime:Date!
    var secondLoadStartTime:Date!
    var firstLoadTimeSent = false
    var secondLoadTimeSent = false
    var isSeeking = false
    var isSwitching = false
    var watchTimer:Timer!
    
    var videoExams:NSMutableArray?
    var parsedSrt:NSDictionary?
    
    
    
    deinit {
        LogPrint("deinit!")
    }
    override init!(contentURL url: URL!) {
        super.init(contentURL: url)
    }
    init(frame:CGRect, vid:String = "sl8da4jjbxe69c6942a7a737819660de_s", level:PvLevel = .auto) {
        super.init(vid: vid, level: level)
//        super.init()
//        super.init
        let f = CGRect(x:frame.origin.x , y: frame.origin.y+20, width: frame.size.width, height: frame.size.height)
        videoControl = SkinVideoView(frame:f)
        videoControl.backgroundColor = UIColor.clear
        self.backgroundView?.backgroundColor = UIColor.clear
        let volumeView = MPVolumeView()
        volumeView.showsRouteButton = false
        volumeView.showsVolumeSlider = true
        volumeView.sizeToFit()
        volumeView.frame = CGRect(x: -1000, y: -1000, width: 10, height: 10)
        videoControl.translatesAutoresizingMaskIntoConstraints = true
        videoControl.addSubview(volumeView)
        //        volumeView.userActivity
        for view in volumeView.subviews {
            if let slider = view as? UISlider {
                self.volumeSlider = slider
                break
            }
        }
        
        self.frame = f
        self.originFrame = frame
        self.view.addSubview(videoControl)
        
        self.view.backgroundColor = UIColor.black
        self.controlStyle = .none
        self.videoControl.closeButton.isHidden = true
        self.videoControl.indicatorView.stopAnimating()
        self.enableDanmuDisplay = true
        self.enableRateDisplay = true
        self.configControlAction()
    }
    override func play() {
        self.videoControl.indicatorView.startAnimating()
        super.play()
    }
}
let pPlayerAnimationTimeinterval = 0.3
//MARK: - 外部方法
extension SkinVideoViewController {
    /// 窗口模式
    func showInWindow() {
        var keyWindow = UIApplication.shared.keyWindow
        if keyWindow == nil {
           keyWindow = UIApplication.shared.windows.first!
        }
        keyWindow?.addSubview(self.view)
        
        view.alpha = 0
        videoControl.closeButton.isHidden = false
        videoControl.showInWindowMode = true
        videoControl.backButton.isHidden = true
        UIView.animate(withDuration: pPlayerAnimationTimeinterval) { 
            self.view.alpha = 1
        }
        
    }
    /// 设置播放器logo
    func setLogo(image:UIImage, location:PvLogoLocation, size:CGSize, alpha:CGFloat) {
        videoControl.logoImage = image
        videoControl.logoPosition = location
        videoControl.logoSize = size
        videoControl.logoAlpha = alpha
//        videoControl.logoImageView
    }
    /// 注册监听
    func configObserver () {
        super.delegate = self
        let notificationCenter = NotificationCenter.default
        // 播放状态改变，可配合playbakcState属性获取具体状态
        notificationCenter.addObserver(self, selector: #selector(onMPMoviePlayerPlaybackStateDidChangeNotification), name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        // 媒体网络加载状态改变
        notificationCenter.addObserver(self, selector: #selector(onMPMoviePlayerLoadStateDidChangeNotification), name: NSNotification.Name.MPMoviePlayerLoadStateDidChange, object: nil)
        // 视频显示就绪
        notificationCenter.addObserver(self, selector: #selector(onMPMoviePlayerReadyForDisplayDidChangeNotification), name: NSNotification.Name.MPMoviePlayerReadyForDisplayDidChange, object: nil)
        // 播放时长可用
        notificationCenter.addObserver(self, selector: #selector(onMPMovieDurationAvailableNotification), name: NSNotification.Name.MPMovieDurationAvailable, object: nil)
        // 媒体播放完成或用户手动退出, 具体原因通过MPMoviePlayerPlaybackDidFinishReasonUserInfoKey key值确定
        notificationCenter.addObserver(self, selector: #selector(onMPMoviePlayerPlaybackDidFinishNotification(_:)), name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish, object: nil)
        // 视频就绪状态改变
        notificationCenter.addObserver(self, selector: #selector(onMediaPlaybackIsPrearedToPlayDidChangeNotification), name: NSNotification.Name.MPMediaPlaybackIsPreparedToPlayDidChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(onMPMoviePlayerNowPlayingMovieDidChangeNotification), name: NSNotification.Name.MPMoviePlayerNowPlayingMovieDidChange, object: nil)
        self.addOrientationObserver()
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panHandler(_:)))
        pan.delegate = self
        self.view.addGestureRecognizer(pan)
    }
    /// 移除监听
    func cancelObserver() {
        NotificationCenter.default.removeObserver(self)
        removeOrientationObserver()
    }
    /// 销毁
    override func cancel() {
        super.cancel()
        self.cancelObserver()
        self.stopBufferTimer()
        self.stopDurationTimer()
        self.stallTimer?.invalidate()
    }
    /// 销毁，在导航控制器中不会执行
    func dismiss() {
        self.stopDurationTimer()
        self.stopBufferTimer()
        UIView.animate(withDuration: pPlayerAnimationTimeinterval, animations: { 
            self.view.alpha = 0
        }) { (_) in
            self.view.removeFromSuperview()
            // 回调结束闭包
            self.dimissCompleteBlock()
        }
      self.watchTimer.invalidate()
        UIApplication.shared.setStatusBarHidden(false, with: .fade)
    }
    func roll(info:String, withDuration:TimeInterval, color:UIColor!, font:UIFont = UIFont.systemFont(ofSize: 13) ) {
        let width = self.frame.size.width
        let infoLabel = UILabel(frame: CGRect(x: width, y: 0, width: 0, height: 0 ))
        if let c = color {
            infoLabel.textColor = c
        }
        infoLabel.font = font
        infoLabel.text = info
        self.view.addSubview(infoLabel)
        infoLabel.sizeToFit()
        UIView.animate(withDuration: duration, delay: 0, options:.curveLinear, animations: {
            infoLabel.transform = CGAffineTransform(translationX: -width-infoLabel.bounds.size.width, y: 0)
        }) { (_) in
            infoLabel.removeFromSuperview()
        }
    }
    
}

// MARK: - 按钮事件
extension SkinVideoViewController {
    /// 配置按钮事件
    func configControlAction() {
        self.videoControl.playButton.addTarget(self, action: #selector(playButtonClick), for: .touchUpInside)
        self.videoControl.backButton.addTarget(self, action: #selector(backButtonAction), for: .touchUpInside)
        self.videoControl.pauseButton.addTarget(self, action: #selector(pauseButtonClick), for: .touchUpInside)
        self.videoControl.closeButton.addTarget(self, action: #selector(closeButtonClick), for: .touchUpInside)
        self.videoControl.danmuButton.addTarget(self, action: #selector(danmuButtonClick), for: .touchUpInside)
        self.videoControl.rateButton.addTarget(self, action: #selector(rateButtonClick(_:)), for: .touchUpInside)
        self.videoControl.sendDanmuButton.addTarget(self, action: #selector(sendDanmuButtonClick), for: .touchUpInside)
        self.videoControl.fullScreenButton.addTarget(self, action: #selector(fullScreenAction(_:)), for: .touchUpInside)
        self.videoControl.bitRateButton.addTarget(self, action: #selector(bitRateButtonClick), for: .touchUpInside)
        self.videoControl.shrinkScreenButton.addTarget(self, action: #selector(fullScreenAction(_:)), for: .touchUpInside)
        self.videoControl.slider.addTarget(self, action: #selector(progressSliderValueChanged(_:)), for: .valueChanged)
        self.videoControl.slider.addTarget(self, action: #selector(progressSliderValueChanged(_:)), for: .touchDragInside)
        self.videoControl.slider.addTarget(self, action: #selector(progressSliderTouchBegan(_:)), for: .touchDown)
        self.videoControl.slider.addTarget(self, action: #selector(progressSliderTouchEnded(_:)), for: .touchUpInside)
        self.videoControl.slider.addTarget(self, action: #selector(progressSliderTouchEnded(_:)), for: .touchUpOutside)
        self.videoControl.slider.addTarget(self, action: #selector(progressSliderTouchEnded(_:)), for: .touchCancel)
        self.videoControl.snapshotButton.addTarget(self, action: #selector(snapshot), for: .touchUpInside)
        self.setProgressSliderMaxMinValues()
        self.monitorVideoPlayback()
    }
    
    func bitRateViewClick(_ button:UIButton) {
        self.watchStartTime = super.currentPlaybackTime
        self.isSwitching = true
        self.videoControl.bitRateView.isHidden = true
        let list = ["自动","流畅","高清","超清"]
        guard button.tag < list.count else {return}
        super.switch(PvLevel(rawValue: Int32(button.tag))!)
        self.videoControl.bitRateButton.setTitle(list[button.tag], for: .normal)
        
    }
    func playButtonClick() {
        self.playButtonClickBlock()
        self.play()
        self.videoControl.playButton.isHidden = true
        self.videoControl.pauseButton.isHidden = false
    }
    func pauseButtonClick() {
        self.pauseButtonClickBlock()
        self.pause()
        self.videoControl.playButton.isHidden = false
        self.videoControl.pauseButton.isHidden = true
    }
    func sendDanmuButtonClick() {
        if let _ = self.danmuSendView {
            self.danmuSendView = nil
        }
        self.danmuSendView = PvDanmuSendView(frame: self.view.bounds)
        self.view.addSubview(self.danmuSendView!)
        self.danmuSendView?.deleagte = self
        self.danmuSendView?.showAction(self.view)
        super.pause()
        self.danmuManager.pause()
    }
    func danmuButtonClick() {
        if self.danmuEnabled {
            self.danmuEnabled = false
            self.videoControl.sendDanmuButton.isHidden = true
        } else {
            self.danmuEnabled = true
            self.videoControl.sendDanmuButton.isHidden = false
        }
    }
    func rateButtonClick(_ sender:UIButton) {
        sender.layer.borderColor = UIColor.red.cgColor
        sender.setTitleColor(UIColor.red, for: .normal)
        let title = sender.title(for: .normal)!
        switch title {
        case "1.25X":
            sender.setTitle("1.5X", for: .normal)
            self.currentPlaybackRate = 1.5
        case "1.5X":
            sender.setTitle("2X", for: .normal)
            self.currentPlaybackRate = 2.0
        case "2X":
            sender.setTitle("1X", for: .normal)
            self.currentPlaybackRate = 1.0
        default:
            sender.setTitle("1.25X", for: .normal)
            self.currentPlaybackRate = 1.25
        }
    }
    func closeButtonClick() {
        self.dismiss()
    }
    func bitRateButtonClick() {
        if !self.isBitRateViewShowing {
            self.videoControl.bitRateView.isHidden = false
            self.videoControl.animateHide()
            self.isBitRateViewShowing = true
        } else {
            self.videoControl.bitRateView.isHidden = true
            self.isBitRateViewShowing = false
        }
    }
    func setProgressSliderMaxMinValues() {
        let duration = CGFloat(self.duration)
        self.videoControl.slider.progressMinimumValue = 0.0
        self.videoControl.slider.progressMaximumValue = duration
    }
    func progressSliderTouchBegan(_ slider:UISlider) {
        self.pause()
        self.videoControl.cancelAutoFadeOutControlBar()
    }
    func progressSliderValueChanged(_ slider:UISlider) {
        self.isSeeking = true
        let currentTime = floor(slider.value)
        let totalTime = floor(self.duration)
        self.timeLabel = self.getTimeLabelString(withCurrentTime: Double(currentTime), totalTime: totalTime)
    }
    func progressSliderTouchEnded(_ slider:UISlider) {
        self.videoControl.autoFadeOutControlBar()
        self.currentPlaybackTime = floor(Double(slider.value))
        self.play()
        self.isSeeking = false
    }
}
// MARK: - 内部方法
extension SkinVideoViewController {
    
}

extension SkinVideoViewController {
    // MARK:   播放器通知响应
    func onMPMoviePlayerNowPlayingMovieDidChangeNotification() {
        // 显示码率
        self.setBitRateButton(titleLevel: Int(self.currentLevel().rawValue))
        // 本地视频不允许切换码率
        self.videoControl.bitRateButton.isEnabled = self.isExistedTheLocalVideo(self.vid) == 0
    }
    // 视频显示信息改变
    func onMPMoviePlayerReadyForDisplayDidChangeNotification() {
        
    }
    // 播放状态改变
    func onMPMoviePlayerPlaybackStateDidChangeNotification() {
        self.syncPlayButtonState()
        if self.playbackState == .playing {
            self.videoControl.indicatorView.stopAnimating()
            self.startDurationTimer()
            self.startBufferTimer()
            self.videoControl.autoFadeOutControlBar()
        } else {
            self.stopDurationTimer()
            if self.playbackState == .stopped {
                self.videoControl.animateShow()
            }
        }
    }
    // FIXME: 网络加载状态改变
    func onMPMoviePlayerLoadStateDidChangeNotification() {
        self.syncPlayButtonState()
        
        if loadState == .stalled {
            videoControl.indicatorView.startAnimating()
        }
        if loadState == .playthroughOK {
            videoControl.indicatorView.stopAnimating()
            isPrepared = true
        } else {
            
        }
        if loadState == .playable {
            
        }
        
//        if (self.loadState.rawValue & MPMovieLoadState.stalled.rawValue) == 1 {
//            self.videoControl.indicatorView.startAnimating()
//        }
//        if self.loadState.rawValue & MPMovieLoadState.playthroughOK.rawValue
    }
    // 做好播放准备后
    func onMediaPlaybackIsPrearedToPlayDidChangeNotification() {
        if self.watchStartTime > 0 && self.watchStartTime < self.duration {
            self.currentPlaybackTime = self.watchStartTime
            self.timeLabel = self.getTimeLabelString(withCurrentTime: self.watchStartTime, totalTime: self.duration)
            self.watchStartTime = -1
            self.isSwitching = false
        }
    }
    // 播放完成或退出
    func onMPMoviePlayerPlaybackDidFinishNotification(_ notification:Notification) {
        self.videoControl.indicatorView.stopAnimating()
        
        if self.autoContinue {
            var autoContinueDict:[String:Any] = UserDefaults.standard.dictionary(forKey: USER_DICT_AUTOCONTINUE) ?? [:]
            autoContinueDict[self.vid] = self.currentTime
            UserDefaults.standard.set(autoContinueDict, forKey: USER_DICT_AUTOCONTINUE)
            UserDefaults.standard.synchronize()
        }
        let notificationUserInfo = notification.userInfo
        let resultValue = notificationUserInfo?[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey]
        
        if fabs(self.duration - self.currentPlaybackTime) < 1 {
            self.videoControl.slider.progressValue = CGFloat(self.duration)
            let total = floor(self.duration)
            self.timeLabel = self.getTimeLabelString(withCurrentTime: total, totalTime: total)
            self.isWatchCompleted = true
            
            // 播放结束清除续播记录
            var autoContinueDict:[String:Any] = UserDefaults.standard.dictionary(forKey: USER_DICT_AUTOCONTINUE) ?? [:]
            if autoContinueDict.count > 0 && !self.vid.isEmpty {
                autoContinueDict.removeValue(forKey: self.vid)
                UserDefaults.standard.set(autoContinueDict, forKey: USER_DICT_AUTOCONTINUE)
                UserDefaults.standard.synchronize()
            }
            self.watchCompletedBlock()
        }
        if let reason = resultValue as? MPMovieFinishReason {
            if reason == .playbackError {
                let mediaPlayerError = notificationUserInfo?["error"]
                
                var errorString = ""
                if let e = mediaPlayerError as? Error {
                    errorString = "\(e.localizedDescription)"
                } else {
                    errorString = "playback failed without any given reason"
                }
                PvReportManager.reportError(super.pid, uid: PolyvUserId, vid: self.vid, error: errorString, param1: self.param1, param2: "", param3: "", param4: "", param5: "polyv-ios-sdk")
            }
        }
        
    }
    func onMPMovieDurationAvailableNotification() {
        self.setProgressSliderMaxMinValues()
    }
    // MARK:   处理字幕
    func searchSubtitles() {
        if self.playbackState == .playing {
            let predicate = NSPredicate(format: "%K <= %f AND %K >= %f", "from", self.currentTime, "to", self.currentPlaybackTime)
            guard let values = parsedSrt?.allValues, values.count > 0 else {return}
            let search = (values as NSArray).filtered(using: predicate)
            guard search.count > 0,
                let result = search.first as? [String:String],
                let text = result["text"]
                else {
                    self.videoControl.subtitleLabel.text = ""
                    return
            }
            self.videoControl.subtitleLabel.text = text
        }
    }
    func parseSubRip () {
        self.parsedSrt = NSMutableDictionary()
        var val = ""
       
        guard let values = self.video.videoSrts?.values else {return}
        if values.count != 0 {val = values.first!}//暂时只选择第一条字幕
        if val.isEmpty {return}
        guard var s = try? String(contentsOf: URL(string: val)!, encoding: .utf8 ) else  {
            return
        }
        s = s.replacingOccurrences(of: "\n\r\n", with: "\n\n")
        s = s.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        return
        print(s)
        let scanner = Scanner(string: s)
        while !scanner.isAtEnd {
            autoreleasepool {
                var indexString:NSString?
                scanner.scanUpToCharacters(from: NSCharacterSet.newlines, into: &indexString)
                var startString:NSString?
                scanner.scanUpTo(" --> ", into: &startString)
                var aScanner = Scanner(string: startString! as String)
                
                var h = 0.0
                var m = 0.0
                var s = 0.0
                var c = 0.0
                
                aScanner.scanDouble(&h)
                aScanner.scanString(":", into: nil)
                aScanner.scanDouble(&m)
                aScanner.scanString(":", into: nil)
                aScanner.scanDouble(&s)
                aScanner.scanString(",", into: nil)
                aScanner.scanDouble(&c)
                let fromTime = (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
                
                scanner.scanString(" --> ", into: nil)
                
                var endString:NSString?
                scanner.scanUpToCharacters(from: .newlines, into: &endString)
                aScanner = Scanner(string: endString! as String)
                aScanner.scanDouble(&h)
                aScanner.scanString(":", into: nil)
                aScanner.scanDouble(&m)
                aScanner.scanString(":", into: nil)
                aScanner.scanDouble(&s)
                aScanner.scanString(",", into: nil)
                aScanner.scanDouble(&c)
                let endTime = (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
                
                var textString:NSString?
                scanner.scanString("\n\n", into: &textString)
                
                textString?.replacingOccurrences(of: "\r\n", with: " ")
                textString = textString?.trimmingCharacters(in: .whitespaces) as NSString?
                
                let dictionary = NSMutableDictionary()
                dictionary.setObject(fromTime, forKey: "from" as NSCopying)
                dictionary.setObject(endTime, forKey: "to" as NSCopying)
                dictionary.setObject(textString as Any, forKey: "text" as NSCopying)
                
                self.parsedSrt?.setValue(dictionary, forKey: indexString! as String)
            }
        }
    }
    
    /// MARK: - 截图并保存到相册
    func snapshot() {
        let currentTime = Int(self.currentPlaybackTime)
        var level = Int(self.getLevel())
        if level == 0 {
            level = Int(self.isExistedTheLocalVideo(self.vid))
        }
        let sign = String(format:"%@%d%dpolyvsnapshot", self.vid, level, currentTime)
        let urlStr = String(format:"http://go.polyv.net/snapshot/videoimage.php?vid=%@&level=%d&second=%d&sign=%@", self.vid, level, currentTime, PolyvUtil.md5HexDigest(sign))
        
        let url = URL(string: urlStr)!
        let task = URLSession.shared.downloadTask(with: url) { (location, response, e) in
            let destinationPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last!.appending(response!.suggestedFilename!)
            guard ((try? FileManager.default.moveItem(at:location! , to: URL(string:destinationPath)!)) != nil),
                let image = UIImage(contentsOfFile: destinationPath) else {return}
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        task.resume()
    }
    func image(_ image:UIImage!, didFinishSavingWithError error:Error!, contextInfo:(()->())!) {
        if error == nil {
            LogPrint("截图保存成功")
            self.videoControl.indicator.showMessage("截图保存成功")
        } else {
            LogPrint("截图保存失败")
            self.videoControl.indicator.showMessage("截图保存失败")
        }
    }
    func show(exam:PvExam) {
        self.videoControl.pvExamView.setExam(exam)
        self.videoControl.pvExamView.closedBlock = {
            [weak self] in
            self?.videoControl.pvExamView.isHidden = true
            if $0 != -1 {
                self?.currentPlaybackTime = TimeInterval($0)
            }
            self?.play()
        }
    }
    
    func getTimeLabelString(withCurrentTime:Double, totalTime:Double) -> String {
        let mElapsed = floor(withCurrentTime / 60.0)
        let sElapsed = fmod(withCurrentTime, 60.0)
        let timeElapsed = String(format:"%02.0f:%02.0f", mElapsed, sElapsed)
        let mRemaining = floor(totalTime / 60.0)
        let sRemaining = fmod(totalTime, 60.0)
        let timeRemaining = String(format:"%02.0f:%02.0f", mRemaining, sRemaining)
        
        return "\(timeElapsed)/\(timeRemaining)"
    }
    // MARK: - 定时器
    func startDurationTimer() {
        self.durationTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(monitorVideoPlayback), userInfo: nil, repeats: true)
        RunLoop.current.add(self.durationTimer, forMode: .defaultRunLoopMode)
    }
    func stopDurationTimer() {
        self.durationTimer?.invalidate()
    }
    func startBufferTimer() {
        // FIX: 确保在同一对象下只被创建一次，否则可能造成内存泄漏的问题(其他如startDurationTimer方法中可参考修改，介于可能影响其他代码的可能性先不做修改)
        if self.bufferTimer == nil {
            self.bufferTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(trackBuffer), userInfo: nil, repeats: true)
            RunLoop.current.add(self.bufferTimer, forMode: .defaultRunLoopMode)
        }
    }
    func stopBufferTimer() {
        self.bufferTimer?.invalidate()
    }
    // MARK: - 定时器事件
    func monitorVideoPlayback() {
//        if self.isseek {}
        if isSwitching {return}// 正在切换码率，return出去
        let currentTime = floor(self.currentPlaybackTime)
        let totalTime = floor(self.duration)
        self.timeLabel = self.getTimeLabelString(withCurrentTime: currentTime, totalTime: totalTime)
        self.videoControl.slider.progressValue = ceil(CGFloat(currentTime))
        
        self.searchSubtitles()
        if self.danmuEnabled {danmuManager.rollDanmu(currentTime)}
        let userDefaults = UserDefaults.standard
        
        if self.enableExam {
            var examShouldShow:PvExam?
            for exam in self.videoExams! as! [PvExam] {
                if Double(exam.seconds) < currentTime && !(userDefaults.string(forKey: "exam_\(exam.examId)") == "Y") {
                    examShouldShow = exam
                    break
                }
            }
            if let e = examShouldShow {
                self.pause()
                self.show(exam: e)
            }
        }
        
    }
    func trackBuffer() {
        let buffer = CGFloat(self.playableDuration/self.duration)
        if !buffer.isNaN {
            self.videoControl.slider.loadValue = buffer
        }
    }
    func fadeDismissControl() {
        self.videoControl.animateHide()
    }
}

// MARK: - PLVMoviePlayerDelegate
extension SkinVideoViewController:PLVMoviePlayerDelegate {
    func moviePlayer(_ player: PLVMoviePlayerController!, didLoadVideoInfo video: PvVideo!) {
        // 码率列表
        let buttons = self.videoControl.createBitRateButton(Int(super.getLevel())) 
        for button in buttons {
            button.addTarget(self, action: #selector(bitRateViewClick(_:)), for: .touchUpInside)
        }
        
        // 问答
//        self.enableExam = self.enableExam

        
        // 字幕
        self.parseSubRip()
    }
    func moviePlayerTeaserDidBegin(_ player: PLVMoviePlayerController!) {
        self.videoControl.isHidden = true
    }
    func moviePlayerTeaserDidEnd(_ player: PLVMoviePlayerController!) {
        self.videoControl.isHidden = false
    }
    func setBitRateButton (titleLevel:Int) {
        let list = ["自动","流畅","高清","超清"]
        guard titleLevel < list.count else {return}
        self.videoControl.bitRateButton.setTitle(list[titleLevel], for: .normal)
    }
    func syncPlayButtonState () {
        if self.loadState == .playable && self.playbackState == .playing {
            self.videoControl.playButton.isHidden = true
            self.videoControl.pauseButton.isHidden = false
        } else {
            self.videoControl.playButton.isHidden = false
            self.videoControl.pauseButton.isHidden = true
        }
    }
}

// MARK: - QHDanmuSendViewDelegate
extension SkinVideoViewController:PvDanmuSendViewDelegate {
    func timeFormatted(totalSeconds:Int) ->String {
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds/60) % 60
        let hours = totalSeconds / 3600
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func sendDanmu(_ danmuSendV: PvDanmuSendView!, info: String!) {
        let currentTime = super.currentPlaybackTime
        self.danmuManager.sendDanmu(self.vid, msg: info, time: self.timeFormatted(totalSeconds: Int(currentTime)), fontSize: "24", fontMode: "roll", fontColor: "0xFFFFFF")
        super.play()
        self.danmuManager.insertDanmu(["c":info, "t":"1", "m":"l","color":"0xFFFFFF","f":"1"])
        self.danmuManager.resume(currentTime)
    }
    func closeSendDanmu(_ danmuSendV: PvDanmuSendView!) {
        super.play()
        self.danmuManager.resume(super.currentPlaybackTime)
    }
    
}
extension SkinVideoViewController:RotateFullScreen {
    /// 旋转按钮事件
    func fullScreenAction(_ sender: UIButton) {
        let orientation = UIDevice.current.orientation
        let interfaceOrientation = UIInterfaceOrientation(rawValue: orientation.rawValue)!
        
        switch(interfaceOrientation) {
        case .portraitUpsideDown, .landscapeLeft, .landscapeRight://电池栏在下,左,右
            changeInterface(toOrientation: .portrait)
        case .portrait://电池栏在上
            changeInterface(toOrientation: .landscapeRight)
        default:
            changeInterface(toOrientation: .landscapeRight)
            
        }
    }
    /// 强制转屏
    func changeInterface(toOrientation:UIInterfaceOrientation) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.blockRotation = toOrientation != .portrait
        let value = toOrientation.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    /// 返回按钮事件
    func backButtonAction() {
        if self.isFullscreenMode { // 全屏模式
            self.fullScreenAction(self.videoControl.shrinkScreenButton)
        } else {
            self.cancel()
            if let n = self.navigationController {
                n.popViewController(animated: true)
                n.setNavigationBarHidden(false, animated: true)
            } else {
                self.parentViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
            }
            
        }
    }
    func addOrientationObserver() {
        let device = UIDevice.current
        device.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orientitionChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: device)
    }
    func removeOrientationObserver() {
        let device = UIDevice.current
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: device)
    }
    
    func orientitionChanged(_ notification:Notification) {
        let orientation = UIDevice.current.orientation
        if orientation == .portrait && self.isFullscreenMode {
            self.shrinkScreenStyle()
        } else if (orientation == .landscapeRight || orientation == .landscapeLeft) && !self.isFullscreenMode {
            self.fullScreenStyle()
        } else if !self.isFullscreenMode {
            
        }
    }
    /// 全屏样式
    func fullScreenStyle() {
        if self.videoControl.showInWindowMode {
            UIApplication.shared.isStatusBarHidden = true
            let orientation = UIDevice.current.orientation
            let height = UIScreen.main.bounds.size.width
            let width = UIScreen.main.bounds.size.height
            let frame = CGRect(x: (height-width)/2, y: (width-height)/2, width: width, height: height)
            
            UIView.animate(withDuration: pPlayerAnimationTimeinterval, animations: { 
                self.frame = frame
                if orientation == .landscapeLeft {
                    self.view.transform = CGAffineTransform.identity
                    self.view.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi/2))
                } else if orientation == .landscapeRight {
                    self.view.transform = CGAffineTransform.identity
                    self.view.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
                }
            },completion:{ _ in
                self.isFullscreenMode = true
                self.videoControl.fullScreenButton.isHidden = true
                self.videoControl.shrinkScreenButton.isHidden = false
            })
        }else { // 视图模式
            let frame = UIScreen.main.bounds
            self.frame = frame
            self.isFullscreenMode = true
            self.videoControl.changeToFullscreen()
            if keepNavigationBar {
                navigationController?.setToolbarHidden(true, animated: true)
                self.videoControl.backButton.isHidden = false
            }
            self.videoControl.fullScreenButton.isHidden = true
            self.videoControl.shrinkScreenButton.isHidden = false
            
            if danmuEnabled {
                self.danmuManager?.resetDanmu(withFrame: self.view.frame)
                self.danmuManager?.initStart()
                self.videoControl.sendDanmuButton.isHidden = false
            }
            
            self.videoControl.danmuButton.isHidden = !self.enableDanmuDisplay
            self.videoControl.rateButton.isHidden = !self.enableRateDisplay
            
            
        }
        self.fullscreenBlock()
    }
    /// 非全屏样式
    func shrinkScreenStyle() {
        self.videoControl.snapshotButton.isHidden = true
        if self.videoControl.showInWindowMode {
            UIView.animate(withDuration: pPlayerAnimationTimeinterval, animations: { 
                self.view.transform = CGAffineTransform.identity
                self.frame = self.originFrame
                UIApplication.shared.isStatusBarHidden = false
            }, completion:{ _ in
                self.isFullscreenMode = false
                self.videoControl.fullScreenButton.isHidden = false
                self.videoControl.shrinkScreenButton.isHidden = true
            })
            
        } else {
            self.danmuSendView?.backAction()
            if self.keepNavigationBar {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.videoControl.backButton.isHidden = true
            } else {
                if let frame = parentViewController?.view.superview?.bounds {
                    self.parentViewController?.view.frame = frame
                }
                
            }
            
            self.frame = self.originFrame
            self.isFullscreenMode = false
            self.videoControl.changeToSmallscreen()
            self.videoControl.fullScreenButton.isHidden = false
            self.videoControl.shrinkScreenButton.isHidden = true
            self.danmuManager?.resetDanmu(withFrame: self.view.frame)
            self.danmuManager?.initStart()
            if self.danmuEnabled {
                self.videoControl.sendDanmuButton.isHidden = true
            }
        }
    }
}

// MARK: - 平移手势方法
extension SkinVideoViewController:Gesture {
    func panHandler(_ recognizer: UIPanGestureRecognizer) {
        let offset = recognizer.translation(in: recognizer.view)
        //根据在view上Pan的位置，确定是调音量还是亮度
        let locationPoint = recognizer.location(in: recognizer.view)
        // 判断是垂直移动还是水平移动
        switch(recognizer.state) {
        case .began:
            let x = fabs(offset.x)
            let y = fabs(offset.y)
            if x > y {// 水平移动
                self.pauseButtonClick()
                self.panHandler = .horizontal
            } else if x < y {// 垂直移动
                self.panHandler = .vertical
                if locationPoint.x > self.frame.size.width/2 {
                    self.volumeEnable = true
                } else {
                    self.volumeEnable = false
                }
            }
        case .changed:
            guard let handler = self.panHandler else  {break}
            switch (handler) {
            case .horizontal:
                self.horizontal(pan: offset.x)
            case .vertical:
                self.vertical(pan: offset.y)
            }
        case .ended:
            guard let handler = self.panHandler else  {break}
            switch handler {
            case .horizontal:
                self.currentTime = floor(self.getTime(withMove: offset.x))
                self.play()
            
            case .vertical:
            // 垂直移动结束后，把状态改为不再控制音量
            self.volumeEnable = false
            }
        default:break
        }
    }
    ///MARK: - pan垂直移动的方法
    func vertical(pan:CGFloat) {
        if self.volumeEnable {
            volumeSlider.value -= Float(pan) / 10000
        } else {
            UIScreen.main.brightness -= pan / 10000
        }
    }
    ///MARK: - pan水平移动的方法
    func getTime(withMove move:CGFloat) -> Double {
        let current = self.currentPlaybackTime
        let duration = self.duration
        let moveToValue = Double(move) / kPanPrecision + current
        if moveToValue >= duration {return duration}
        if moveToValue <= 0 {return 0}
        return moveToValue
    }
    func horizontal(pan:CGFloat) {
        let currentTime = floor(self.getTime(withMove: pan))
        let totalTime = floor(self.duration)
        self.timeLabel = getTimeLabelString(withCurrentTime: currentTime, totalTime: totalTime)
        let minutesElapsed = floor(currentTime / 60)
        let secondsElapsed = fmod(currentTime, 60)
        var timeElapsedString = String(format: "%02.0f:%02.0f", minutesElapsed,secondsElapsed)
        if currentTime <= 0 || currentTime >= totalTime {
            timeElapsedString = "到头啦！"
        }
        if pan < 0 {
            self.videoControl.indicator.forward(false, time: timeElapsedString)
        } else if pan > 0 {
            self.videoControl.indicator.forward(true, time: timeElapsedString)
        }
    }
    
}

// MARK: - UIGestureRecognizerDelegate
extension SkinVideoViewController:UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: self.view)
        return  !(point.y > self.frame.size.height-40)
    }
}
