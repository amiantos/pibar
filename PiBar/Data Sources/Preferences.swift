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
        static let piholes = "piholes" // Deprecated in PiBar 1.1
        static let piholesV2 = "piholesV2" // Deprecated in PiBar 1.2
        static let piholesV3 = "piholesV3"
        static let showBlocked = "showBlocked"
        static let showQueries = "showQueries"
        static let showPercentage = "showPercentage"
        static let showLabels = "showLabels"
        static let verboseLabels = "verboseLabels"
        static let shortcutEnabled = "shortcutEnabled"
        static let pollingRate = "pollingRate"
    }

    static var standard: UserDefaults {
        let database = UserDefaults.standard
        database.register(defaults: [
            Key.piholes: [],
            Key.piholesV2: [],
            Key.piholesV3: [],
            Key.showBlocked: true,
            Key.showQueries: true,
            Key.showPercentage: true,
            Key.showLabels: false,
            Key.verboseLabels: false,
            Key.shortcutEnabled: true,
            Key.pollingRate: 3,
        ])

        return database
    }
}

extension UserDefaults {
    var piholes: [PiholeConnectionV3] {
        if let array = array(forKey: Preferences.Key.piholesV2), !array.isEmpty {
            // Migrate from PiBar v1.1 format to PiBar v1.2 format if needed
            Log.debug("Found V1 Pi-holes")
            var piholesV2: [PiholeConnectionV2] = []
            var piholesV3: [PiholeConnectionV3] = []
            for data in array {
                Log.debug("Loading Pi-hole V2...")
                guard let data = data as? Data, let piholeConnection = PiholeConnectionV2(data: data) else { continue }
                piholesV2.append(piholeConnection)
            }
            if !piholesV2.isEmpty {
                for pihole in piholesV2 {
                    Log.debug("Converting V2 Pi-hole to V3")
                    piholesV3.append(PiholeConnectionV3(hostname: pihole.hostname, port: pihole.port, useSSL: pihole.useSSL, token: pihole.token, passwordProtected: pihole.passwordProtected, adminPanelURL: pihole.adminPanelURL, isV6: false))
                }
                set([], for: Preferences.Key.piholesV2)
                let encodedArray = piholesV3.map { $0.encode()! }
                set(encodedArray, for: Preferences.Key.piholesV3)
            }
            return piholesV3
        } else if let array = array(forKey: Preferences.Key.piholesV3), !array.isEmpty {
            var piholesV3: [PiholeConnectionV3] = []
            for data in array {
                Log.debug("Loading V3 Pi-hole")
                guard let data = data as? Data, let piholeConnection = PiholeConnectionV3(data: data) else { continue }
                piholesV3.append(piholeConnection)
            }
            return piholesV3
        }
        return []
    }

    func set(piholes: [PiholeConnectionV3]) {
        let array = piholes.map { $0.encode()! }
        set(array, for: Preferences.Key.piholesV3)
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

    var pollingRate: Int {
        let savedPollingRate = integer(forKey: Preferences.Key.pollingRate)
        if savedPollingRate >= 3 {
            return savedPollingRate
        }
        set(pollingRate: 3)
        return 3
    }

    func set(pollingRate: Int) {
        set(pollingRate, for: Preferences.Key.pollingRate)
    }

    // Helpers

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
