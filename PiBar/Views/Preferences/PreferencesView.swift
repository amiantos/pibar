//
//  PreferencesView.swift
//  PiBar
//
//  Created by Brad Root on 3/23/26.
//  Copyright © 2026 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import LaunchAtLogin

struct PreferencesView: View {
    @Bindable var store: PreferencesStore
    @State private var showingAddSheet = false
    @State private var editingConnection: PiholeConnection?
    @State private var selection: PiholeConnection.ID?

    var body: some View {
        Form {
            Section("Pi-holes") {
                Table(store.connections, selection: $selection) {
                    TableColumn("Hostname", value: \.hostname)
                    TableColumn("Port") { connection in
                        Text("\(connection.port)")
                    }
                    .width(50)
                    TableColumn("Version") { connection in
                        Text(connection.version == .v6 ? "v6+" : "v5")
                    }
                    .width(50)
                    TableColumn("SSL") { connection in
                        Text(connection.useSSL ? "Yes" : "No")
                    }
                    .width(35)
                }
                .frame(minHeight: 100, maxHeight: 200)

                HStack {
                    Button("Add") {
                        showingAddSheet = true
                    }
                    Button("Edit") {
                        if let id = selection,
                           let connection = store.connections.first(where: { $0.id == id }) {
                            editingConnection = connection
                        }
                    }
                    .disabled(selection == nil)
                    Button("Remove") {
                        if let id = selection,
                           let index = store.connections.firstIndex(where: { $0.id == id }) {
                            store.removeConnection(at: IndexSet(integer: index))
                            selection = nil
                        }
                    }
                    .disabled(selection == nil)
                    Spacer()
                }
            }

            Section("Menu Bar Display") {
                Toggle("Show Queries", isOn: $store.showQueries)
                    .onChange(of: store.showQueries) { store.saveDisplaySettings() }
                Toggle("Show Blocked", isOn: $store.showBlocked)
                    .onChange(of: store.showBlocked) { store.saveDisplaySettings() }
                Toggle("Show Percentage", isOn: $store.showPercentage)
                    .onChange(of: store.showPercentage) { store.saveDisplaySettings() }
            }

            Section("Labels") {
                Toggle("Show Labels", isOn: $store.showLabels)
                    .onChange(of: store.showLabels) { store.saveDisplaySettings() }
                    .disabled(!store.showQueries && !store.showBlocked && !store.showPercentage)
                Toggle("Verbose Labels", isOn: $store.verboseLabels)
                    .onChange(of: store.verboseLabels) { store.saveDisplaySettings() }
                    .disabled(!store.showLabels)
            }

            Section("General") {
                HStack {
                    Text("Polling Rate (seconds)")
                    Spacer()
                    TextField("", value: $store.pollingRate, format: .number)
                        .frame(width: 50)
                        .multilineTextAlignment(.trailing)
                        .onSubmit { store.saveDisplaySettings() }
                }
                Toggle("Keyboard Shortcut (Cmd+Opt+Shift+P)", isOn: $store.shortcutEnabled)
                    .onChange(of: store.shortcutEnabled) { store.saveDisplaySettings() }
                LaunchAtLogin.Toggle("Launch at Login")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, minHeight: 450)
        .sheet(isPresented: $showingAddSheet) {
            AddPiholeView(store: store)
        }
        .sheet(item: $editingConnection) { connection in
            EditPiholeView(store: store, connection: connection)
        }
    }
}
