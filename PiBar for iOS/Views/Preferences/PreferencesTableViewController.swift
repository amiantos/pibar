//
//  PreferencesTableViewController.swift
//  PiBar for iOS
//
//  Created by Brad Root on 8/24/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit

class PreferencesTableViewController: UITableViewController {
    @IBOutlet var interfaceColorLabel: UILabel!
    @IBOutlet weak var normalizeChartsLabel: UILabel!

    @IBAction func doneButtonAction(_: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    override func viewWillAppear(_: Bool) {
        interfaceColorLabel.text = Preferences.standard.interfaceColor.capitalized
        normalizeChartsLabel.text = Preferences.standard.normalizeCharts ? "On" : "Off"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 0, section: 2) {
            UIApplication.shared.open(URL(string: "https://github.com/amiantos/pibar")!)
        } else if indexPath == IndexPath(row: 1, section: 2) {
            UIApplication.shared.open(URL(string: "https://reddit.com/r/pibar")!)

        } else if indexPath == IndexPath(row: 2, section: 2) {
            UIApplication.shared.open(URL(string: "https://twitter.com/amiantos")!)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
