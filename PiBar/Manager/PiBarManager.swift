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
    func updateNetwork(_ network: PiholeNetworkOverview)
}

class PiBarManager {
    private var piholes: [String: Pihole] = [:]

    private var networkOverview: PiholeNetworkOverview {
        didSet {
            let overview = networkOverview
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.updateNetwork(overview)
            }
        }
    }

    private var pollingTask: Task<Void, Never>?
    private var updateInterval: TimeInterval

    weak var delegate: PiBarManagerDelegate?

    init() {
        Log.logLevel = .debug
        Log.useEmoji = true

        updateInterval = TimeInterval(Preferences.standard.pollingRate)

        networkOverview = PiholeNetworkOverview(
            networkStatus: .initializing,
            canBeManaged: false,
            totalQueriesToday: 0,
            adsBlockedToday: 0,
            adsPercentageToday: 0.0,
            averageBlocklist: 0,
            piholes: [:],
            hasIgnoredOfflinePiholes: false
        )

        loadConnections()
    }

    // MARK: - Public

    func loadConnections() {
        createPiholes(Preferences.standard.piholes)
    }

    func setPollingRate(to seconds: Int) {
        let newPollingRate = TimeInterval(seconds)
        if newPollingRate != updateInterval {
            Log.debug("Changed polling rate to: \(seconds)")
            updateInterval = newPollingRate
            startPolling()
        }
    }

    func toggleNetwork() {
        let status = networkStatus()
        if status == .enabled || status == .partiallyEnabled {
            disableNetwork()
        } else if status == .disabled {
            enableNetwork()
        }
    }

    func disableNetwork(seconds: Int? = nil) {
        stopPolling()
        let targets = activePiholes()
        Task {
            await withTaskGroup(of: Void.self) { group in
                for pihole in targets {
                    group.addTask {
                        do {
                            try await pihole.api.disable(seconds: seconds)
                        } catch {
                            Log.error("Failed to disable \(pihole.identifier): \(error)")
                        }
                    }
                }
            }
            await updateAllPiholes()
            startPolling()
        }
    }

    func enableNetwork() {
        stopPolling()
        let targets = activePiholes()
        Task {
            await withTaskGroup(of: Void.self) { group in
                for pihole in targets {
                    group.addTask {
                        do {
                            try await pihole.api.enable()
                        } catch {
                            Log.error("Failed to enable \(pihole.identifier): \(error)")
                        }
                    }
                }
            }
            await updateAllPiholes()
            startPolling()
        }
    }

    private func activePiholes() -> [Pihole] {
        piholes.values.filter { !($0.api.connection.ignoreWhenOffline && !$0.online) }
    }

    private func hasIgnoredOfflinePiholes() -> Bool {
        piholes.values.contains { $0.api.connection.ignoreWhenOffline && !$0.online }
    }

    // MARK: - Private

    private func startPolling() {
        stopPolling()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.updateInterval ?? 3))
                guard !Task.isCancelled else { break }
                await self?.updateAllPiholes()
            }
        }
        Log.debug("Manager: Polling Started")
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        Log.debug("Manager: Polling Stopped")
    }

    private func createPiholes(_ connections: [PiholeConnection]) {
        Log.debug("Manager: Updating Connections")

        stopPolling()
        piholes.removeAll()
        resetNetwork()

        for connection in connections {
            Log.debug("Manager: Adding Connection: \(connection.hostname)")
            let api: any PiholeAPIProtocol
            switch connection.version {
            case .v6:
                api = Pihole6API(connection: connection)
            case .v5:
                api = PiholeAPI(connection: connection)
            }
            piholes[api.identifier] = Pihole(
                api: api,
                identifier: api.identifier,
                online: false,
                summary: nil,
                canBeManaged: false,
                enabled: nil
            )
        }

        Task {
            await updateAllPiholes()
            startPolling()
        }
    }

    private func resetNetwork() {
        networkOverview = PiholeNetworkOverview(
            networkStatus: .initializing,
            canBeManaged: false,
            totalQueriesToday: 0,
            adsBlockedToday: 0,
            adsPercentageToday: 0.0,
            averageBlocklist: 0,
            piholes: [:],
            hasIgnoredOfflinePiholes: false
        )
    }

    private func updateAllPiholes() async {
        Log.debug("Manager: Updating Pi-holes")

        await withTaskGroup(of: (String, Pihole).self) { group in
            for (id, pihole) in piholes {
                group.addTask {
                    return await (id, self.fetchUpdatedPihole(pihole))
                }
            }
            for await (id, updated) in group {
                piholes[id] = updated
            }
        }

        updateNetworkOverview()
    }

    private func fetchUpdatedPihole(_ pihole: Pihole) async -> Pihole {
        do {
            let summary = try await pihole.api.fetchSummary()
            let blocking = try await pihole.api.fetchBlockingStatus()
            return Pihole(
                api: pihole.api,
                identifier: pihole.identifier,
                online: true,
                summary: summary,
                canBeManaged: true,
                enabled: blocking
            )
        } catch {
            Log.error("Failed to update \(pihole.identifier): \(error)")
            return Pihole(
                api: pihole.api,
                identifier: pihole.identifier,
                online: false,
                summary: nil,
                canBeManaged: false,
                enabled: nil
            )
        }
    }

    private func updateNetworkOverview() {
        Log.debug("Updating Network Overview")

        networkOverview = PiholeNetworkOverview(
            networkStatus: networkStatus(),
            canBeManaged: canManage(),
            totalQueriesToday: networkTotalQueries(),
            adsBlockedToday: networkBlockedQueries(),
            adsPercentageToday: networkPercentageBlocked(),
            averageBlocklist: networkBlocklist(),
            piholes: piholes,
            hasIgnoredOfflinePiholes: hasIgnoredOfflinePiholes()
        )
    }

    private func networkTotalQueries() -> Int {
        activePiholes().reduce(0) { $0 + ($1.summary?.dnsQueriesToday ?? 0) }
    }

    private func networkBlockedQueries() -> Int {
        activePiholes().reduce(0) { $0 + ($1.summary?.adsBlockedToday ?? 0) }
    }

    private func networkPercentageBlocked() -> Double {
        let total = networkTotalQueries()
        let blocked = networkBlockedQueries()
        guard total > 0, blocked > 0 else { return 0.0 }
        return Double(blocked) / Double(total) * 100.0
    }

    private func networkBlocklist() -> Int {
        let counts = activePiholes().map { $0.summary?.domainsBeingBlocked ?? 0 }
        return counts.average()
    }

    private func networkStatus() -> PiholeNetworkStatus {
        if piholes.isEmpty { return .noneSet }

        let active = activePiholes()
        if active.isEmpty { return .offline }

        let summaries = active.compactMap(\.summary)
        if summaries.isEmpty { return .offline }
        if summaries.count < active.count { return .partiallyOffline }

        let statuses = Set(active.compactMap(\.enabled))
        if statuses.count == 1 {
            return statuses.first! ? .enabled : .disabled
        }
        return .partiallyEnabled
    }

    private func canManage() -> Bool {
        activePiholes().contains { $0.canBeManaged }
    }
}
