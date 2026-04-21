//
//  PiholeDetectionService.swift
//  PiBar
//
//  Created by Brad Root on 3/23/26.
//  Copyright © 2026 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

enum DetectionError: Error, LocalizedError {
    case unreachable
    case notPihole
    case timeout

    var errorDescription: String? {
        switch self {
        case .unreachable: return "Could not connect to the host."
        case .notPihole: return "No Pi-hole installation was detected."
        case .timeout: return "Connection timed out."
        }
    }
}

/// Delegate that accepts self-signed certificates only for local-network Pi-holes
/// (localhost, *.local, or RFC1918 addresses). All other hosts fall through to
/// default trust evaluation so remote targets still get real cert validation.
class InsecureSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        if Self.isLocalHost(challenge.protectionSpace.host) {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    static func isLocalHost(_ host: String) -> Bool {
        let lower = host.lowercased()
        if lower == "localhost" || lower.hasSuffix(".local") { return true }
        let parts = lower.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4, parts.allSatisfy({ (0...255).contains($0) }) else { return false }
        if parts[0] == 10 { return true }
        if parts[0] == 192 && parts[1] == 168 { return true }
        if parts[0] == 172 && (16...31).contains(parts[1]) { return true }
        return false
    }
}

/// Shared URLSession that accepts self-signed certificates for local-network hosts.
/// Used by detection and by the v5/v6 API clients so a Pi-hole on a private IP
/// with a self-signed cert works end-to-end. Remote hosts still get default trust.
enum InsecureURLSession {
    private static let delegate = InsecureSessionDelegate()

    static let shared: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }()

    /// Short-timeout ephemeral variant for the detection phase.
    static let detection: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }()
}

actor PiholeDetectionService {
    private var session: URLSession { InsecureURLSession.detection }

    /// Detect Pi-hole at the given hostname, optionally with a specific port and SSL preference
    func detect(hostname: String, customPort: Int? = nil, useSSL: Bool? = nil) async throws -> DetectionResult {
        let (port, ssl) = try await detectConnectivity(hostname: hostname, customPort: customPort, useSSL: useSSL)
        return try await detectVersion(hostname: hostname, port: port, useSSL: ssl)
    }

    // MARK: - Port/SSL Detection

    private func detectConnectivity(hostname: String, customPort: Int?, useSSL: Bool?) async throws -> (Int, Bool) {
        if let port = customPort {
            // If user specified SSL preference, use it. Otherwise infer from port.
            if let ssl = useSSL {
                return (port, ssl)
            }
            if port == 443 {
                return (port, true)
            }
            return (port, false)
        }

        // Try HTTP on 80 first (most common for local Pi-holes)
        if await canConnect(hostname: hostname, port: 80, useSSL: false) {
            return (80, false)
        }

        // Then try HTTPS on 443
        if await canConnect(hostname: hostname, port: 443, useSSL: true) {
            return (443, true)
        }

        throw DetectionError.unreachable
    }

    private func canConnect(hostname: String, port: Int, useSSL: Bool) async -> Bool {
        let scheme = useSSL ? "https" : "http"
        guard let url = URL(string: "\(scheme)://\(hostname):\(port)/") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        do {
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse {
                return http.statusCode < 500
            }
            return false
        } catch {
            return false
        }
    }

    // MARK: - Version Detection

    private func detectVersion(hostname: String, port: Int, useSSL: Bool) async throws -> DetectionResult {
        let scheme = useSSL ? "https" : "http"
        let base = "\(scheme)://\(hostname):\(port)"

        // Detect version

        // Try v6 first: POST /api/auth with empty password
        if let v6Result = try? await probeV6(base: base) {
            // Check auth
            return DetectionResult(
                port: port,
                useSSL: useSSL,
                version: .v6,
                passwordRequired: !v6Result.session.valid,
                totpRequired: v6Result.session.totp
            )
        }

        // Try v5: GET /admin/api.php?summaryRaw
        if await probeV5(base: base) {
            // Check auth
            return DetectionResult(
                port: port,
                useSSL: useSSL,
                version: .v5,
                passwordRequired: true, // v5 always needs a token for management
                totpRequired: false
            )
        }

        throw DetectionError.notPihole
    }

    private func probeV6(base: String) async throws -> PiholeV6PasswordResponse {
        guard let url = URL(string: "\(base)/api/auth") else {
            throw DetectionError.notPihole
        }

        // Pi-hole v6 expects POST on /api/auth — an empty password probe
        // returns session info with valid=false if password is required
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(PiholeV6PasswordRequest(password: "", totp: nil))
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)

        // v6 returns 200 with session info even for empty password
        // Accept 401 too — as long as we can decode the response, it's v6
        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 || http.statusCode == 401 else {
            throw DetectionError.notPihole
        }

        return try JSONDecoder().decode(PiholeV6PasswordResponse.self, from: data)
    }

    private func probeV5(base: String) async -> Bool {
        // Try summaryRaw first — works with or without auth on most v5 setups
        if await probeV5Endpoint(url: "\(base)/admin/api.php?summaryRaw") {
            return true
        }
        // Fallback: just check if /admin/api.php responds at all
        if await probeV5Endpoint(url: "\(base)/admin/api.php") {
            return true
        }
        return false
    }

    private func probeV5Endpoint(url urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            // Any response from api.php means Pi-hole v5 is there
            // 200 = normal, 302 = redirect to login, both confirm it exists
            guard http.statusCode < 400 else { return false }
            if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                return true
            }
            // Empty 200 is still valid (no auth = empty response for some endpoints)
            return http.statusCode == 200
        } catch {
            return false
        }
    }

}
