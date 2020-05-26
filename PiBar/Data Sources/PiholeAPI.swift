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

class PiholeAPI: NSObject {
    let connection: PiholeConnectionV2

    var identifier: String {
        return "\(connection.hostname)"
    }

    private let path: String = "/admin/api.php"
    private let timeout: Int = 2

    private enum Endpoints {
        static let summary = PiholeAPIEndpoint(queryParameter: "summaryRaw", authorizationRequired: false)
        static let overTimeData10mins = PiholeAPIEndpoint(queryParameter: "overTimeData10mins", authorizationRequired: false)
        static let topItems = PiholeAPIEndpoint(queryParameter: "topItems", authorizationRequired: true)
        static let topClients = PiholeAPIEndpoint(queryParameter: "topClients", authorizationRequired: true)
        static let enable = PiholeAPIEndpoint(queryParameter: "enable", authorizationRequired: true)
        static let disable = PiholeAPIEndpoint(queryParameter: "disable", authorizationRequired: true)
        static let recentBlocked = PiholeAPIEndpoint(queryParameter: "recentBlocked", authorizationRequired: false)
    }

    override init() {
        connection = PiholeConnectionV2(
            hostname: "pi.hole",
            port: 80,
            useSSL: false,
            token: "",
            passwordProtected: true,
            adminPanelURL: "http://pi.hole/admin/"
        )
        super.init()
    }

    init(connection: PiholeConnectionV2) {
        self.connection = connection
        super.init()
    }

    private func get(_ endpoint: PiholeAPIEndpoint, argument: String? = nil, completion: @escaping (String?) -> Void) {
        var builtURLString = baseURL

        if endpoint.authorizationRequired {
            builtURLString.append(contentsOf: "?auth=\(connection.token)&\(endpoint.queryParameter)")
        } else {
            builtURLString.append(contentsOf: "?\(endpoint.queryParameter)")
        }

        if let argument = argument {
            builtURLString.append(contentsOf: "=\(argument)")
        }

        Log.debug("Built API String: \(builtURLString)")

        guard let builtURL = URL(string: builtURLString) else { return completion(nil) }

        var urlRequest = URLRequest(url: builtURL)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 3
        let session = URLSession(configuration: .default)
        let dataTask = session.dataTask(with: urlRequest) { data, response, error in
            if error != nil {
                completion(nil)
            }
            if let response = response as? HTTPURLResponse {
                if 200 ..< 300 ~= response.statusCode {
                    if let data = data, let string = String(data: data, encoding: .utf8) {
                        completion(string)
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
        dataTask.resume()
    }

    private func decodeJSON<T>(_ string: String) -> T? where T: Decodable {
        do {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            let jsonData = string.data(using: .utf8)!
            let object = try jsonDecoder.decode(T.self, from: jsonData)
            return object
        } catch {
            return nil
        }
    }

    // MARK: - URLs

    private var baseURL: String {
        let prefix = connection.useSSL ? "https" : "http"
        return "\(prefix)://\(connection.hostname):\(connection.port)\(path)"
    }

    var admin: URL {
        return URL(string: "http://\(connection.hostname):\(connection.port)/admin")!
    }

    // MARK: - Testing

    func testConnection(completion: @escaping (PiholeConnectionTestResult) -> Void) {
        fetchTopItems { string in
            DispatchQueue.main.async {
                if let contents = string {
                    if contents == "[]" {
                        completion(.failureInvalidToken)
                    } else {
                        completion(.success)
                    }
                } else {
                    completion(.failure)
                }
            }
        }
    }

    // MARK: - Endpoints

    func fetchSummary(completion: @escaping (PiholeAPISummary?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.get(Endpoints.summary) { string in
                guard let jsonString = string,
                    let summary: PiholeAPISummary = self.decodeJSON(jsonString) else { return completion(nil) }
                completion(summary)
            }
        }
    }

    func fetchTopItems(completion: @escaping (String?) -> Void) {
        // Only using this endpoint to verify the API token
        // So we don't actually do anything with the output yet
        DispatchQueue.global(qos: .background).async {
            self.get(Endpoints.topItems) { string in
                completion(string)
            }
        }
    }

    func disable(seconds: Int? = nil, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            var secondsString: String?
            if let seconds = seconds {
                secondsString = String(seconds)
            }
            self.get(Endpoints.disable, argument: secondsString) { string in
                guard let jsonString = string,
                    let _: PiholeAPIStatus = self.decodeJSON(jsonString) else { return completion(false) }
                completion(true)
            }
        }
    }

    func enable(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.get(Endpoints.enable) { string in
                guard let jsonString = string,
                    let _: PiholeAPIStatus = self.decodeJSON(jsonString) else { return completion(false) }
                completion(true)
            }
        }
    }
}
