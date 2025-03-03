//
//  PiholeAPI.swift
//  PiBar
//
//  Created by Brad Root on 5/17/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa

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

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse(statusCode: Int, content: String)
    case decodingFailed
    case requestTimedOut
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

struct Pihole6APIEndpoint {
    let path: String
    let authorizationRequired: Bool
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

class Pihole6API: NSObject {
    let connection: PiholeConnectionV3

    var identifier: String {
        return "\(connection.hostname)"
    }

    private let path: String = "/api"
    private let timeout: Int = 2

    override init() {
        connection = PiholeConnectionV3(
            hostname: "pi.hole",
            port: 80,
            useSSL: false,
            token: "",
            passwordProtected: true,
            adminPanelURL: "http://pi.hole/admin/",
            isV6: true
        )
        super.init()
    }

    init(connection: PiholeConnectionV3) {
        self.connection = connection
        super.init()
    }

    // MARK: - URLs

    private var baseURL: String {
        let prefix = connection.useSSL ? "https" : "http"
        return "\(prefix)://\(connection.hostname):\(connection.port)\(path)"
    }
    
    var userAgent: String = "PiBar:1.2:https://github.com/amiantos/pibar"

    var admin: URL {
        return URL(string: "http://\(connection.hostname):\(connection.port)/admin")!
    }
    
    func checkPassword(password: String, totp: Int?) async throws -> PiholeV6PasswordResponse {
        do {
            return try await post("/auth", responseType: PiholeV6PasswordResponse.self, body: PiholeV6PasswordRequest(password: password, totp: totp))
        } catch URLError.timedOut {
            throw APIError.requestTimedOut
        }
    }
    
    func fetchSummary() async throws -> Pihole6APISummary {
        do {
            return try await get("/stats/summary", responseType: Pihole6APISummary.self, apiKey: connection.token)
        }
    }
    
    func fetchBlockingStatus() async throws -> Pihole6APIBlockingStatus {
        do {
            return try await get("/dns/blocking", responseType: Pihole6APIBlockingStatus.self, apiKey: connection.token)
        }
    }
    
    func disable(seconds: Int?) async throws -> Pihole6APIBlockingStatus {
        do {
            return try await post("/dns/blocking", responseType: Pihole6APIBlockingStatus.self, apiKey: connection.token, body: PiholeV6BlockingRequest(blocking: false, timer: seconds))
        }
    }
    
    func enable() async throws -> Pihole6APIBlockingStatus {
        do {
            return try await post("/dns/blocking", responseType: Pihole6APIBlockingStatus.self, apiKey: connection.token, body: PiholeV6BlockingRequest(blocking: true, timer: nil))
        }
    }
    
    // Ugly Innards

    private func request(
        for url: URL, method: String = "GET", apiKey: String? = nil,
        body: Encodable? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if let apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "sid")
        }
        if let body {
            request.httpBody = try? JSONEncoder().encode(body)
            request.timeoutInterval = 5
        }
        return request
    }

    private func perform<T: Decodable>(
        _ request: URLRequest, responseType _: T.Type
    ) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(
                for: request)
            if let response = response as? HTTPURLResponse,
                !((200..<300) ~= response.statusCode)
            {
                throw APIError.invalidResponse(
                    statusCode: response.statusCode,
                    content: String(
                        describing: String(data: data, encoding: .utf8)))
            }
            do {
//                Log.debug(String(data: data, encoding: .utf8) ?? "No data")
                let decodedResponse = try JSONDecoder().decode(
                    T.self, from: data)
                return decodedResponse
            } catch {
                throw APIError.decodingFailed
            }
        } catch {
            throw APIError.requestFailed(error)
        }
    }

    private func get<T: Decodable>(
        _ path: String, responseType: T.Type, apiKey: String? = nil
    ) async throws -> T {
        do {
            let request = request(
                for: URL(string: "\(baseURL)\(path)")!, apiKey: apiKey)
            return try await perform(request, responseType: T.self)
        } catch {
            throw APIError.requestFailed(error)
        }
    }

    private func post<T: Decodable>(
        _ path: String, responseType: T.Type, apiKey: String? = nil,
        body: Encodable? = nil
    ) async throws -> T {
        do {
            let request = request(
                for: URL(string: "\(baseURL)\(path)")!, method: "POST",
                apiKey: apiKey, body: body)
            return try await perform(request, responseType: T.self)
        } catch {
            throw APIError.requestFailed(error)
        }
    }

}
