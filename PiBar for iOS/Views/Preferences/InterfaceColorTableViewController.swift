//
//  InterfaceColorTableViewController.swift
//  PiBar for iOS
//
//  Created by Brad Root on 8/25/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit

class InterfaceColorTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            set(color: "red")
        case 1:
            set(color: "orange")
        case 2:
            set(color: "yellow")
        case 3:
            set(color: "green")
        case 4:
            set(color: "blue")
        case 5:
            set(color: "indigo")
        case 6:
            set(color: "violet")
        default:
            set(color: "red")
        }
    }
}

extension InterfaceColorTableViewController {
    fileprivate func set(color: String) {
        ThemeManager.setColor(color: color)
    }
}
