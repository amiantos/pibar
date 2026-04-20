//
//  Pihole6API.swift
//  PiBar
//
//  Created by Brad Root on 5/17/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

class Pihole6API: PiholeAPIProtocol {
    let connection: PiholeConnection

    var identifier: String {
        return connection.hostname
    }

    var adminURL: URL? {
        URL(string: connection.adminPanelURL)
    }

    private let basePath = "/api"
    private let userAgent = "PiBar:1.2:https://github.com/amiantos/pibar"

    /// Current session ID — transient, not persisted
    private var sid: String?

    /// Saved password for auto-refresh (loaded from Keychain if savePassword is true)
    private var savedPassword: String?

    init(connection: PiholeConnection) {
        self.connection = connection

        // Load the SID if one was stored during setup (token field)
        self.sid = connection.token

        // Load saved password for auto-refresh
        if connection.savePassword {
            self.savedPassword = KeychainService.load(account: "\(connection.id.uuidString)-password")
        }
    }

    // MARK: - Authentication

    func authenticate(password: String, totp: Int? = nil) async throws -> PiholeV6Session {
        let response: PiholeV6PasswordResponse = try await post(
            "/auth",
            body: PiholeV6PasswordRequest(password: password, totp: totp)
        )
        if response.session.valid, let newSID = response.session.sid {
            self.sid = newSID
        }
        return response.session
    }

    /// Save password to Keychain for auto-refresh
    func savePasswordForRefresh(_ password: String) {
        self.savedPassword = password
        _ = KeychainService.save(password: password, forAccount: "\(connection.id.uuidString)-password")
    }

    // MARK: - PiholeAPIProtocol

    func fetchSummary() async throws -> PiholeAPISummary {
        let raw: Pihole6APISummary = try await authenticatedGet("/stats/summary")
        return PiholeAPISummary(
            domainsBeingBlocked: raw.gravity.domainsBeingBlocked,
            dnsQueriesToday: raw.queries.total,
            adsBlockedToday: raw.queries.blocked,
            adsPercentageToday: raw.queries.percentBlocked,
            status: "enabled" // v6 doesn't include status in summary, we check blocking separately
        )
    }

    func fetchBlockingStatus() async throws -> Bool {
        let status: Pihole6APIBlockingStatus = try await authenticatedGet("/dns/blocking")
        return status.blocking == "enabled"
    }

    func enable() async throws {
        let _: Pihole6APIBlockingStatus = try await authenticatedPost(
            "/dns/blocking",
            body: PiholeV6BlockingRequest(blocking: true, timer: nil)
        )
    }

    func disable(seconds: Int?) async throws {
        let _: Pihole6APIBlockingStatus = try await authenticatedPost(
            "/dns/blocking",
            body: PiholeV6BlockingRequest(blocking: false, timer: seconds)
        )
    }

    // MARK: - Authenticated requests with auto-refresh

    private func authenticatedGet<T: Decodable>(_ path: String) async throws -> T {
        do {
            return try await get(path, apiKey: sid)
        } catch APIError.invalidResponse(let statusCode, _) where statusCode == 401 {
            try await refreshSession()
            return try await get(path, apiKey: sid)
        } catch APIError.requestFailed(let inner) {
            if let apiError = inner as? APIError,
               case .invalidResponse(let code, _) = apiError, code == 401 {
                try await refreshSession()
                return try await get(path, apiKey: sid)
            }
            throw APIError.requestFailed(inner)
        }
    }

    private func authenticatedPost<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        do {
            return try await post(path, apiKey: sid, body: body)
        } catch APIError.invalidResponse(let statusCode, _) where statusCode == 401 {
            try await refreshSession()
            return try await post(path, apiKey: sid, body: body)
        } catch APIError.requestFailed(let inner) {
            if let apiError = inner as? APIError,
               case .invalidResponse(let code, _) = apiError, code == 401 {
                try await refreshSession()
                return try await post(path, apiKey: sid, body: body)
            }
            throw APIError.requestFailed(inner)
        }
    }

    private func refreshSession() async throws {
        guard let password = savedPassword else {
            throw APIError.authenticationRequired
        }
        let session = try await authenticate(password: password)
        if !session.valid {
            throw APIError.authenticationRequired
        }
    }

    // MARK: - Low-level HTTP

    private var baseURL: String {
        let prefix = connection.useSSL ? "https" : "http"
        return "\(prefix)://\(connection.hostname):\(connection.port)\(basePath)"
    }

    private func buildRequest(
        for url: URL, method: String = "GET", apiKey: String? = nil, body: Encodable? = nil
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
        } else {
            request.timeoutInterval = 5
        }
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await InsecureURLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300 ~= httpResponse.statusCode) {
            throw APIError.invalidResponse(
                statusCode: httpResponse.statusCode,
                content: String(data: data, encoding: .utf8) ?? ""
            )
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    private func get<T: Decodable>(_ path: String, apiKey: String? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        let request = buildRequest(for: url, apiKey: apiKey)
        return try await perform(request)
    }

    private func post<T: Decodable>(_ path: String, apiKey: String? = nil, body: Encodable? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        let request = buildRequest(for: url, method: "POST", apiKey: apiKey, body: body)
        return try await perform(request)
    }
}
