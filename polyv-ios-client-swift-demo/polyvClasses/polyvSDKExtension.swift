//
//  polyvSDKExtension.swift
//  burui
//
//  Created by R0uter on 2017/3/30.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit
extension PolyvSettings {
    static func shared() -> PolyvSettings {
        return PolyvSettings.sharedInstance() as! PolyvSettings
    }
}
