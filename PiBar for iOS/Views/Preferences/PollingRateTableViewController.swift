//
//  PollingRateTableViewController.swift
//  PiBar for iOS
//
//  Created by Brad Root on 10/26/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit

class PollingRateTableViewController: UITableViewController {
    weak var selectedCell: UITableViewCell?
    weak var delegate: PreferencesDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)

        // there is undoubtedly a better way to do this, but this works
        var indexPath = IndexPath(row: 0, section: 0)
        switch Preferences.standard.pollingRate {
        case 5:
            indexPath = IndexPath(row: 1, section: 0)
        case 10:
            indexPath = IndexPath(row: 2, section: 0)
        case 15:
            indexPath = IndexPath(row: 3, section: 0)
        case 30:
            indexPath = IndexPath(row: 4, section: 0)
        case 60:
            indexPath = IndexPath(row: 5, section: 0)
        case 300:
            indexPath = IndexPath(row: 6, section: 0)
        default:
            indexPath = IndexPath(row: 0, section: 0)
        }
        if let cell = tableView.cellForRow(at: indexPath) {
            selectedCell = cell
            cell.accessoryType = .checkmark
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCell?.accessoryType = .none
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            Preferences.standard.set(pollingRate: cell.tag)
            selectedCell = cell
            delegate?.updatedPreferences()
        }
    }
}
