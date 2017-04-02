//
//  DetailViewWithNavigationController.swift
//  burui
//
//  Created by R0uter on 2017/3/30.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit

class DetailViewWithNavigationController:UIViewController {
    var video:Video!
    var isPresented = false
    
    
    var currentVid = ""
    var isShouldPause = false
    
    lazy var videoPlayer:SkinVideoViewController = {
        let width = self.view.bounds.size.width
        let vp = SkinVideoViewController(frame: CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y, width: width, height: width*(9.0/16.0)))
        vp.configObserver()
        return vp
    }()
    
    override func viewDidDisappear(_ animated: Bool) {
       
        self.videoPlayer.cancel()
        NotificationCenter.default.removeObserver(self)
        super.viewDidDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.edgesForExtendedLayout = .init(rawValue: 0)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        // 播放指定 vid 的视频
        videoPlayer.vid = video.vid
        view.addSubview(videoPlayer.view)
        videoPlayer.parentViewController = self
        // 需要保留导航栏
        videoPlayer.keepNavigationBar = true
        videoPlayer.navigationController = self.navigationController
        
        // 设置附加组件
        videoPlayer.headTitle = video.title
        
//        videoPlayer.enableDanmuDisplay = false
//        videoPlayer.enableRateDisplay = false
//        videoPlayer.setLogo(image: UIImage!, location: Int32, size: <#T##CGSize#>, alpha: <#T##CGFloat#>)
        
//        videoPlayer.teaserEnable = true
        // 开启弹幕
        videoPlayer.danmuEnabled = true
        // 是否开启截图
        videoPlayer.enableSnapshot = true
        
//        videoPlayer.autoContinue = true
//        videoPlayer.shouldAutoplay = false
        /**
         *  ---- 回调代码块 ----
         */
        videoPlayer.playButtonClickBlock = {
            LogPrint("user click play button")
        }
        videoPlayer.pauseButtonClickBlock = {
            LogPrint("user click pause button")
        }
        videoPlayer.fullscreenBlock = {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            LogPrint("should hide toolbox in this viewcontroller if needed")
        }
        videoPlayer.shrinkscreenBlock = {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            LogPrint("show toolbox back if needed")
        }
        videoPlayer.dimissCompleteBlock = {
            LogPrint("!!!!!")
            self.navigationController?.popViewController(animated: true)
        }
        videoPlayer.watchCompletedBlock = {
            LogPrint("user watching completed")
        }
    }
    
}
