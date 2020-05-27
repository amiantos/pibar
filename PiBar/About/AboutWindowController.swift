//
//  AboutWindowController.swift
//  PiBar
//
//  Created by Brad Root on 5/26/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Cocoa

class AboutWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()

        AppDelegate.bringToFront(window: window!)
    }
}
