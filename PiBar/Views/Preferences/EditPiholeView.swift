//
//  EditPiholeView.swift
//  PiBar
//
//  Created by Brad Root on 3/23/26.
//  Copyright © 2026 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct EditPiholeView: View {
    var store: PreferencesStore
    var connection: PiholeConnection
    @Environment(\.dismiss) private var dismiss

    @State private var hostname: String = ""
    @State private var port: String = ""
    @State private var useSSL: Bool = false
    @State private var adminPanelURL: String = ""
    @State private var savePassword: Bool = false
    @State private var ignoreWhenOffline: Bool = false

    // Re-auth fields
    @State private var password: String = ""
    @State private var apiToken: String = ""
    @State private var totp: String = ""
    @State private var isAuthenticating: Bool = false
    @State private var authError: String = ""
    @State private var requiresTOTP: Bool = false
    @State private var showReAuth: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Pi-hole")
                .font(.headline)

            HStack {
                Text("Version:")
                    .bold()
                Text(connection.version == .v6 ? "Pi-hole v6+" : "Pi-hole v5")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            TextField("Hostname", text: $hostname)
                .textFieldStyle(.roundedBorder)

            HStack {
                TextField("Port", text: $port)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Toggle("Use SSL", isOn: $useSSL)
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField("Admin Panel URL", text: $adminPanelURL)
                    .textFieldStyle(.roundedBorder)
                Text("Override this if you access the admin panel at a different URL (e.g., behind a reverse proxy).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            if connection.version == .v6 {
                Toggle("Save password for automatic reconnection", isOn: $savePassword)
                    .font(.caption)
            }

            Toggle("Ignore when offline", isOn: $ignoreWhenOffline)
                .font(.caption)

            Divider()

            DisclosureGroup("Re-authenticate", isExpanded: $showReAuth) {
                VStack(alignment: .leading, spacing: 8) {
                    if connection.version == .v6 {
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                        TextField("TOTP Code (if enabled)", text: $totp)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        TextField("API Token", text: $apiToken)
                            .textFieldStyle(.roundedBorder)
                    }

                    if !authError.isEmpty {
                        Text(authError)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Button("Test & Save Credentials") {
                        Task { await reAuthenticate() }
                    }
                    .disabled(isAuthenticating)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    saveChanges()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .frame(width: 400)
        .padding()
        .onAppear {
            hostname = connection.hostname
            port = "\(connection.port)"
            useSSL = connection.useSSL
            adminPanelURL = connection.adminPanelURL
            savePassword = connection.savePassword
            requiresTOTP = connection.requiresTOTP
            ignoreWhenOffline = connection.ignoreWhenOffline
        }
    }

    private func saveChanges() {
        let effectiveSavePassword = connection.version == .v6 ? savePassword : false
        if !effectiveSavePassword {
            connection.deleteSavedPassword()
        }
        let updated = PiholeConnection(
            id: connection.id,
            hostname: hostname.trimmingCharacters(in: .whitespacesAndNewlines),
            port: Int(port) ?? connection.port,
            useSSL: useSSL,
            version: connection.version,
            passwordProtected: connection.passwordProtected,
            adminPanelURL: adminPanelURL,
            savePassword: effectiveSavePassword,
            requiresTOTP: requiresTOTP,
            ignoreWhenOffline: ignoreWhenOffline
        )
        store.updateConnection(updated)
    }

    private func reAuthenticate() async {
        isAuthenticating = true
        authError = ""

        let portInt = Int(port) ?? connection.port
        let cleanHostname = hostname.trimmingCharacters(in: .whitespacesAndNewlines)

        if connection.version == .v6 {
            let tempConnection = PiholeConnection(
                id: connection.id,
                hostname: cleanHostname,
                port: portInt,
                useSSL: useSSL,
                version: .v6,
                passwordProtected: true,
                adminPanelURL: adminPanelURL,
                savePassword: savePassword,
                requiresTOTP: !totp.isEmpty || requiresTOTP
            )
            let api = Pihole6API(connection: tempConnection)

            do {
                let totpInt = totp.isEmpty ? nil : Int(totp)
                let session = try await api.authenticate(password: password, totp: totpInt)
                if session.valid {
                    if let sid = session.sid {
                        tempConnection.saveToken(sid)
                    }
                    // Update TOTP requirement based on server response
                    requiresTOTP = session.totp
                    // If TOTP is needed, disable password saving (can't auto-refresh with TOTP)
                    if session.totp {
                        savePassword = false
                    }
                    if savePassword {
                        api.savePasswordForRefresh(password)
                    }
                    authError = ""
                    showReAuth = false
                } else {
                    authError = session.message ?? "Authentication failed."
                }
            } catch {
                authError = "Failed: \(error.localizedDescription)"
            }
        } else {
            let tempConnection = PiholeConnection(
                id: connection.id,
                hostname: cleanHostname,
                port: portInt,
                useSSL: useSSL,
                version: .v5,
                passwordProtected: !apiToken.isEmpty,
                adminPanelURL: adminPanelURL,
                savePassword: false,
                requiresTOTP: false
            )
            tempConnection.saveToken(apiToken)
            let api = PiholeAPI(connection: tempConnection)

            do {
                let valid = try await api.testConnection()
                if valid {
                    authError = ""
                    showReAuth = false
                } else {
                    authError = "Invalid API token."
                }
            } catch {
                authError = "Failed: \(error.localizedDescription)"
            }
        }

        isAuthenticating = false
    }
}
