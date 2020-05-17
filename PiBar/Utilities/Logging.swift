//
//  Logging.swift
//  PiBar
//
//  Created by Brad Root on 5/19/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

open class Log {
    public enum Level: Int {
        case verbose
        case debug
        case info
        case warn
        case error
        case off

        var name: String {
            switch self {
            case .verbose: return "Verbose"
            case .debug: return "Debug"
            case .info: return "Info"
            case .warn: return "Warn"
            case .error: return "Error"
            case .off: return "Disabled"
            }
        }

        var emoji: String {
            switch self {
            case .verbose: return "📖"
            case .debug: return "🐝"
            case .info: return "✏️"
            case .warn: return "⚠️"
            case .error: return "⁉️"
            case .off: return ""
            }
        }
    }

    public static var logLevel: Level = .off

    public static var useEmoji: Bool = true

    public static var handler: ((Level, String) -> Void)?

    private static let dateformatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "Y-MM-dd H:m:ss.SSSS"
        return dateFormatter
    }()

    private static func log<T>(_ object: @autoclosure () -> T, level: Log.Level, _ fileName: String, _: String, _ line: Int) {
        if logLevel.rawValue <= level.rawValue {
            let date = Log.dateformatter.string(from: Date())
            let components: [String] = fileName.components(separatedBy: "/")
            let objectName = components.last ?? "Unknown Object"
            let levelString = Log.useEmoji ? level.emoji : "|" + level.name.uppercased() + "|"
            let logString = "\(levelString) [\(date)]: \(object()) [\(objectName): \(line)]"
            print(logString)
            handler?(level, logString)
        }
    }

    public static func error<T>(
        _ object: @autoclosure () -> T,
        _ fileName: String = #file,
        _ functionName: String = #function,
        _ line: Int = #line
    ) {
        log(object(), level: .error, fileName, functionName, line)
    }

    public static func warn<T>(
        _ object: @autoclosure () -> T,
        _ fileName: String = #file,
        _ functionName: String = #function,
        _ line: Int = #line
    ) {
        log(object(), level: .warn, fileName, functionName, line)
    }

    public static func info<T>(
        _ object: @autoclosure () -> T,
        _ fileName: String = #file,
        _ functionName: String = #function,
        _ line: Int = #line
    ) {
        log(object(), level: .info, fileName, functionName, line)
    }

    public static func debug<T>(
        _ object: @autoclosure () -> T,
        _ fileName: String = #file,
        _ functionName: String = #function,
        _ line: Int = #line
    ) {
        log(object(), level: .debug, fileName, functionName, line)
    }

    public static func verbose<T>(
        _ object: @autoclosure () -> T,
        _ fileName: String = #file,
        _ functionName: String = #function,
        _ line: Int = #line
    ) {
        log(object(), level: .verbose, fileName, functionName, line)
    }
}
