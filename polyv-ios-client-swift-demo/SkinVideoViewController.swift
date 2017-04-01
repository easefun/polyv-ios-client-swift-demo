//
//  SkinVideoViewController.swift
//  polyv-ios-client-swift-demo
//
//  Created by R0uter on 2017/3/31.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit
enum panHandler:Int {
    case horizontal,vertical
}


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
    /// 开始播放时间
    var watchStartTime:TimeInterval
    var autoContinue = false         // 继续上一次的视频。如果设置为YES,视频将从上次播放停止的位置继续播放
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
    /// 播放控制视图
    fileprivate (set) lazy var videoControl:SkinVideoViewControllerView = {
        let v = SkinVideoViewControllerView()
        v.translatesAutoresizingMaskIntoConstraints = true
        return v
    }()
    fileprivate (set) lazy var movieBackgroundView:UIView = {
       let v = UIView()
        v.alpha = 0.0
        v.backgroundColor = UIColor.black
        return v
    }()
    /// 当前播放时间
    var currentTime = 0.0
    
    
    var isFullscreenMode = false
    var parentViewController:UIViewController?
    var navigationController:UINavigationController? {
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
                self.orifinFrame = frame
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.videoControl.backButton.isHidden = true
            }
        }
    }
    var isBitRateViewShowing = false
    var orifinFrame:CGRect!
    
    var durationTimer = 0
    var bufferTimer = 0
    /// 启用弹幕
    var danmuEnabled = true {
        didSet {
            let dmFrame = self.view.bounds
            self.danmuManager = PVDanmuManager(frame: dmFrame, withVid: self.vid, in: self.view, underView: self.videoControl, durationTime: 1)
            let color = danmuEnabled ? UIColor.yellow : UIColor.white
            self.videoControl.setDanmuButtonColor(color)
        }
    }
    fileprivate var danmuManager:PVDanmuManager!
    fileprivate var danmuSendView:PvDanmuSendView!
    /// 设置播放器标题
    var headTitle = "" {
        didSet {
            self.videoControl.setHeadTitle(headTitle)
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
    
    var videoExams:NSMutableArray!
//    var parsedSrt:[:]
    deinit {
        LogPrint("deinit!")
    }
    init(frame:CGRect, vid:String = "", level:PvLevel = .auto) {
        super.init(vid: vid, level: level)
        let f = CGRect(x:frame.origin.x , y: frame.origin.y+20, width: frame.size.width, height: frame.size.height)
        self.frame = f
        self.orifinFrame = frame
        self.view.addSubview(videoControl)
        self.videoControl.frame = self.view.bounds
        
        self.view.backgroundColor = UIColor.black
        self.controlStyle = .none
        self.videoControl.closeButton.isHidden = true
        self.videoControl.indicatorView.stopAnimating()
        self.enableDanmuDisplay = true
        self.enableRateDisplay = true
        self.configControlAction()
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
//        notificationCenter.
    }
    /// 移除监听
    func cancelObserver() {
        NotificationCenter.default.removeObserver(self)
        removeOrientationObserver()
    }
    
 
}

// MARK: - 存取器
extension SkinVideoViewController {
    
}

extension SkinVideoViewController:PLVMoviePlayerDelegate {
    
}

extension SkinVideoViewController:PvDanmuSendViewDelegate {
    
}
extension SkinVideoViewController:rotateFullScreen {
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
            self.videoControl.changeToFullsreen()
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
                self.frame = self.orifinFrame
                UIApplication.shared.isStatusBarHidden = false
            }, completion:{ _ in
                self.isFullscreenMode = false
                self.videoControl.fullScreenButton.isHidden = false
                self.videoControl.shrinkScreenButton.isHidden = true
            })
            
        } else {
            self.danmuSendView = backAction()
            if self.keepNavigationBar {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.videoControl.backButton.isHidden = true
            } else {
                if let frame = parentViewController?.view.superview?.bounds {
                    self.parentViewController?.view.frame = frame
                }
                
            }
            
            self.frame = self.orifinFrame
            self.isFullscreenMode = false
            self.videoControl.changeToSmallsreen()
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

