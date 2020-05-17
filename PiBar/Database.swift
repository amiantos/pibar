//
//  PBDatabase.swift
//  PiBar
//
//  Created by Brad Root on 5/17/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Foundation

struct PBDatabase {
    fileprivate enum Key {
        static let hostname = "hostname"
        static let port = "port"
        static let token = "token"
        static let showBlocked = "showBlocked"
        static let showQueries = "showQueries"
        static let showPercentage = "showPercentage"
        static let showLabels = "showLabels"
        static let verboseLabels = "verboseLabels"
    }

    static var standard: UserDefaults {
        let database = UserDefaults.standard
        database.register(defaults: [
            Key.hostname: "pi-hole.local",
            Key.port: "80",
            Key.token: "",
            Key.showBlocked: true,
            Key.showQueries: false,
            Key.showPercentage: false,
            Key.showLabels: false,
            Key.verboseLabels: false,
        ])

        return database
    }
}

extension UserDefaults {
    var hostname: String {
        return string(forKey: PBDatabase.Key.hostname) ?? "pi-hole.local"
    }

    var port: Int {
        let port = integer(forKey: PBDatabase.Key.port)
        return port > 0 ? port : 80
    }

    var token: String {
        return string(forKey: PBDatabase.Key.token) ?? ""
    }

    var showBlocked: Bool {
        return bool(forKey: PBDatabase.Key.showBlocked)
    }

    var showQueries: Bool {
        return bool(forKey: PBDatabase.Key.showQueries)
    }

    var showPercentage: Bool {
        return bool(forKey: PBDatabase.Key.showPercentage)
    }

    var showLabels: Bool {
        return bool(forKey: PBDatabase.Key.showLabels)
    }

    var verboseLabels: Bool {
        return bool(forKey: PBDatabase.Key.verboseLabels)
    }
}

private extension UserDefaults {
    func set(_ object: Any?, for key: String) {
        set(object, forKey: key)
        synchronize()
    }
}
