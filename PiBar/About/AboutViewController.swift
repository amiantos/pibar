//
//  AboutViewController.swift
//  PiBar
//
//  Created by Brad Root on 5/26/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Cocoa

class AboutViewController: NSViewController {
    @IBAction func aboutURLAction(_: NSButton) {
        let url = URL(string: "https://github.com/amiantos/pibar")!
        NSWorkspace.shared.open(url)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
