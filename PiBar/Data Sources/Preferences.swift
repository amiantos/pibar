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
        static let piholesV3 = "piholesV3" // Deprecated in PiBar 2.0
        static let piholesV4 = "piholesV4"
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
            Key.piholesV4: [],
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
    var piholes: [PiholeConnection] {
        // Try loading v4 format first
        if let array = array(forKey: Preferences.Key.piholesV4) as? [Data], !array.isEmpty {
            let decoder = JSONDecoder()
            return array.compactMap { try? decoder.decode(PiholeConnection.self, from: $0) }
        }

        // Migrate from v3 format
        if let array = array(forKey: Preferences.Key.piholesV3) as? [Data], !array.isEmpty {
            let decoder = JSONDecoder()
            let v3Connections = array.compactMap { try? decoder.decode(PiholeConnectionV3.self, from: $0) }
            let migrated = v3Connections.map { v3 in
                let connection = PiholeConnection(
                    id: UUID(),
                    hostname: v3.hostname,
                    port: v3.port,
                    useSSL: v3.useSSL,
                    version: v3.isV6 ? .v6 : .v5,
                    passwordProtected: v3.passwordProtected,
                    adminPanelURL: v3.adminPanelURL,
                    savePassword: false,
                    requiresTOTP: false
                )
                // Migrate token to Keychain
                if !v3.token.isEmpty {
                    connection.saveToken(v3.token)
                }
                return connection
            }
            if !migrated.isEmpty {
                set(piholes: migrated)
                set([], forKey: Preferences.Key.piholesV3)
            }
            return migrated
        }

        // Migrate from v2 format
        if let array = array(forKey: Preferences.Key.piholesV2) as? [Data], !array.isEmpty {
            let decoder = JSONDecoder()
            let v2Connections = array.compactMap { try? decoder.decode(PiholeConnectionV2.self, from: $0) }
            let migrated = v2Connections.map { v2 in
                let connection = PiholeConnection(
                    id: UUID(),
                    hostname: v2.hostname,
                    port: v2.port,
                    useSSL: v2.useSSL,
                    version: .v5,
                    passwordProtected: v2.passwordProtected,
                    adminPanelURL: v2.adminPanelURL,
                    savePassword: false,
                    requiresTOTP: false
                )
                if !v2.token.isEmpty {
                    connection.saveToken(v2.token)
                }
                return connection
            }
            if !migrated.isEmpty {
                set(piholes: migrated)
                set([], forKey: Preferences.Key.piholesV2)
            }
            return migrated
        }

        return []
    }

    func set(piholes: [PiholeConnection]) {
        let encoder = JSONEncoder()
        let array = piholes.compactMap { try? encoder.encode($0) }
        set(array, forKey: Preferences.Key.piholesV4)
        synchronize()
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
