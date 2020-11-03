//
//  DisableDurationTableViewController.swift
//  PiBar for iOS
//
//  Created by Brad Root on 11/2/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit

class DisableDurationTableViewController: UITableViewController {
    weak var selectedCell: UITableViewCell?
    weak var delegate: PreferencesDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // there is undoubtedly a better way to do this, but this works
        var indexPath = IndexPath(row: 0, section: 0)
        switch Preferences.standard.defaultDisableDuration {
        case -1:
            indexPath = IndexPath(row: 0, section: 0)
        case 0:
            indexPath = IndexPath(row: 6, section: 0)
        case 10:
            indexPath = IndexPath(row: 1, section: 0)
        case 30:
            indexPath = IndexPath(row: 2, section: 0)
        case 300:
            indexPath = IndexPath(row: 3, section: 0)
        case 900:
            indexPath = IndexPath(row: 4, section: 0)
        case 3600:
            indexPath = IndexPath(row: 5, section: 0)
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
            Preferences.standard.set(defaultDisableDuration: cell.tag)
            selectedCell = cell
            delegate?.updatedPreferences()
        }
    }
}
