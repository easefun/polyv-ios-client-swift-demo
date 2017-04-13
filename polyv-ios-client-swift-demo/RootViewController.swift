//
//  RootViewController.swift
//  polyv-ios-client-swift-demo
//
//  Created by R0uter on 2017/4/9.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit

class RootViewController:UITabBarController {
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedIndex = 0
    }
    // 哪些页面支持自动转屏
    override var shouldAutorotate: Bool {
        
        if let vc = viewControllers?[selectedIndex] as? UINavigationController {
            return vc.topViewController!.isMember(of: DetailViewWithNavigationController.self)
        }
        return false
    }
    // 支持哪些转屏方向
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let vc = viewControllers?[selectedIndex] as? UINavigationController {
            if vc.topViewController!.isMember(of: DetailViewWithNavigationController.self) {
                return .allButUpsideDown
            }
            
        }
        return .portrait// 其他页面支持转屏方向
    }
}
