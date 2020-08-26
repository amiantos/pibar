//
//  ThemeManager.swift
//  PiBar for iOS
//
//  Created by Brad Root on 8/25/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Foundation
import UIKit

class ThemeManager {
    static func initialize() {
        let colorString = Preferences.standard.interfaceColor
        if let foundColor = UIColor(named: colorString) {
            applyColor(color: foundColor)
        }
    }
    static func setColor(color: String) {
        if let foundColor = UIColor(named: color) {
            Preferences.standard.set(interfaceColor: color)
            applyColor(color: foundColor)
        }
    }

    static func applyColor(color: UIColor) {
        UINavigationBar.appearance().tintColor = color
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: color], for: .normal)
        PiBarLabel.appearance().configurableTextColor = color
        PiBarChartView.appearance().chartColor = color

        for window in UIApplication.shared.windows {
            if !window.isKind(of: NSClassFromString("UITextEffectsWindow") ?? NSString.classForCoder()) {
                window.subviews.forEach {
                    $0.removeFromSuperview()
                    window.addSubview($0)
                }
            }
        }
    }
}
