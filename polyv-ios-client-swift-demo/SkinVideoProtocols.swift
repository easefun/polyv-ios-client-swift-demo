//
//  SkinVideoProtocols.swift
//  polyv-ios-client-swift-demo
//
//  Created by R0uter on 2017/3/31.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import Foundation

protocol rotateFullScreen {
    func fullScreenAction(_ sender:UIButton)
    func backButtonAction()
    func addOrientationObserver()
    func removeOrientationObserver()
}
protocol Gesture:UIGestureRecognizerDelegate {
    func panHandler(_ recognizer:UIPanGestureRecognizer)
}
