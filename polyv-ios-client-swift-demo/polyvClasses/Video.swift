//
//  Video.swift
//  polyv-ios-client-swift-demo
//
//  Created by R0uter on 2017/3/30.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import Foundation

class Video {
    var title = ""///标题
    var desc = ""///视频描述
    var vid = ""///视频的vid
    var piclink = ""///视频第一张图的链接
    var duration = ""///视频的总时长
    var filesize:Int64 = 0///视频大小
    var allfilesize:[Int64] = []///同一个视频各个不同清晰度的视频大小
    var level = 0///视频清晰度，1：流畅, 2：高清, 3：超清
    var df = 0///视频码率数
    var seed = 0///加密方式，1为加密，0为非加密
    var status = 0///下载状态
    var percent = 0.0///下载进度，百分比
    var rate = 0///下载速率，单位kb/s
    
    init(withJSON item:[String:Any]) {
        
            title = item["title"] as! String
            desc = item["context"] as! String
            vid = item["vid"] as! String
            duration = item["duration"] as! String
            piclink = (item["first_image"] as! String).replacingOccurrences(of: "http://", with: "https://")
            //                        video.df = item["df"] as! Int32
            seed = item["seed"] as! Int
            allfilesize = item["filesize"] as! [Int64]
    }
    
    init?(withVid:String) {
        if let item = PolyvSettings.loadVideoJson(withVid) {
            self.title = item ["title"] as! String
            self.duration = item["duration"] as! String
            self.desc = item["duration"] as! String
            self.piclink = item["first_image"] as! String
            self.df = item["df_num"] as! Int
            self.seed = item["seed"] as! Int
            self.allfilesize = item["filesize"] as! [Int64]
            self.vid = withVid
        }
    }

}
