//
//  UpdatePiholeV6Operation.swift
//  PiBar
//
//  Created by Brad Root on 3/16/25.
//  Copyright © 2025 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

final class UpdatePiholeV6Operation: AsyncOperation, @unchecked Sendable {
    private(set) var pihole: Pihole

    init(_ pihole: Pihole) {
        self.pihole = pihole
    }

    override func main() {
        Log.debug("Updating Pi-hole: \(pihole.identifier)")
        Task {
            var enabled: Bool? = true
            var online = true
            var canBeManaged: Bool = true
            
            do {
                let result = try await pihole.api6!.fetchSummary()
                let blockingResult = try await pihole.api6!.fetchBlockingStatus()
                
                Log.debug("Blocking result \(blockingResult)")
                
                if blockingResult.blocking != "enabled" {
                    enabled = false
                }
                
                let newSummary = PiholeAPISummary(domainsBeingBlocked: result.gravity.domainsBeingBlocked, dnsQueriesToday: result.queries.total, adsBlockedToday: result.queries.blocked, adsPercentageToday: result.queries.percentBlocked, uniqueDomains: result.queries.uniqueDomains, queriesForwarded: result.queries.forwarded, queriesCached: result.queries.cached, uniqueClients: result.clients.active, dnsQueriesAllTypes: 0, status: blockingResult.blocking)
                
                let updatedPihole: Pihole = Pihole(
                    api: nil,
                    api6: self.pihole.api6!,
                    identifier: self.pihole.identifier,
                    online: online,
                    summary: newSummary,
                    canBeManaged: canBeManaged,
                    enabled: enabled,
                    isV6: true
                )
                self.pihole = updatedPihole
            } catch {
                Log.error(error)
                let updatedPihole: Pihole = Pihole(
                    api: nil,
                    api6: self.pihole.api6!,
                    identifier: self.pihole.identifier,
                    online: false,
                    summary: nil,
                    canBeManaged: false,
                    enabled: nil,
                    isV6: true
                )
                self.pihole = updatedPihole
            }
            self.state = .isFinished
        }
            
//            let updatedPihole: Pihole = Pihole(
//                api: self.pihole.api!,
//                api6: nil,
//                identifier: self.pihole.api!.identifier,
//                online: online,
//                summary: summary,
//                canBeManaged: canBeManaged,
//                enabled: enabled, isV6: false
//            )
//
//            self.pihole = updatedPihole
//
//            self.state = .isFinished
//        pihole.api!.fetchSummary { summary in
//            Log.debug("Received Summary for \(self.pihole.identifier)")
//            var enabled: Bool? = true
//            var online = true
//            var canBeManaged: Bool = false
//
//            if let summary = summary {
//                if summary.status != "enabled" {
//                    enabled = false
//                }
//                if !self.pihole.api!.connection.token.isEmpty || !self.pihole.api!.connection.passwordProtected {
//                    canBeManaged = true
//                }
//            } else {
//                enabled = nil
//                online = false
//                canBeManaged = false
//            }
//
//            let updatedPihole: Pihole = Pihole(
//                api: self.pihole.api!,
//                api6: nil,
//                identifier: self.pihole.api!.identifier,
//                online: online,
//                summary: summary,
//                canBeManaged: canBeManaged,
//                enabled: enabled, isV6: false
//            )
//
//            self.pihole = updatedPihole
//
//            self.state = .isFinished
//        }
    }
}
