//
//  PolyvPlayerDemoViewController.swift
//  polyv-ios-client-swift-demo
//
//  Created by R0uter on 2017/3/30.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit

class PolyvPlayerDemoViewController:UIViewController {
    var downloader:PvUrlSessionDownload!
    @IBOutlet weak var plabel: UILabel!
    @IBOutlet weak var pbar: UIProgressView!
    var vid:String = "sl8da4jjbxc5565c46961a6f88ca52e5_s"
    var posterImageView:UIImageView!
    var videoPlayer:PLVMoviePlayerController!
    
 
    
    override func viewDidLoad() {
        // 配置下载器
        downloader = PvUrlSessionDownload(vid: vid, level: 1)
        // 自动选择码率
        videoPlayer = PLVMoviePlayerController(vid: vid)
        self.view.addSubview(videoPlayer.view)
        videoPlayer.view.frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y, width: view.frame.size.width, height: 240)
        // 设置播放器选项
        videoPlayer.shouldAutoplay = false
        
        // 设置播放器首图
        let imageURL = URL(string: "https://v.polyv.net/uc/video/getImage?vid="+vid)!
        DispatchQueue.global(qos: .background).async {
            var image = UIImage()
            if let data = try? Data(contentsOf: imageURL) {
                image = UIImage(data: data)!
            }
            
            
            DispatchQueue.main.async {
                let buttonImage = UIImage(named: "video-play.png")
                self.posterImageView = UIImageView(image: image)
                self.posterImageView.contentMode = .scaleAspectFit
                self.posterImageView.backgroundColor = UIColor.black
                self.posterImageView.isUserInteractionEnabled = true
                let iButton = UIImageView(image: buttonImage)
                iButton.frame = CGRect(x: self.posterImageView.frame.size.width/2 - 30, y: self.posterImageView.frame.size.height/2 - 30, width: 60, height: 60)
                self.posterImageView.addSubview(iButton)
                let playTap = UITapGestureRecognizer(target: self, action: #selector(self.playButtonTap))
                self.posterImageView.addGestureRecognizer(playTap)
                self.view.addSubview(self.posterImageView)
                
            }
        }
        
    }
    
    
    
    deinit {
        videoPlayer.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
}
// 按钮事件
extension PolyvPlayerDemoViewController {
    func playButtonTap() {
        if videoPlayer.playbackState != .playing && videoPlayer.playbackState != .paused {
            posterImageView.removeFromSuperview()
        }
        videoPlayer.play()
    }
    @IBAction func closeAction (_ sender:Any) {
        videoPlayer.stop()
        dismiss(animated: true, completion: nil)
    }
    @IBAction func seekAction (_ sender:Any) {
        videoPlayer.currentPlaybackTime = 30
    }
    @IBAction func playAction (_ sender:Any) {
        self.playButtonTap()
    }
    @IBAction func pauseAction(_ sender:Any) {
        videoPlayer.pause()
    }
    @IBAction func fullscreenAction (_ sender:Any) {
        videoPlayer.setFullscreen(true, animated: true)
    }
    @IBAction func switchVid(_ sender:Any) {
        videoPlayer.vid = "sl8da4jjbxe69c6942a7a737819660de_s"
    }
}
//下载器操作
extension PolyvPlayerDemoViewController {
    @IBAction func downloadAction(_ sender:Any) {
        downloader.setDownloadDelegate(self)
        downloader.start()
    }
    @IBAction func stopAction(_ sender:Any) {
        downloader.stop()
    }
    @IBAction func deleteAction (_ sender:Any) {
        PvUrlSessionDownload.deleteVideo(vid)
    }
}
//通知响应
extension PolyvPlayerDemoViewController {
    func moviePlayBackDidFinish (_ notification:Notification) {
        let info = notification.userInfo
        if let resultValue = info?[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] as? Int {
            let reason = MPMovieFinishReason(rawValue: resultValue)
            if reason == .playbackError {
                if let mediaPlayerError = info?["error"] {
                    LogPrint("playback failed with error description: \(mediaPlayerError)")
                } else {
                    LogPrint("playback failed without any given reason")
                }
            }
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish, object: nil)
    }
}
//MARK:download delegate
extension PolyvPlayerDemoViewController:PvUrlSessionDownloadDelegate {
    func dataDownloadStop(_ downloader: PvUrlSessionDownload!, withVid vid: String!) {
        
    }
    func downloadDidFinished(_ downloader: PvUrlSessionDownload!, withVid vid: String!) {
        LogPrint("vid:\(vid)")
        DispatchQueue.main.async {
            let alert = UIAlertView(title: "通知", message: "视频下载完成", delegate: self, cancelButtonTitle: "好")
            alert.show()
        }
    }
    func dataDownloadFailed(_ downloader: PvUrlSessionDownload!, withVid vid: String!, reason: String!) {
        DispatchQueue.main.async {
            let alert = UIAlertView(title: "下载失败", message: reason, delegate: self, cancelButtonTitle: "好")
            alert.show()
        }
    }
    func dataDownload(atPercent downloader: PvUrlSessionDownload!, withVid vid: String!, percent aPercent: NSNumber!) {
        LogPrint(aPercent)
        DispatchQueue.main.async {
            self.plabel.text = String(format: "%.02f%%", aPercent.floatValue)
            self.pbar.progress = aPercent.floatValue/100
        }
    }
    
    override var prefersStatusBarHidden:Bool {
        return true
    }
}
//MARK:页面旋转
extension PolyvPlayerDemoViewController {
    override var shouldAutorotate: Bool {
        return false
    }
    override var supportedInterfaceOrientations:UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation:UIInterfaceOrientation {
        return .portrait
    }
    
}

