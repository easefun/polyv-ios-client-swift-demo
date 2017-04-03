//
//  SubTitleLabel.swift
//  polyv-ios-client-swift-demo
//
//  Created by R0uter on 2017/4/3.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit
class SubTitleLabel:UILabel {
    override func drawText(in rect: CGRect) {
        let height = sizeThatFits(rect.size).height
        var rect = rect
        rect.origin.y += rect.size.height - height
        rect.size.height = height
        super.drawText(in: rect)
    }
}
