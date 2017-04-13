//
//  AppDelegate.swift
//  polyv-ios-client-swift-demo
//
//  Created by R0uter on 2017/3/30.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Override point for customization after application launch.
        //download dir
        PolyvSettings.shared().downloadDir = NSHomeDirectory().appending("/Documents/plvideo/a")
        PolyvSettings.shared().logLevel = .all
        PolyvSettings.shared().httpDNSEnable = true
        
        let appKey = "iPGXfu3KLEOeCW4KXzkWGl1UYgrJP7hRxUfsJGldI6DEWJpYfhaXvMA+32YIYqAOocWd051v5XUAU17LoVlgZCSEVNkx11g7CxYadcFPYPozslnQhFjkxzzjOt7lUPsWF/CO2xt5xZemQCBkkSKLGA=="
        let config = PolyvUtil.decryptUserConfig(appKey.data(using: .utf8))!
        PolyvSettings.shared().initVideoSettings(config[1] as! String, readtoken: config[2] as! String, writetoken: config[3] as! String, userId: config[0] as! String)
        

        return true
    }
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        let userInfo = [
            PLVSessionIdKey:identifier,
            PLVBackgroundSessionCompletionHandlerKey:completionHandler
        ] as [String : Any]
        NotificationCenter.default.post(name: NSNotification.Name(PLVBackgroundSessionUpdateNotification), object: self, userInfo: userInfo)
    }
    func applicationWillResignActive(_ application: UIApplication) {
        PolyvSettings.shared().reload()
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

