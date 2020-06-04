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

// PiBar v1.0 format
struct PiholeConnectionV1: Codable {
    let hostname: String
    let port: Int
    let useSSL: Bool
    let token: String
}

extension PiholeConnectionV1 {
    init?(data: Data) {
        let jsonDecoder = JSONDecoder()
        do {
            let object = try jsonDecoder.decode(PiholeConnectionV1.self, from: data)
            self = object
        } catch {
            Log.debug("Couldn't decode connection: \(error.localizedDescription)")
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

// PiBar v1.1 format
struct PiholeConnectionV2: Codable {
    let hostname: String
    let port: Int
    let useSSL: Bool
    let token: String
    let passwordProtected: Bool
    let adminPanelURL: String
}

extension PiholeConnectionV2 {
    init?(data: Data) {
        let jsonDecoder = JSONDecoder()
        do {
            let object = try jsonDecoder.decode(PiholeConnectionV2.self, from: data)
            self = object
        } catch {
            Log.debug("Couldn't decode connection: \(error.localizedDescription)")
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

    static func generateAdminPanelURL(hostname: String, port: Int, useSSL: Bool) -> String {
        let prefix: String = useSSL ? "https" : "http"
        return "\(prefix)://\(hostname):\(port)/admin/"
    }
}

enum PiholeConnectionTestResult {
    case success
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

struct PiholeOverTimeData: Decodable {
    let domainsOverTime: [String: Int]
    let adsOverTime: [String: Int]
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
    let overTimeData: PiholeOverTimeData?
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

    let overTimeData: PiholeNetworkOverTimeData?

    let piholes: [String: Pihole]
}

struct PiholeNetworkOverTimeData {
    let overview: [Double: (Double, Double)]
    let maximumValue: Double
    let piholes: [String: [Double: (Double, Double)]]
}
