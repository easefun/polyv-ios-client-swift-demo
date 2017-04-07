//
//  VideoListController.swift
//  burui
//
//  Created by R0uter on 2017/3/30.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit

class VideoListController:UITableViewController,UIAlertViewDelegate {
    var video:Video!
    var fmdbHelper:FMDBHelper = FMDBHelper.shared
    var videoList:[Video] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LogPrint("Download dir \(PolyvSettings.shared().downloadDir!)")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 101
        var request = URLRequest(url: URL(string: "https://demo.polyv.net/data/video.js")!)

        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            LogPrint("Download !!!")
            if data != nil {
                let jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                if let videos = jsonData?["data"] as? [[String:Any]] {
                    for item in videos {
                        let video = Video(withJSON: item)
                        self.videoList.append(video)
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                } else {
                    print("______ 账号下暂无视频")
                }
            }
        }.resume()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.isNavigationBarHidden = false
        UIApplication.shared.setStatusBarStyle(.default, animated: true)
    }
    //MARK: Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoList.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "videoCellIdentifier")!
        let video = videoList[indexPath.row]
        let imageView = cell.viewWithTag(103) as! UIImageView
        NSURLConnection.sendAsynchronousRequest(URLRequest(url: URL(string:video.piclink)!), queue: OperationQueue.main) { (response, data, e) in
            if let d = data {
                imageView.image = UIImage(data: d)
            }
        }
        
        let titleLabel = cell.viewWithTag(101) as! UILabel
        titleLabel.text = video.title;
        let descLabel = cell.viewWithTag(102) as! UILabel
        descLabel.text = video.desc
        let typeLabel = cell.viewWithTag(105) as! UILabel
        typeLabel.text = video.seed == 1 ? "加密" : ""
        
        if let button = cell.viewWithTag(104) as? UIButton {
            button.tag = indexPath.row
            button.addTarget(self, action: #selector(downloadClick), for: .touchUpInside)
        }
        
        return cell
    }
    func downloadClick (_ sender:UIButton) {
        video = videoList[sender.tag]
        let title = "选择要下载的码率"
        let msg = "您要下载哪个清晰度的视频?"
        let cancel = "取消"
        switch video.allfilesize.count {
        case 1:
            UIAlertView(title: title, message: msg, delegate: self, cancelButtonTitle: cancel, otherButtonTitles: "流畅").show()
        case 2:
            UIAlertView(title: title, message: msg, delegate: self, cancelButtonTitle: cancel, otherButtonTitles: "流畅","高清" ).show()
        default:
            UIAlertView(title: title, message: msg, delegate: self, cancelButtonTitle: cancel, otherButtonTitles: "流畅","高清","超清" ).show()
        }
    }
    func alertView(_ alertView: UIAlertView, willDismissWithButtonIndex buttonIndex: Int) {
        guard buttonIndex > 0, buttonIndex < 3 else {return}
        video.level = buttonIndex
        video.filesize = video.allfilesize[buttonIndex-1]
        fmdbHelper.addDownload(video: video)
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = videoList[indexPath.row]
        
        let vc = DetailViewWithNavigationController()
        vc.video = video
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
