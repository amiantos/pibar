//
//  PiBarLabel.swift
//  PiBar for iOS
//
//  Created by Brad Root on 8/25/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit

class PiBarLabel: UILabel {
    @objc dynamic var configurableTextColor: UIColor {
        get {
            return textColor
        }
        set {
            textColor = newValue
        }
    }
}
