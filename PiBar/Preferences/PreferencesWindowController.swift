//
//  PreferencesWindowController.swift
//  PiBar
//
//  Created by Brad Root on 5/17/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa

class PreferencesWindowController: NSWindowController {
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)

        AppDelegate.bringToFront(window: window!)
    }
}
