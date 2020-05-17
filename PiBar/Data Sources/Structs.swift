//
//  Structs.swift
//  PiBar
//
//  Created by Brad Root on 5/18/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

// MARK: - Pi-hole Connections

struct PiholeConnection: Codable {
    let hostname: String
    let port: Int
    let useSSL: Bool
    let token: String
}

extension PiholeConnection {
    init?(data: Data) {
        let jsonDecoder = JSONDecoder()
        if let object = try? jsonDecoder.decode(PiholeConnection.self, from: data) {
            self = object
        } else {
            return nil
        }
    }

    func encode() -> Data? {
        let jsonEncoder = JSONEncoder()
        if let data = try? jsonEncoder.encode(self) {
            return data
        } else {
            return nil
        }
    }
}

enum PiholeConnectionTestResult {
    case success
    case successNoToken
    case failure
    case failureInvalidToken
}

// MARK: - Pi-hole API

struct PiholeAPIEndpoint {
    let queryParameter: String
    let authorizationRequired: Bool
}

struct PiholeAPISummary: Decodable {
    let domainsBeingBlocked: Int
    let dnsQueriesToday: Int
    let adsBlockedToday: Int
    let adsPercentageToday: Double
    let uniqueDomains: Int
    let queriesForwarded: Int
    let queriesCached: Int
    let uniqueClients: Int
    let dnsQueriesAllTypes: Int
    let status: String
}

struct PiholeAPIStatus: Decodable {
    let status: String
}

// MARK: - Pi-hole Network

enum PiholeNetworkStatus: String {
    case enabled = "Enabled"
    case disabled = "Disabled"
    case partiallyEnabled = "Partially Enabled"
    case offline = "Offline"
    case partiallyOffline = "Partially Offline"
    case noneSet = "No Pi-holes"
    case initializing = "Initializing"
}

struct Pihole {
    let api: PiholeAPI
    let identifier: String
    let online: Bool
    let summary: PiholeAPISummary?
    let canBeManaged: Bool?
    let enabled: Bool?

    var status: PiholeNetworkStatus {
        if !online {
            return .offline
        }
        if let enabled = enabled {
            if enabled {
                return .enabled
            }
            return .disabled
        }
        return .initializing
    }
}

struct PiholeNetworkOverview {
    let networkStatus: PiholeNetworkStatus
    let canBeManaged: Bool
    let totalQueriesToday: Int
    let adsBlockedToday: Int
    let adsPercentageToday: Double
    let averageBlocklist: Int

    let piholes: [String: Pihole]
}
