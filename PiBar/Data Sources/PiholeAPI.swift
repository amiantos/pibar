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

import Foundation

class PiholeAPI: PiholeAPIProtocol {
    let connection: PiholeConnection

    var identifier: String {
        return connection.hostname
    }

    var adminURL: URL? {
        URL(string: connection.adminPanelURL)
    }

    private let basePath = "/admin/api.php"

    init(connection: PiholeConnection) {
        self.connection = connection
    }

    // MARK: - PiholeAPIProtocol

    func fetchSummary() async throws -> PiholeAPISummary {
        let raw: PiholeV5APISummary = try await get(query: "summaryRaw")
        return PiholeAPISummary(
            domainsBeingBlocked: raw.domainsBeingBlocked,
            dnsQueriesToday: raw.dnsQueriesToday,
            adsBlockedToday: raw.adsBlockedToday,
            adsPercentageToday: raw.adsPercentageToday,
            status: raw.status
        )
    }

    func fetchBlockingStatus() async throws -> Bool {
        let summary = try await fetchSummary()
        return summary.status == "enabled"
    }

    func enable() async throws {
        let _: PiholeAPIStatus = try await get(query: "enable")
    }

    func disable(seconds: Int?) async throws {
        var query = "disable"
        if let seconds {
            query += "=\(seconds)"
        }
        let _: PiholeAPIStatus = try await get(query: query)
    }

    // MARK: - Queries & Domain Management

    func fetchRecentQueries(count: Int) async throws -> [PiholeQuery] {
        let response: PiholeV5QueriesResponse = try await get(query: "getAllQueries=\(count)")
        return response.data.compactMap { row -> PiholeQuery? in
            // row format: [timestamp, type, domain, client, status, ...]
            guard row.count >= 5 else { return nil }
            let timestampInt = Double(row[0]) ?? 0
            let domain = row[2]
            let client = row[3]
            let statusCode = Int(row[4]) ?? 0
            // Status 1=forwarded, 2=cache, 3=blocked(gravity), 4+=blocked(other)
            let blocked = statusCode >= 3
            return PiholeQuery(
                domain: domain,
                timestamp: Date(timeIntervalSince1970: timestampInt),
                blocked: blocked,
                client: client,
                piholeIdentifier: identifier
            )
        }
    }

    func addToAllowList(domain: String) async throws {
        let (resolvedDomain, list) = Self.resolveWildcard(domain, allow: true)
        let _ = try await getRaw(query: "list=\(list)&add=\(resolvedDomain)")
    }

    func addToDenyList(domain: String) async throws {
        let (resolvedDomain, list) = Self.resolveWildcard(domain, allow: false)
        let _ = try await getRaw(query: "list=\(list)&add=\(resolvedDomain)")
    }

    /// Determines if domain should be added as exact or regex.
    /// Converts wildcard (*.example.com) to regex format.
    /// Passes through raw regex as-is.
    private static func resolveWildcard(_ domain: String, allow: Bool) -> (String, String) {
        let isRegex: Bool
        if domain.hasPrefix("*.") {
            let base = String(domain.dropFirst(2))
            let escaped = NSRegularExpression.escapedPattern(for: base)
            let regex = "(\\.|^)\(escaped)$"
            return (regex, allow ? "regex_white" : "regex_black")
        }
        isRegex = domain.contains("(") || domain.contains("[") || domain.contains("\\") ||
            domain.contains("^") || domain.contains("$") || domain.contains("|") ||
            domain.contains("+") || domain.contains("?") || domain.contains("{")
        if isRegex {
            return (domain, allow ? "regex_white" : "regex_black")
        }
        return (domain, allow ? "white" : "black")
    }

    // MARK: - Testing

    func testConnection() async throws -> Bool {
        let result: String = try await getRaw(query: "topItems")
        return result != "[]"
    }

    // MARK: - Private

    private var baseURL: String {
        let prefix = connection.useSSL ? "https" : "http"
        return "\(prefix)://\(connection.hostname):\(connection.port)\(basePath)"
    }

    private func get<T: Decodable>(query: String) async throws -> T {
        let token = connection.token ?? ""
        let urlString = "\(baseURL)?auth=\(token)&\(query)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300 ~= httpResponse.statusCode) {
            throw APIError.invalidResponse(
                statusCode: httpResponse.statusCode,
                content: String(data: data, encoding: .utf8) ?? ""
            )
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    private func getRaw(query: String) async throws -> String {
        let token = connection.token ?? ""
        let urlString = "\(baseURL)?auth=\(token)&\(query)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300 ~= httpResponse.statusCode) {
            throw APIError.invalidResponse(
                statusCode: httpResponse.statusCode,
                content: String(data: data, encoding: .utf8) ?? ""
            )
        }

        return String(data: data, encoding: .utf8) ?? ""
    }
}
