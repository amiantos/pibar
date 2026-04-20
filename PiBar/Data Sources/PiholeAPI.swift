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

        let (data, response) = try await InsecureURLSession.shared.data(for: request)

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

        let (data, response) = try await InsecureURLSession.shared.data(for: request)

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
