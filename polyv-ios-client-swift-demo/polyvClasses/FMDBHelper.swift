//
//  FMDBHelper.swift
//  polyv-ios-client-swift-demo
//
//  Created by R0uter on 2017/3/30.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import Foundation

class FMDBHelper {
    var DBName = ""
    var queue:FMDatabaseQueue!
    static let shared = FMDBHelper()
    private init () {
        DBName = get(path: "polyv.db")
        print(DBName)
        readyDownloadTable()
    }
    // 数据库存储路径(内部使用)
    func get(path dbNme:String) ->String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = path[0]
        return documentsDirectory.appending("/"+dbNme)
    }
    //打开数据库
    func readyDatabase() {
        queue = FMDatabaseQueue(path: DBName)
    
    }
}
 //MARK: downloadTable
extension FMDBHelper {
    
    func readyDownloadTable() {
        readyDatabase()
        queue.inDatabase {
            let sql = "create table if not exists downloadlist (vid varchar(40),title varchar(100),duration varchar(20),filesize bigint,level int,percent int default 0,status int,primary key (vid))"
            $0?.executeStatements(sql)
        }
    }
    
    func addDownload(video:Video) {
        queue.inDatabase{
            $0?.executeUpdate("replace INTO downloadlist(vid,title,duration,filesize,level,percent,status) VALUES (?,?,?,?,?,?,0)", withArgumentsIn: [video.vid,video.title,video.duration,Int64(video.filesize),Int(video.level),Int(video.percent)])
        }
    }
    func updateDownload(vid:String,percent:Double) {
        queue.inDatabase {
            $0?.executeUpdate("update downloadlist set percent=? where vid=?", withArgumentsIn: [Int(percent),vid])
        }
    }

    func updateDownload(vid:String,status:Int) {
        queue.inDatabase {
            $0?.executeUpdate("update downloadlist set status=? where vid=?", withArgumentsIn: [status,vid])
        }
    }
    
    func removeDownload(video:Video) {
        queue.inDatabase {
            $0?.executeUpdate("delete from downloadlist where vid=?", withArgumentsIn: [video.vid])
        }
    }
    
}

extension FMDBHelper {
    func listDownLoadVideo()->[Video] {
        var downloadVideos:[Video] = []
        queue.inDatabase {
            if let rs = $0?.executeQuery("select * from downloadlist", withArgumentsIn: []) {
                while rs.next() {
                    let v = Video()
                    v.vid = rs.string(forColumn: "vid")
                    v.title = rs.string(forColumn: "title")
                    v.duration = rs.string(forColumn: "duration")
                    v.filesize = rs.longLongInt(forColumn: "filesize")
                    v.level = Int(rs.int(forColumn: "level"))
                    v.percent = Double(rs.int(forColumn: "percent"))
                    v.status = Int(rs.int(forColumn: "status"))
                    downloadVideos.append(v)
                }
            }
            
        }
        return downloadVideos
    }
}

