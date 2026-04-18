//
//  AboutView.swift
//  PiBar
//
//  Created by Brad Root on 3/23/26.
//  Copyright © 2026 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct AboutView: View {
    private let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        return "\(version)"
    }()

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("PiBar")
                .font(.title)
                .fontWeight(.bold)

            Text("Version \(appVersion)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("A Pi-hole menu bar app for macOS")
                .font(.body)

            Button("GitHub") {
                NSWorkspace.shared.open(URL(string: "https://github.com/amiantos/pibar")!)
            }

            Text("Copyright \u{00A9} 2020-2026 Brad Root")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 280)
    }
}
