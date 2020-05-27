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
        static let piholesV2 = "piholesV2"
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
    var piholes: [PiholeConnectionV2] {
        if let array = array(forKey: Preferences.Key.piholes), !array.isEmpty {
            // Migrate from PiBar v1.0 format to PiBar v1.1 format if needed
            Log.debug("Found V1 Pi-holes")
            var piholesV2: [PiholeConnectionV2] = []
            var piholesV1: [PiholeConnectionV1] = []
            for data in array {
                Log.debug("Loading Pi-hole V1...")
                guard let data = data as? Data, let piholeConnection = PiholeConnectionV1(data: data) else { continue }
                piholesV1.append(piholeConnection)
            }
            if !piholesV1.isEmpty {
                for pihole in piholesV1 {
                    Log.debug("Converting V1 Pi-hole to V2")
                    piholesV2.append(PiholeConnectionV2(
                        hostname: pihole.hostname,
                        port: pihole.port,
                        useSSL: pihole.useSSL,
                        token: pihole.token,
                        passwordProtected: true,
                        adminPanelURL: PiholeConnectionV2.generateAdminPanelURL(
                            hostname: pihole.hostname,
                            port: pihole.port,
                            useSSL: pihole.useSSL
                        )
                    ))
                }
                set([], for: Preferences.Key.piholes)
                let encodedArray = piholesV2.map { $0.encode()! }
                set(encodedArray, for: Preferences.Key.piholesV2)
            }
            return piholesV2
        } else if let array = array(forKey: Preferences.Key.piholesV2) {
            // Load Pi-holes in PiBar v1.1 format
            var piholesV2: [PiholeConnectionV2] = []
            for data in array {
                Log.debug("Loading Pi-hole V2...")
                guard let data = data as? Data, let piholeConnection = PiholeConnectionV2(data: data) else { continue }
                piholesV2.append(piholeConnection)
            }
            return piholesV2
        }
        return []
    }

    func set(piholes: [PiholeConnectionV2]) {
        let array = piholes.map { $0.encode()! }
        set(array, for: Preferences.Key.piholesV2)
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
        return integer(forKey: Preferences.Key.pollingRate)
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
