//
//  PiBarManager.swift
//  PiBar
//
//  Created by Brad Root on 5/20/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

protocol PiBarManagerDelegate: AnyObject {
    func networkUpdated()
}

class PiBarManager: NSObject {
    private var piholes: [String: Pihole] = [:] {
        didSet {
            updateNetworkOverview()
        }
    }

    private var timer: Timer?
    private let updateInterval: TimeInterval = 3

    override init() {
        Log.logLevel = .debug
        Log.useEmoji = true

        networkOverview = PiholeNetworkOverview(
            networkStatus: .initializing,
            canBeManaged: false,
            totalQueriesToday: 0,
            adsBlockedToday: 0,
            adsPercentageToday: 0.0,
            averageBlocklist: 0,
            piholes: [:]
        )
        super.init()
        loadConnections()
    }

    // MARK: - Public Variables and Functions

    weak var delegate: PiBarManagerDelegate?

    private(set) var networkOverview: PiholeNetworkOverview {
        didSet {
            delegate?.networkUpdated()
        }
    }

    func loadConnections() {
        createPiholes(Preferences.standard.piholes)
    }

    func toggleNetwork() {
        if networkStatus() == .enabled || networkStatus() == .partiallyEnabled {
            disableNetwork()
        } else if networkStatus() == .disabled {
            enableNetwork()
        }
    }

    func disableNetwork(seconds: Int? = nil) {
        for pihole in piholes.values {
            pihole.api.disable(seconds: seconds) { success in
                if success {
                    self.updatePihole(pihole)
                }
            }
        }
    }

    func enableNetwork() {
        piholes.values.forEach { pihole in
            pihole.api.enable { success in
                if success {
                    self.updatePihole(pihole)
                }
            }
        }
    }

    // MARK: - Private Functions

    // MARK: Timer

    private func startTimer() {
        stopTimer()

        let newTimer = Timer(timeInterval: updateInterval, target: self, selector: #selector(updatePiholes), userInfo: nil, repeats: true)
        newTimer.tolerance = 0.2
        RunLoop.current.add(newTimer, forMode: .common)

        timer = newTimer

        Log.debug("Manager: Timer Started")
    }

    private func stopTimer() {
        if let existingTimer = timer {
            existingTimer.invalidate()
            timer = nil
        }
    }

    // MARK: Data Updates

    private func createNewNetwork() {
        networkOverview = PiholeNetworkOverview(
            networkStatus: .initializing,
            canBeManaged: false,
            totalQueriesToday: 0,
            adsBlockedToday: 0,
            adsPercentageToday: 0.0,
            averageBlocklist: 0,
            piholes: [:]
        )
    }

    private func createPiholes(_ connections: [PiholeConnectionV2]) {
        Log.debug("Manager: Updating Connections")

        stopTimer()
        piholes.removeAll()
        createNewNetwork()

        let apis = connections.map { PiholeAPI(connection: $0) }
        apis.forEach {
            piholes[$0.identifier] = Pihole(
                api: $0,
                identifier: $0.identifier,
                online: false,
                summary: nil,
                canBeManaged: nil,
                enabled: nil
            )
        }

        updatePiholes()

        startTimer()
    }

    @objc private func updatePiholes() {
        Log.debug("Manager: Updating Pi-holes")

        piholes.values.forEach {
            updatePihole($0)
        }

        if piholes.isEmpty {
            updateNetworkOverview()
        }
    }

    private func updatePihole(_ pihole: Pihole) {
        pihole.api.fetchSummary { summary in
            DispatchQueue.main.async {
                var enabled: Bool? = true
                var online = true
                var canBeManaged: Bool = false

                if let summary = summary {
                    if summary.status != "enabled" {
                        enabled = false
                    }
                    if !pihole.api.connection.token.isEmpty || !pihole.api.connection.passwordProtected {
                        canBeManaged = true
                    }
                } else {
                    enabled = nil
                    online = false
                    canBeManaged = false
                }

                let pihole: Pihole = Pihole(
                    api: pihole.api,
                    identifier: pihole.api.identifier,
                    online: online,
                    summary: summary,
                    canBeManaged: canBeManaged,
                    enabled: enabled
                )

                self.piholes[pihole.identifier] = pihole

                Log.debug("Updated Pi-hole: \(pihole.identifier)")
            }
        }
    }

    private func updateNetworkOverview() {
        networkOverview = PiholeNetworkOverview(
            networkStatus: networkStatus(),
            canBeManaged: canManage(),
            totalQueriesToday: networkTotalQueries(),
            adsBlockedToday: networkBlockedQueries(),
            adsPercentageToday: networkPercentageBlocked(),
            averageBlocklist: networkBlocklist(),
            piholes: piholes
        )
    }

    private func networkTotalQueries() -> Int {
        var queries: Int = 0
        piholes.values.forEach {
            queries += $0.summary?.dnsQueriesToday ?? 0
        }
        return queries
    }

    private func networkBlockedQueries() -> Int {
        var queries: Int = 0
        piholes.values.forEach {
            queries += $0.summary?.adsBlockedToday ?? 0
        }
        return queries
    }

    private func networkPercentageBlocked() -> Double {
        let totalQueries = networkTotalQueries()
        let blockedQueries = networkBlockedQueries()
        if totalQueries == 0 || blockedQueries == 0 {
            return 0.0
        }
        return Double(blockedQueries) / Double(totalQueries) * 100.0
    }

    private func networkBlocklist() -> Int {
        var blocklistCounts: [Int] = []
        piholes.values.forEach {
            blocklistCounts.append($0.summary?.domainsBeingBlocked ?? 0)
        }
        return blocklistCounts.average()
    }

    private func networkStatus() -> PiholeNetworkStatus {
        var summaries: [PiholeAPISummary] = []
        piholes.values.forEach {
            if let summary = $0.summary { summaries.append(summary) }
        }

        if piholes.isEmpty {
            return .noneSet
        } else if summaries.isEmpty {
            return .offline
        } else if summaries.count < piholes.count {
            return .partiallyOffline
        }

        var status = Set<String>()
        summaries.forEach {
            status.insert($0.status)
        }
        if status.count == 1 {
            let statusString = status.first!
            if statusString == "enabled" {
                return .enabled
            } else {
                return .disabled
            }
        } else {
            return .partiallyEnabled
        }
    }

    private func canManage() -> Bool {
        for pihole in piholes.values where pihole.canBeManaged ?? false {
            return true
        }

        return false
    }
}
