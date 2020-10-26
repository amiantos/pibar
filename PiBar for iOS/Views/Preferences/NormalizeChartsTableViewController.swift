//
//  NormalizeChartsTableViewController.swift
//  PiBar for iOS
//
//  Created by Brad Root on 10/25/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit

class NormalizeChartsTableViewController: UITableViewController {

    @IBOutlet weak var normalizeChartsToggle: UISwitch!
    @IBAction func toggleDidChange(_ sender: UISwitch) {
        Preferences.standard.set(normalizeCharts: sender.isOn)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        normalizeChartsToggle.isOn = Preferences.standard.normalizeCharts
    }

}
