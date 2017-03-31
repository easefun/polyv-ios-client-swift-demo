//
//  LogPrint.swift
//  burui
//
//  Created by R0uter on 2017/3/30.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import Foundation
func LogPrint<T> (_ txt:T,line:Int = #line, method:String = #function, file:String = #file) {
    #if DEBUG
        print(file + "->line:\(line); method:" + method + "\t" + String(describing: txt) )
    #endif
}
