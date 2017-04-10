//
//  DownloadListController.swift
//  polyv-ios-client-swift-demo
//
//  Created by R0uter on 2017/3/30.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit

class DownloadListController:UITableViewController {
    var videoList:[Video] = []
    var downloaderDictionary:[String:PvUrlSessionDownload] = [:]
    var btnStart:UIBarButtonItem!
    var started = false
    var currentVid = ""
//    lazy var videoPlayer:SkinVideoViewController = {
//        let width = UIScreen.main.bounds.size.width
//        let rect = CGRect(x: 0, y: 0, width: width, height: width*(9.0/16.0))
//        let v = SkinVideoViewController(frame: rect)
//        v?.configObserver()
//        v?.dimissCompleteBlock = {
//            v?.stop()
//            v?.cancel()
////            v?.cancelObserver()
//            
//        }
//        return v!
//    }()
    
    override func viewDidAppear(_ animated: Bool) {
        
        videoList = FMDBHelper.shared.listDownLoadVideo()
        
        for video in videoList {
            //只加入新增下载任务
            if !downloaderDictionary.keys.contains(video.vid) {
                let downloader = PvUrlSessionDownload(vid: video.vid, level: Int32(video.level))
                //设置下载代理为自身，需要实现四个代理方法download delegate
                downloader?.setDownloadDelegate(self)
                downloaderDictionary[video.vid] = downloader
            }
        }
        tableView.reloadData()
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        btnStart = UIBarButtonItem(title: "全部开始", style: .plain, target: self, action: #selector(startAll))
        navigationItem.rightBarButtonItem = btnStart
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleBackgroundSession), name: NSNotification.Name(rawValue: PLVBackgroundSessionUpdateNotification), object: nil)
        super.viewDidLoad()
    }
    
    func startAll() {
        if started {
            for item in downloaderDictionary {
                item.value.stop()
            }
            btnStart.title = "全部开始"
        } else {
            for item in downloaderDictionary {
                item.value.start()
            }
            btnStart.title = "全部停止"
        }
        started = !started
    }
    func handleBackgroundSession (_ notification:Notification) {
        // AppDelegate 执行 -application:handleEventsForBackgroundURLSession:completionHandler: 才把 block 属性赋值
        for downloader in downloaderDictionary.values {
            if let id = notification.userInfo?[PLVSessionIdKey] as? String {
                if id == downloader.sessionId {
                    downloader.completeBlock = notification.userInfo![PLVBackgroundSessionCompletionHandlerKey] as! () -> Void
                }
            }
        }
    }
 
    //更新下载百分比
    func update(percent:Double, vid:String) {
        for (index,video) in videoList.enumerated() {
            if video.vid == vid {
                video.percent = percent
                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                break
            }
        }
    }

    //更新视频下载的速率
    func update(rate:Int, vid:String) {
        for (index,video) in videoList.enumerated() {
            if video.vid == vid {
                if video.rate != rate {//和之前速率不相等时更新cell
                    video.rate = rate
                    tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    break
                }
            }
        }
    }

}
//MARK:pv download delegate
extension DownloadListController:PvUrlSessionDownloadDelegate {
    //下载完成
    func downloadDidFinished(_ downloader:PvUrlSessionDownload!,withVid vid:String!) {
        FMDBHelper.shared.updateDownload(vid: vid, percent: 100)
        FMDBHelper.shared.updateDownload(vid: vid, status: 1)
        LogPrint("downloadDidFinished \(vid)")
    }
    //下载被停止
    func dataDownloadStop(_ downloader: PvUrlSessionDownload!, withVid vid: String!) {
        LogPrint("stop download" + vid)
    }
    //下载失败
    func dataDownloadFailed(_ downloader: PvUrlSessionDownload!, withVid vid: String!, reason: String!) {
        FMDBHelper.shared.updateDownload(vid: vid, status: -1)
        LogPrint("dataDownloadFailed \(vid) - \(reason)")
    }
    
    //实时获取下载进度百分比
    func dataDownload(atPercent downloader: PvUrlSessionDownload!, withVid vid: String!, percent aPercent: NSNumber!) {
        FMDBHelper.shared.updateDownload(vid: vid, percent: aPercent.doubleValue)
        DispatchQueue.main.async {
            self.update(percent: aPercent.doubleValue, vid: vid)
        }
    }
    
    //实时获取下载速率(下载开始之后此方法会一直被调用直到当前下载任务结束)
    func dataDownload(atRate downloader: PvUrlSessionDownload!, withVid vid: String!, rate aRate: NSNumber!) {
        DispatchQueue.main.async {
            self.update(rate: aRate.intValue, vid: vid)
        }
    }
    func downloadTaskDidCreate(_ downloader: PvUrlSessionDownload!, withVid vid: String!) {
        LogPrint("创建任务:"+vid)
    }
    func downloadDidStart(_ downloader: PvUrlSessionDownload!, withVid vid: String!) {
        LogPrint("任务开始:"+vid)
    }
}
//MARK:页面旋转
extension DownloadListController {
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
//MARK:Table view data source
extension DownloadListController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoList.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "downloadItemCell")!
        let video = videoList[indexPath.row]
        
        let titleLabel = cell.viewWithTag(101) as! UILabel
        titleLabel.text = video.title
        let percentLabel = cell.viewWithTag(103) as! UILabel
        percentLabel.text = String(format: "%.1f%%, %ldkb/s", video.percent,video.rate)
        let filesizeLabel = cell.viewWithTag(102) as! UILabel
        filesizeLabel.text = String(format: "大小:%@", ByteCountFormatter.string(fromByteCount: video.filesize, countStyle: .file))
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = videoList[indexPath.row]
        let vc = DetailViewWithNavigationController()
        vc.video = video
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let video = videoList.remove(at: indexPath.row)
        if let downloader = downloaderDictionary[video.vid] {
            //删除任务需要执行清理下载URLSession，不然会再次加入任务的时候会报告session已经存在错误
            downloader.stop()
            downloader.cleanSession()
            downloaderDictionary.removeValue(forKey: video.vid)
        }
        PvUrlSessionDownload.deleteVideo(video.vid, level: Int32(video.level))
        FMDBHelper.shared.removeDownload(video: video)
        tableView.reloadData()
        
    }
}
