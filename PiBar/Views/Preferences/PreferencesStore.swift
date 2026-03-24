//
//  PreferencesStore.swift
//  PiBar
//
//  Created by Brad Root on 3/23/26.
//  Copyright © 2026 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Observation

protocol PreferencesDelegate: AnyObject {
    func updatedPreferences()
    func updatedConnections()
}

@Observable
class PreferencesStore {
    weak var delegate: PreferencesDelegate?

    var connections: [PiholeConnection] = []
    var showBlocked: Bool = true
    var showQueries: Bool = true
    var showPercentage: Bool = true
    var showLabels: Bool = false
    var verboseLabels: Bool = false
    var shortcutEnabled: Bool = true
    var pollingRate: Int = 3

    init() {
        load()
    }

    func load() {
        let prefs = Preferences.standard
        connections = prefs.piholes
        showBlocked = prefs.showBlocked
        showQueries = prefs.showQueries
        showPercentage = prefs.showPercentage
        showLabels = prefs.showLabels
        verboseLabels = prefs.verboseLabels
        shortcutEnabled = prefs.shortcutEnabled
        pollingRate = prefs.pollingRate
    }

    func saveDisplaySettings() {
        let prefs = Preferences.standard
        prefs.set(showBlocked: showBlocked)
        prefs.set(showQueries: showQueries)
        prefs.set(showPercentage: showPercentage)
        prefs.set(showLabels: showLabels)
        prefs.set(verboseLabels: verboseLabels)
        prefs.set(shortcutEnabled: shortcutEnabled)

        if pollingRate >= 3 {
            prefs.set(pollingRate: pollingRate)
        } else {
            pollingRate = 3
            prefs.set(pollingRate: 3)
        }

        delegate?.updatedPreferences()
    }

    func addConnection(_ connection: PiholeConnection) {
        connections.append(connection)
        Preferences.standard.set(piholes: connections)
        delegate?.updatedConnections()
    }

    func updateConnection(_ connection: PiholeConnection) {
        if let index = connections.firstIndex(where: { $0.id == connection.id }) {
            connections[index] = connection
            Preferences.standard.set(piholes: connections)
            delegate?.updatedConnections()
        }
    }

    func removeConnection(at offsets: IndexSet) {
        for index in offsets {
            connections[index].deleteToken()
        }
        connections.remove(atOffsets: offsets)
        Preferences.standard.set(piholes: connections)
        delegate?.updatedConnections()
    }

    func removeConnection(_ connection: PiholeConnection) {
        connection.deleteToken()
        connections.removeAll { $0.id == connection.id }
        Preferences.standard.set(piholes: connections)
        delegate?.updatedConnections()
    }
}
