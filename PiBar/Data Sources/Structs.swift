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
import KeychainAccess

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

// PiBar v1.2 format
struct PiholeConnectionV3: Codable, Copyable {
    let hostname: String
    let port: Int
    let useSSL: Bool
    var token: String
    let passwordProtected: Bool
    let adminPanelURL: String
    let isV6: Bool
}

extension PiholeConnectionV3 {
    
    private var keychainIdentifier: String? {
        get {
            if self.hostname.count > 0 {
                return "apitoken.\(self.hostname):\(self.port)"
            }
            return nil
        }
    }
    
    init?(data: Data) {
        let jsonDecoder = JSONDecoder()
        do {
            var object = try jsonDecoder.decode(PiholeConnectionV3.self, from: data)
            // load the token from the Keychain and add it to the connection object:
            if let bundleIdentifier = Bundle.main.bundleIdentifier, let keychainIdentifier = object.keychainIdentifier {
                let keychain = Keychain(service: bundleIdentifier, accessGroup: nil)
                if let tokenStr = keychain[keychainIdentifier], !tokenStr.isEmpty {
                    object.token = tokenStr
                }
            }
            self = object
        } catch {
            Log.debug("Couldn't decode connection: \(error.localizedDescription)")
            return nil
        }
    }
    
    func encode() -> Data? {
        let jsonEncoder = JSONEncoder()
        // make sure the token is being securely stored to the Keychain only, and nowhere else
        var copySelf = self.copy() as! PiholeConnectionV3
        if let bundleIdentifier = Bundle.main.bundleIdentifier, !copySelf.token.isEmpty, let keychainIdentifier = copySelf.keychainIdentifier {
            let keychain = Keychain(service: bundleIdentifier, accessGroup: nil)
            keychain[keychainIdentifier] = copySelf.token
            copySelf.token = ""
        }
        if let data = try? jsonEncoder.encode(copySelf) {
            return data
        } else {
            return nil
        }
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = PiholeConnectionV3(hostname: hostname, port: port, useSSL: useSSL, token: token, passwordProtected: passwordProtected, adminPanelURL: adminPanelURL, isV6: isV6)
        return copy
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
    let api: PiholeAPI?
    let api6: Pihole6API?
    let identifier: String
    let online: Bool
    let summary: PiholeAPISummary?
    let canBeManaged: Bool?
    let enabled: Bool?
    let isV6: Bool

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
