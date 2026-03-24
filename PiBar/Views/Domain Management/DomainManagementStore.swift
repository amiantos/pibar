//
//  DomainManagementStore.swift
//  PiBar
//
//  Created by Brad Root on 3/24/26.
//  Copyright © 2026 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Observation

@Observable
class DomainManagementStore {
    var blockedDomains: [DomainEntry] = []
    var allowedDomains: [DomainEntry] = []
    var isLoading = false
    var errorMessage: String?
    var actionMessage: String?
    var manualDomain: String = ""

    private let manager: PiBarManager

    init(manager: PiBarManager) {
        self.manager = manager
    }

    func loadQueries() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let queries = await manager.fetchAllRecentQueries(count: 100)

        // Group by domain and blocked status
        var blockedCounts: [String: (count: Int, lastSeen: Date)] = [:]
        var allowedCounts: [String: (count: Int, lastSeen: Date)] = [:]

        for query in queries {
            if query.blocked {
                let existing = blockedCounts[query.domain]
                blockedCounts[query.domain] = (
                    count: (existing?.count ?? 0) + 1,
                    lastSeen: max(existing?.lastSeen ?? .distantPast, query.timestamp)
                )
            } else {
                let existing = allowedCounts[query.domain]
                allowedCounts[query.domain] = (
                    count: (existing?.count ?? 0) + 1,
                    lastSeen: max(existing?.lastSeen ?? .distantPast, query.timestamp)
                )
            }
        }

        blockedDomains = blockedCounts.map { domain, info in
            DomainEntry(domain: domain, queryCount: info.count, lastSeen: info.lastSeen)
        }.sorted { $0.queryCount > $1.queryCount }

        allowedDomains = allowedCounts.map { domain, info in
            DomainEntry(domain: domain, queryCount: info.count, lastSeen: info.lastSeen)
        }.sorted { $0.queryCount > $1.queryCount }
    }

    func addToAllowList(domain: String) async {
        actionMessage = nil
        let errors = await manager.addToAllowListOnAll(domain: domain)
        if errors.isEmpty {
            actionMessage = "Added \(domain) to allow list."
        } else {
            actionMessage = "Errors: \(errors.joined(separator: ", "))"
        }
        await loadQueries()
    }

    func addToDenyList(domain: String) async {
        actionMessage = nil
        let errors = await manager.addToDenyListOnAll(domain: domain)
        if errors.isEmpty {
            actionMessage = "Added \(domain) to deny list."
        } else {
            actionMessage = "Errors: \(errors.joined(separator: ", "))"
        }
        await loadQueries()
    }
}
