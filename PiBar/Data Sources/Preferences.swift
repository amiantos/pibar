//
//  Preferences.swift
//  PiBar
//
//  Created by Brad Root on 5/17/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct Preferences {
    fileprivate enum Key {
        static let piholes = "piholes"
        static let showBlocked = "showBlocked"
        static let showQueries = "showQueries"
        static let showPercentage = "showPercentage"
        static let showLabels = "showLabels"
        static let verboseLabels = "verboseLabels"
        static let shortcutEnabled = "shortcutEnabled"
    }

    static var standard: UserDefaults {
        let database = UserDefaults.standard
        database.register(defaults: [
            Key.piholes: [],
            Key.showBlocked: true,
            Key.showQueries: true,
            Key.showPercentage: true,
            Key.showLabels: false,
            Key.verboseLabels: false,
            Key.shortcutEnabled: true,
        ])

        return database
    }
}

extension UserDefaults {
    var piholes: [PiholeConnection] {
        if let array = array(forKey: Preferences.Key.piholes) {
            var piholes: [PiholeConnection] = []
            for data in array {
                guard let data = data as? Data, let piholeConnection = PiholeConnection(data: data) else { continue }
                piholes.append(piholeConnection)
            }
            return piholes
        } else {
            return []
        }
    }

    func set(piholes: [PiholeConnection]) {
        let array = piholes.map { $0.encode()! }
        set(array, for: Preferences.Key.piholes)
    }

    var showBlocked: Bool {
        return bool(forKey: Preferences.Key.showBlocked)
    }

    func set(showBlocked: Bool) {
        set(showBlocked, for: Preferences.Key.showBlocked)
    }

    var showQueries: Bool {
        return bool(forKey: Preferences.Key.showQueries)
    }

    func set(showQueries: Bool) {
        set(showQueries, for: Preferences.Key.showQueries)
    }

    var showPercentage: Bool {
        return bool(forKey: Preferences.Key.showPercentage)
    }

    func set(showPercentage: Bool) {
        set(showPercentage, for: Preferences.Key.showPercentage)
    }

    var showLabels: Bool {
        return bool(forKey: Preferences.Key.showLabels)
    }

    func set(showLabels: Bool) {
        set(showLabels, for: Preferences.Key.showLabels)
    }

    var verboseLabels: Bool {
        return bool(forKey: Preferences.Key.verboseLabels)
    }

    func set(verboseLabels: Bool) {
        set(verboseLabels, for: Preferences.Key.verboseLabels)
    }

    var shortcutEnabled: Bool {
        return bool(forKey: Preferences.Key.shortcutEnabled)
    }

    func set(shortcutEnabled: Bool) {
        set(shortcutEnabled, for: Preferences.Key.shortcutEnabled)
    }

    var showTitle: Bool {
        return showQueries || showBlocked || showPercentage
    }
}

private extension UserDefaults {
    func set(_ object: Any?, for key: String) {
        set(object, forKey: key)
        synchronize()
    }
}
