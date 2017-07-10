//
//  polyvSDKExtension.swift
//  burui
//
//  Created by R0uter on 2017/3/30.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit
extension PolyvSettings {
    static var shared: PolyvSettings {
        return PolyvSettings.sharedInstance() as! PolyvSettings
    }
}
extension Notification.Name {
    static let PLVErrorNotification:Notification.Name = Notification.Name(rawValue: "PLVErrorNotification")
}
