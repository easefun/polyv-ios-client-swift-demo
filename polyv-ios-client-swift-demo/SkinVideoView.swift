//
// Created by R0uter on 2017/4/3.
// Copyright (c) 2017 R0uter. All rights reserved.
//

import UIKit
import MediaPlayer

let pVideoControlBarHeight:CGFloat = 50
let pVideoControlAnimationTimeInterval:TimeInterval = 0.5
let pVideoControlTimeLabelFontSize:CGFloat = 10
let pVideoControlTitleLabelFontSize:CGFloat = 16
let pVideoControlBarAutoFadeOutTimeInterval:TimeInterval = 5

enum PvLogoLocation:Int {
    case left = 0, right, bottomLeft, bottomRight
}


class SkinVideoView:UIView {
    lazy var topBar:UIView = {
        var v = UIView()
        v.backgroundColor = UIColor.clear
        return v
    }()/// 顶部工具栏
    lazy var bottomBar:UIView = {
        var v = UIView()
        v.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
        return v
    }()/// 底部工具栏
    lazy var bitRateView:UIView = {
        var v = UIView()
        v.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
        return v
    }()/// 码率列表
    lazy var playButton:UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "pl-video-player-play"), for: .normal)
        b.bounds = CGRect(x: 0, y: 0, width: pVideoControlBarHeight, height: pVideoControlBarHeight)
        return b
    }()/// 播放按钮
    lazy var pauseButton:UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "pl-video-player-pause"), for: .normal)
        b.bounds = CGRect(x: 0, y: 0, width: pVideoControlBarHeight, height: pVideoControlBarHeight)
        return b
    }()/// 暂停按钮
    lazy var backButton:UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "pl-video-player-back"), for: .normal)
        b.bounds = CGRect(x: 0, y: 0, width: pVideoControlBarHeight, height: pVideoControlBarHeight)
        b.alpha = 0.7
        return b
    }()/// 返回按钮
    lazy var fullScreenButton:UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "pl-video-player-fullscreen"), for: .normal)
        b.bounds = CGRect(x: 0, y: 0, width: pVideoControlBarHeight, height: pVideoControlBarHeight)
        return b
    }()/// 全屏按钮
    lazy var shrinkScreenButton:UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "pl-video-player-shrinkscreen"), for: .normal)
        b.bounds = CGRect(x: 0, y: 0, width: pVideoControlBarHeight, height: pVideoControlBarHeight)
        return b
    }()/// 小屏按钮
    lazy var bitRateButton:UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("自动", for: .normal)
        b.bounds = CGRect(x: 0, y: 0, width: pVideoControlBarHeight, height: pVideoControlBarHeight)
        return b
    }()/// 码率切换按钮
    lazy var danmuButton:UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("弹幕", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.layer.masksToBounds = true
        b.layer.cornerRadius = 3
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.white.cgColor
        b.bounds = CGRect(x: 0, y: 0, width: 50, height: 30)
        b.isHidden = true
        return b
    }()/// 弹幕开启按钮
    lazy var sendDanmuButton:UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "pl-video-player-danmu"), for: .normal)
        b.contentMode = .scaleAspectFit
        b.tintColor = UIColor.white
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
        return b
    }()/// 发送弹幕按钮
    lazy var slider:PLVSlider = {
        let s = PLVSlider(frame: CGRect(x: 10, y: 10, width: 10, height: 10))
        s.thumbImage = UIImage(named: "pl-video-player-point")
        return s
    }()/// 进度滑块
    lazy var  indicator:PLVIndicator = {
        let i = PLVIndicator(frame:  CGRect(x: 10, y: 10, width: 10, height: 10))
        i.alpha = 0
        return i
    }()/// 手势滑动指示器
    lazy var rateButton:UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("1X", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.layer.masksToBounds = true
        b.layer.cornerRadius = 3
        b.layer.borderWidth = 1
        b.bounds = CGRect(x: 0, y: 0, width: 50, height: 30)
        b.isHidden = true
        return b
    }()/// 变速按钮
    lazy var snapshotButton:UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "pl-video-player-snapshot"), for: .normal)
        b.contentMode = .scaleAspectFill
        b.bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
        b.isHidden = true
        return b
    }()/// 截图按钮

    lazy var pvExamView:PvExamView = {
        return PvExamView(frame: self.frame)
    }()/// 问答视图
    lazy var closeButton:UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UIImage(named: "pl-video-player-close"), for: .normal)
        b.bounds = CGRect(x: 0, y: 0, width: pVideoControlBarHeight, height: pVideoControlBarHeight)
        return b
    }()/// 关闭按钮
    var bitRateButtons:[UIButton] = []
    lazy var timeLabel:UILabel = {
        let t = UILabel()
        t.backgroundColor = UIColor.clear
        t.font = UIFont.systemFont(ofSize: pVideoControlTitleLabelFontSize)
        t.textAlignment = .right
        t.bounds = CGRect(x: 0, y: 0, width: pVideoControlTitleLabelFontSize, height: pVideoControlTitleLabelFontSize)
        return t
    }()/// 时间标签
    lazy var titleLabel:UILabel = {
        let t = UILabel()
        t.backgroundColor = UIColor.clear
        t.font = UIFont.systemFont(ofSize: pVideoControlTitleLabelFontSize)
        t.textColor = UIColor.white
        t.textAlignment = .left
        t.bounds = CGRect(x: 0, y: 0, width: pVideoControlTitleLabelFontSize, height: pVideoControlTitleLabelFontSize)
        t.isHidden = true
        return t
    }()
    lazy var subtitleLabel:UILabel = {
        let s = SubTitleLabel()
        s.backgroundColor = UIColor.clear
        s.font = UIFont.systemFont(ofSize: pVideoControlTitleLabelFontSize)
        s.textColor = UIColor.white
        s.numberOfLines = 0
        s.textAlignment = .center
        s.shadowColor = UIColor.black
        s.shadowOffset = CGSize(width: 0, height: 1)
        s.sizeToFit()
        return s
    }()/// 字幕

    var isBarShowing = false
    var currentBitRate = 0
    var hideControl = false {
        didSet {
            self.isBarShowing = false
            if hideControl {
                topBar.alpha = 0
                bottomBar.alpha = 0
                sendDanmuButton.alpha = 0
                snapshotButton.alpha = 0
            } else {
                topBar.alpha = 1
                bottomBar.alpha = 1
                sendDanmuButton.alpha = 1
                snapshotButton.alpha = 1
            }
        }
    }
    var enableSnapshot = false {
        didSet {
            snapshotButton.isHidden = true
            snapshotButton.alpha = 0
        }
    }/// 启用截图功能

    lazy var indicatorView:UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(activityIndicatorStyle: .white)
        v.hidesWhenStopped = true
        return v
    }()/// 缓冲菊花
    var isFullscreenMode = false
    var showInWindowMode = true/// 窗口模式

    var logoPosition:PvLogoLocation = .left
    var logoAlpha:CGFloat = 0
    var logoSize = CGSize(width: 0, height: 0)
    var logoImage:UIImage?
    lazy var logoImageView:UIImageView = {
        let l = UIImageView(image: self.logoImage)
        l.alpha = self.logoAlpha
        return l
    }()
    convenience init() {
            self.init(frame: CGRect())
    }
    override init (frame:CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = true

        addSubview(logoImageView)
        addSubview(subtitleLabel)
        addSubview(bitRateView)
        bitRateView.isHidden = true

        // 顶部工具栏
        addSubview(topBar)
        topBar.addSubview(titleLabel)
        topBar.addSubview(backButton)
        topBar.addSubview(danmuButton)
        topBar.addSubview(rateButton)
        topBar.addSubview(closeButton)

        addSubview(sendDanmuButton)
        sendDanmuButton.isHidden = true
        addSubview(indicator)
        // 底部工具栏
        addSubview(bottomBar)
        bottomBar.addSubview(playButton)
        bottomBar.addSubview(pauseButton)
        pauseButton.isHidden = true
        bottomBar.addSubview(bitRateButton)
        bottomBar.addSubview(fullScreenButton)
        bottomBar.addSubview(shrinkScreenButton)
        shrinkScreenButton.isHidden = true
        addSubview(slider)
        bottomBar.addSubview(timeLabel)

        addSubview(indicatorView)
        indicatorView.startAnimating()
        addSubview(snapshotButton)
        snapshotButton.isHidden = true
        snapshotButton.alpha = 0

        addSubview(pvExamView)
        pvExamView.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tapGesture)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func onTap(_ gesture:UITapGestureRecognizer) {
        bitRateView.isHidden = true
        if gesture.state == .recognized {
            if isBarShowing {
                self.animateHide()
            } else {
                self.animateShow()
            }
        }
    }
}
extension SkinVideoView {
    override func layoutSubviews() {
        super.layoutSubviews()
        topBar.frame = CGRect(x: bounds.minX, y: bounds.minY,
                              width: bounds.width, height: pVideoControlBarHeight)
        backButton.frame = CGRect(x: 0, y: topBar.bounds.minX,
                                  width: backButton.bounds.width, height: backButton.bounds.height)
        titleLabel.frame = CGRect(x: backButton.bounds.width, y: topBar.bounds.minX,
                                  width: 300, height: topBar.bounds.height)
        danmuButton.frame = CGRect(x: topBar.bounds.width - closeButton.bounds.width - danmuButton.bounds.width,
                                   y: (topBar.bounds.height - danmuButton.bounds.height)/2,
                                   width: danmuButton.bounds.width,height: danmuButton.bounds.height)
        rateButton.frame = CGRect(x: topBar.bounds.height-danmuButton.bounds.width*2 - rateButton.bounds.width-10,
                                  y: (topBar.bounds.height-rateButton.bounds.height)/2,
                                  width: rateButton.bounds.width, height: rateButton.bounds.height)
        sendDanmuButton.frame = CGRect(x: bounds.width - sendDanmuButton.bounds.width - 20,
                                       y: (bounds.height - sendDanmuButton.bounds.height)/2,
                                       width: sendDanmuButton.bounds.width, height: sendDanmuButton.bounds.height)
        snapshotButton.frame = CGRect(x: 20, y: (bounds.height - snapshotButton.bounds.height)/2,
                                      width: snapshotButton.bounds.width, height: snapshotButton.bounds.height)
        closeButton.frame = CGRect(x: topBar.bounds.width - closeButton.bounds.width,
                                   y: topBar.bounds.minX,
                                   width: closeButton.bounds.width, height: closeButton.bounds.height)
        bottomBar.frame = CGRect(x: bounds.minX, y: bounds.height - pVideoControlBarHeight,
                                 width: bounds.width, height: pVideoControlBarHeight)
        bitRateView.frame = CGRect(x: 2*bounds.width/3, y: bounds.minY, width: bounds.width/3, height: bounds.height)
        playButton.frame = CGRect(x: bottomBar.bounds.minX,
                                  y: bottomBar.bounds.height/2 - playButton.bounds.height/2,
                                  width: playButton.bounds.width, height: playButton.bounds.height)
        pauseButton.frame = playButton.frame
        bitRateButton.frame = CGRect(x: bottomBar.bounds.width - fullScreenButton.bounds.width - bitRateButton.bounds.width,
                                     y: bottomBar.bounds.height/2 - bitRateButton.bounds.height/2,
                                     width: bitRateButton.bounds.width, height: bitRateButton.bounds.height)
        fullScreenButton.frame = CGRect(x: bottomBar.bounds.width - fullScreenButton.bounds.width,
                                        y: bottomBar.bounds.height/2 - fullScreenButton.bounds.height/2,
                                        width: fullScreenButton.bounds.width,
                                        height: fullScreenButton.bounds.height)
        shrinkScreenButton.frame = fullScreenButton.frame
        
        slider.frame = CGRect(x: playButton.frame.maxX,
                              y: bottomBar.bounds.height/2 - slider.bounds.height/2,
                              width: bitRateButton.frame.minX - playButton.frame.maxX,
                              height: slider.bounds.height)
        subtitleLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        timeLabel.frame = CGRect(x: slider.frame.midX,
                                 y: bottomBar.bounds.height-1 - timeLabel.bounds.height - 2,
                                 width: slider.bounds.width/2,
                                 height: timeLabel.bounds.height)
        indicatorView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        indicator.center = CGPoint(x: center.x, y: center.y/2)
        
        switch logoPosition {
        case .left:
            logoImageView.frame = CGRect(x: 0, y: 0, width: logoSize.width, height: logoSize.height)
        case .right:
            logoImageView.frame = CGRect(x: frame.size.width-logoSize.width, y: 0, width: logoSize.width, height: logoSize.height)
        case .bottomLeft:
            logoImageView.frame = CGRect(x: 0, y: frame.size.height-logoSize.height, width: logoSize.width, height: logoSize.height)
        case .bottomRight:
            logoImageView.frame = CGRect(x: frame.size.width-logoSize.width, y: frame.size.height-logoSize.height, width: logoSize.width, height: logoSize.height)
        }
        pvExamView.frame = frame
        arrangeBitRateButtons()
        
    }
}
extension SkinVideoView {

    var headTitle:String? {
        get {
            return titleLabel.text
        }
        set {
            DispatchQueue.main.async {
                self.titleLabel.text = newValue
            }
        }
    }
}
extension SkinVideoView {
    
    /// 排列码率按钮
    func arrangeBitRateButtons() {
        let buttonWidth = 100
        let buttonSize = bitRateButtons.count * 30
        var initHeight = (Int(bitRateView.bounds.height) - buttonSize)/2
        for button in bitRateButtons {
            button.bounds = CGRect(x: 0, y: 0, width: pVideoControlBarHeight, height: 30)
            button.frame = CGRect(x: (Int(bitRateView.bounds.width)-buttonWidth)/2, y: initHeight, width: buttonWidth, height: 30)
            initHeight+=30
        }
    }
    func createBitRateButton(_ dfnum:Int) ->[UIButton]{
        guard dfnum <= 3 else {return []}
        for view in bitRateView.subviews {view.removeFromSuperview()}
        
        let list = ["自动","流畅","高清","超清"]
        for index in 0...dfnum {
            let button = UIButton(type: .custom)
            button.setTitle(list[index], for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            bitRateButtons.append(button)
            bitRateView.addSubview(button)
        }
        arrangeBitRateButtons()
        return bitRateButtons
    }
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        isBarShowing = true
    }
    func setDanmuButton(color:UIColor) {
        danmuButton.layer.borderColor = color.cgColor
        danmuButton.setTitleColor(color, for: .normal)
    }
    func animateHide() {
        guard isBarShowing else {return}
        UIView.animate(withDuration: pVideoControlAnimationTimeInterval, animations: { 
            self.topBar.alpha = 0
            self.bottomBar.alpha = 0
            self.snapshotButton.alpha = 0
        }) { (_) in
            self.isBarShowing = false
        }
    }
    func animateShow() {
        guard !hideControl,!isBarShowing else {return}
        UIView.animate(withDuration: pVideoControlAnimationTimeInterval, animations: { 
            self.topBar.alpha = 1
            self.bottomBar.alpha = 1
            if self.isFullscreenMode {
                self.sendDanmuButton.alpha = 1
                if self.enableSnapshot {self.snapshotButton.alpha = 1}
            }
        }) { (_) in
            self.isBarShowing = true
            self.autoFadeOutControlBar()
        }
    }
    func autoFadeOutControlBar() {
        guard isBarShowing else {return}
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(animateHide), object: nil)
        self.perform(#selector(animateHide), with: nil, afterDelay: pVideoControlBarAutoFadeOutTimeInterval)
    }
    func cancelAutoFadeOutControlBar() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(animateHide), object: nil)
    }
    func changeToFullscreen () {
        topBar.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
        titleLabel.isHidden = false
        danmuButton.isHidden = false
        sendDanmuButton.isHidden = false
        snapshotButton.isHidden = false
        isFullscreenMode = true
        rateButton.isHidden = false
        
    }
    func changeToSmallscreen() {
        topBar.backgroundColor = UIColor.clear
        titleLabel.isHidden = true
        danmuButton.isHidden = true
        isFullscreenMode = false
        sendDanmuButton.alpha = 0
        snapshotButton.alpha = 0
        rateButton.isHidden = true
    }
}
