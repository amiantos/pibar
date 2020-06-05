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

class PiBarManager: NSObject {
    private var piholes: [String: Pihole] = [:]

    private var networkOverview: PiholeNetworkOverview {
        didSet {
            delegate?.updateNetwork(networkOverview)
        }
    }

    private var timer: Timer?
    private var updateInterval: TimeInterval
    private let operationQueue: OperationQueue = OperationQueue()

    override init() {
        Log.logLevel = .debug
        Log.useEmoji = true

        operationQueue.maxConcurrentOperationCount = 1

        updateInterval = TimeInterval(Preferences.standard.pollingRate)

        networkOverview = PiholeNetworkOverview(
            networkStatus: .initializing,
            canBeManaged: false,
            totalQueriesToday: 0,
            adsBlockedToday: 0,
            adsPercentageToday: 0.0,
            averageBlocklist: 0,
            overTimeData: nil,
            piholes: [:]
        )
        super.init()

        delegate?.updateNetwork(networkOverview)

        loadConnections()
    }

    // MARK: - Public Variables and Functions

    weak var delegate: PiBarManagerDelegate?

    func loadConnections() {
        createPiholes(Preferences.standard.piholes)
    }

    func setPollingRate(to seconds: Int) {
        let newPollingRate = TimeInterval(seconds)
        if newPollingRate != updateInterval {
            Log.debug("Changed polling rate to: \(seconds)")
            updateInterval = newPollingRate
            startTimer()
        }
    }

    // Enable / Disable Pi-hole(s)

    func toggleNetwork() {
        if networkStatus() == .enabled || networkStatus() == .partiallyEnabled {
            disableNetwork()
        } else if networkStatus() == .disabled {
            enableNetwork()
        }
    }

    func disableNetwork(seconds: Int? = nil) {
        stopTimer()

        let completionOperation = BlockOperation {
            self.updatePiholes()
            self.startTimer()
        }
        piholes.values.forEach { pihole in
            let operation = ChangePiholeStatusOperation(pihole: pihole, status: .disable, seconds: seconds)
            completionOperation.addDependency(operation)
            operationQueue.addOperation(operation)
        }
        operationQueue.addOperation(completionOperation)
    }

    func enableNetwork() {
        stopTimer()

        let completionOperation = BlockOperation {
            self.updatePiholes()
            self.startTimer()
        }
        piholes.values.forEach { pihole in
            let operation = ChangePiholeStatusOperation(pihole: pihole, status: .enable)
            completionOperation.addDependency(operation)
            operationQueue.addOperation(operation)
        }
        operationQueue.addOperation(completionOperation)
    }

    // MARK: - Private Functions

    // MARK: Timer

    private func startTimer() {
        stopTimer()

        let newTimer = Timer(timeInterval: updateInterval, target: self, selector: #selector(updatePiholes), userInfo: nil, repeats: true)
        newTimer.tolerance = 0.2
        RunLoop.main.add(newTimer, forMode: .common)

        timer = newTimer

        Log.debug("Manager: Timer Started")
    }

    private func stopTimer() {
        if let existingTimer = timer {
            Log.debug("Manager: Timer Stopped")
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
            overTimeData: nil,
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
                overTimeData: nil,
                canBeManaged: nil,
                enabled: nil
            )
        }

        updatePiholes()

        startTimer()
    }

    @objc private func updatePiholes() {
        Log.debug("Manager: Updating Pi-holes")

        let completionOperation = BlockOperation {
            // If we don't sleep here we run into some weird timing issues with dictionaries
            sleep(1)
            self.updateNetworkOverview()
        }

        for pihole in piholes.values {
            Log.debug("Creating operation for \(pihole.identifier)")
            let operation = UpdatePiholeOperation(pihole)
            operation.completionBlock = { [unowned operation] in
                self.piholes[pihole.identifier] = operation.pihole
            }
            completionOperation.addDependency(operation)
            operationQueue.addOperation(operation)
        }

        operationQueue.addOperation(completionOperation)
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
            overTimeData: generateNetworkOverTimeData(),
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

    private func generateNetworkOverTimeData() -> PiholeNetworkOverTimeData? {
        if piholes.isEmpty {
            return nil
        }

        var piholesOverTimeData: [String: [Double: (Double, Double)]] = [:]

        for (identifier, pihole) in piholes {
            piholesOverTimeData[identifier] = normalizeOverTimeData(pihole)
        }

        var overview: [Double: (Double, Double)] = [:]

        var hours: Set<Double> = []
        for identifier in piholes.keys {
            guard let data = piholesOverTimeData[identifier] else { continue }
            hours = hours.union(data.keys)
        }

        var maximumHourlyValue: Double = 0.0

        for hour in hours {
            var summedData: (Double, Double) = (0, 0)
            for identifier in piholes.keys {
                guard let data = piholesOverTimeData[identifier] else { continue }
                let queryData: (Double, Double) = data[hour] ?? (0, 0)
                summedData = (summedData.0 + queryData.0, summedData.1 + queryData.1)

                let hourlyTotalQueries: Double = summedData.0 + summedData.1
                maximumHourlyValue = hourlyTotalQueries > maximumHourlyValue ? hourlyTotalQueries : maximumHourlyValue
            }
            overview[hour] = summedData
        }

        return PiholeNetworkOverTimeData(
            overview: overview,
            maximumValue: maximumHourlyValue,
            piholes: piholesOverTimeData
        )
    }

    private func normalizeOverTimeData(_ pihole: Pihole) -> [Double: (Double, Double)] {
        var overTimeData: [Double: (Double, Double)] = [:]
        if let domainsOverTime = pihole.overTimeData?.domainsOverTime,
            let adsOverTime = pihole.overTimeData?.adsOverTime {
            var hour: Double = 0
            var batchCount: Int = 0
            var summedDomains: Double = 0.0
            var summedAds: Double = 0.0

            let sorted = domainsOverTime.sorted { $0.key < $1.key }

            for (key, value) in sorted {
                if batchCount < 5 {
                    summedDomains += Double(value)
                    summedAds += Double(adsOverTime[key] ?? 0)
                    batchCount += 1
                } else {
                    overTimeData[hour] = (summedDomains, summedAds)
                    hour += 1
                    summedDomains = 0
                    summedAds = 0
                    batchCount = 0
                }
            }
            if !summedDomains.isZero || !summedAds.isZero {
                overTimeData[hour] = (summedDomains, summedAds)
            }
        }

        return overTimeData
    }
}
