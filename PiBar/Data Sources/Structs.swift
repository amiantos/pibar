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

// MARK: - Pi-hole Version

enum PiholeVersion: String, Codable {
    case v5
    case v6
}

// MARK: - Pi-hole Connection (v2.0 format)

struct PiholeConnection: Codable, Identifiable, Hashable {
    static func == (lhs: PiholeConnection, rhs: PiholeConnection) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: UUID
    var hostname: String
    var port: Int
    var useSSL: Bool
    var version: PiholeVersion
    var passwordProtected: Bool
    var adminPanelURL: String
    var savePassword: Bool
    var requiresTOTP: Bool
    var ignoreWhenOffline: Bool

    init(
        id: UUID,
        hostname: String,
        port: Int,
        useSSL: Bool,
        version: PiholeVersion,
        passwordProtected: Bool,
        adminPanelURL: String,
        savePassword: Bool,
        requiresTOTP: Bool,
        ignoreWhenOffline: Bool = false
    ) {
        self.id = id
        self.hostname = hostname
        self.port = port
        self.useSSL = useSSL
        self.version = version
        self.passwordProtected = passwordProtected
        self.adminPanelURL = adminPanelURL
        self.savePassword = savePassword
        self.requiresTOTP = requiresTOTP
        self.ignoreWhenOffline = ignoreWhenOffline
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        hostname = try c.decode(String.self, forKey: .hostname)
        port = try c.decode(Int.self, forKey: .port)
        useSSL = try c.decode(Bool.self, forKey: .useSSL)
        version = try c.decode(PiholeVersion.self, forKey: .version)
        passwordProtected = try c.decode(Bool.self, forKey: .passwordProtected)
        adminPanelURL = try c.decode(String.self, forKey: .adminPanelURL)
        savePassword = try c.decode(Bool.self, forKey: .savePassword)
        requiresTOTP = try c.decode(Bool.self, forKey: .requiresTOTP)
        ignoreWhenOffline = try c.decodeIfPresent(Bool.self, forKey: .ignoreWhenOffline) ?? false
    }

    var token: String? {
        KeychainService.load(account: id.uuidString)
    }

    func saveToken(_ token: String) {
        _ = KeychainService.save(password: token, forAccount: id.uuidString)
    }

    func deleteToken() {
        KeychainService.delete(account: id.uuidString)
        KeychainService.delete(account: "\(id.uuidString)-password")
    }

    func deleteSavedPassword() {
        KeychainService.delete(account: "\(id.uuidString)-password")
    }

    static func generateAdminPanelURL(hostname: String, port: Int, useSSL: Bool) -> String {
        let prefix = useSSL ? "https" : "http"
        return "\(prefix)://\(hostname):\(port)/admin/"
    }
}

// MARK: - Legacy Connection Models (for migration)

struct PiholeConnectionV1: Codable {
    let hostname: String
    let port: Int
    let useSSL: Bool
    let token: String
}

struct PiholeConnectionV2: Codable {
    let hostname: String
    let port: Int
    let useSSL: Bool
    let token: String
    let passwordProtected: Bool
    let adminPanelURL: String
}

struct PiholeConnectionV3: Codable {
    let hostname: String
    let port: Int
    let useSSL: Bool
    let token: String
    let passwordProtected: Bool
    let adminPanelURL: String
    let isV6: Bool
}

// MARK: - Pi-hole API Protocol

protocol PiholeAPIProtocol: AnyObject {
    var identifier: String { get }
    var connection: PiholeConnection { get }
    var adminURL: URL? { get }
    func fetchSummary() async throws -> PiholeAPISummary
    func fetchBlockingStatus() async throws -> Bool
    func enable() async throws
    func disable(seconds: Int?) async throws
}

// MARK: - Unified Summary

struct PiholeAPISummary {
    let domainsBeingBlocked: Int
    let dnsQueriesToday: Int
    let adsBlockedToday: Int
    let adsPercentageToday: Double
    let status: String
}

// MARK: - Pi-hole v5 API Response Models

struct PiholeV5APISummary: Decodable {
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

// MARK: - Pi-hole v6 API Response Models

struct Pihole6APISummary: Decodable {
    let queries: Queries
    let clients: Clients
    let gravity: Gravity
    let took: Double
}

struct Queries: Decodable {
    let total: Int
    let blocked: Int
    let percentBlocked: Double
    let uniqueDomains: Int
    let forwarded: Int
    let cached: Int
    let frequency: Double
    let types: QueryTypes
    let status: QueryStatus
    let replies: QueryReplies

    enum CodingKeys: String, CodingKey {
        case total, blocked, forwarded, cached, frequency, types, status, replies
        case percentBlocked = "percent_blocked"
        case uniqueDomains = "unique_domains"
    }
}

struct QueryTypes: Decodable {
    let A: Int
    let AAAA: Int
    let ANY: Int
    let SRV: Int
    let SOA: Int
    let PTR: Int
    let TXT: Int
    let NAPTR: Int
    let MX: Int
    let DS: Int
    let RRSIG: Int
    let DNSKEY: Int
    let NS: Int
    let SVCB: Int
    let HTTPS: Int
    let OTHER: Int
}

struct QueryStatus: Decodable {
    let UNKNOWN: Int
    let GRAVITY: Int
    let FORWARDED: Int
    let CACHE: Int
    let REGEX: Int
    let DENYLIST: Int
    let EXTERNAL_BLOCKED_IP: Int
    let EXTERNAL_BLOCKED_NULL: Int
    let EXTERNAL_BLOCKED_NXRA: Int
    let GRAVITY_CNAME: Int
    let REGEX_CNAME: Int
    let DENYLIST_CNAME: Int
    let RETRIED: Int
    let RETRIED_DNSSEC: Int
    let IN_PROGRESS: Int
    let DBBUSY: Int
    let SPECIAL_DOMAIN: Int
    let CACHE_STALE: Int
    let EXTERNAL_BLOCKED_EDE15: Int
}

struct QueryReplies: Decodable {
    let UNKNOWN: Int
    let NODATA: Int
    let NXDOMAIN: Int
    let CNAME: Int
    let IP: Int
    let DOMAIN: Int
    let RRNAME: Int
    let SERVFAIL: Int
    let REFUSED: Int
    let NOTIMP: Int
    let OTHER: Int
    let DNSSEC: Int
    let NONE: Int
    let BLOB: Int
}

struct Clients: Decodable {
    let active: Int
    let total: Int
}

struct Gravity: Decodable {
    let domainsBeingBlocked: Int
    let lastUpdate: Int

    enum CodingKeys: String, CodingKey {
        case domainsBeingBlocked = "domains_being_blocked"
        case lastUpdate = "last_update"
    }
}

struct PiholeV6Session: Decodable {
    let valid: Bool
    let totp: Bool
    let sid: String?
    let csrf: String?
    let validity: Int
    let message: String?
}

struct PiholeV6PasswordResponse: Decodable {
    let session: PiholeV6Session
    let took: Double
}

struct PiholeV6PasswordRequest: Encodable {
    let password: String
    let totp: Int?
}

struct Pihole6APIBlockingStatus: Decodable {
    let blocking: String
    let timer: Double?
    let took: Double
}

struct PiholeV6BlockingRequest: Encodable {
    let blocking: Bool
    let timer: Int?
}

// MARK: - API Error

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse(statusCode: Int, content: String)
    case decodingFailed
    case requestTimedOut
    case authenticationRequired
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
    let api: any PiholeAPIProtocol
    let identifier: String
    let online: Bool
    let summary: PiholeAPISummary?
    let canBeManaged: Bool
    let enabled: Bool?

    var status: PiholeNetworkStatus {
        if !online {
            return .offline
        }
        if let enabled = enabled {
            return enabled ? .enabled : .disabled
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
    let hasIgnoredOfflinePiholes: Bool
}

// MARK: - Detection

struct DetectionResult {
    let port: Int
    let useSSL: Bool
    let version: PiholeVersion
    let passwordRequired: Bool
    let totpRequired: Bool
}

