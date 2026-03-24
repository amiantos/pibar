//
//  AddPiholeView.swift
//  PiBar
//
//  Created by Brad Root on 3/23/26.
//  Copyright © 2026 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

@Observable
class AddPiholeViewModel {
    enum Step {
        case hostname
        case detecting
        case authenticate
        case confirm
    }

    var step: Step = .hostname
    var hostname: String = ""
    var customPort: String = ""
    var useSSL: Bool = false
    var statusMessage: String = ""
    var errorMessage: String = ""

    // Stable ID for this connection (used for Keychain storage)
    let connectionID = UUID()

    // Detection result
    var detectionResult: DetectionResult?

    // Auth fields
    var password: String = ""
    var apiToken: String = ""
    var totp: String = ""
    var savePassword: Bool = true
    var adminPanelURL: String = ""

    // Auth state
    var isAuthenticating: Bool = false
    var authError: String = ""

    private let detector = PiholeDetectionService()

    func startDetection() async {
        step = .detecting
        errorMessage = ""
        statusMessage = "Detecting Pi-hole..."

        do {
            var port = customPort.isEmpty ? nil : Int(customPort)
            if port == nil && useSSL {
                port = 443
            }
            let sslOverride: Bool? = (port != nil || useSSL) ? useSSL : nil
            let result = try await detector.detect(hostname: hostname.trimmingCharacters(in: .whitespacesAndNewlines), customPort: port, useSSL: sslOverride)
            detectionResult = result

            let useSSL = result.useSSL
            adminPanelURL = PiholeConnection.generateAdminPanelURL(
                hostname: hostname.trimmingCharacters(in: .whitespacesAndNewlines),
                port: result.port,
                useSSL: useSSL
            )

            if result.passwordRequired {
                step = .authenticate
            } else {
                step = .confirm
            }
        } catch {
            errorMessage = error.localizedDescription
            step = .hostname
        }
    }

    func authenticate() async {
        guard let result = detectionResult else { return }
        isAuthenticating = true
        authError = ""

        let cleanHostname = hostname.trimmingCharacters(in: .whitespacesAndNewlines)

        if result.version == .v6 {
            let connection = PiholeConnection(
                id: connectionID,
                hostname: cleanHostname,
                port: result.port,
                useSSL: result.useSSL,
                version: .v6,
                passwordProtected: true,
                adminPanelURL: adminPanelURL,
                savePassword: savePassword,
                requiresTOTP: result.totpRequired
            )
            let api = Pihole6API(connection: connection)

            do {
                let totpInt = totp.isEmpty ? nil : Int(totp)
                let session = try await api.authenticate(password: password, totp: totpInt)
                if session.valid {
                    // Save SID as the token
                    if let sid = session.sid {
                        connection.saveToken(sid)
                    }
                    if savePassword {
                        api.savePasswordForRefresh(password)
                    }
                    detectionResult = result
                    step = .confirm
                } else {
                    authError = session.message ?? "Authentication failed."
                }
            } catch {
                authError = "Authentication failed: \(error.localizedDescription)"
            }
        } else {
            // v5: validate API token
            let connection = PiholeConnection(
                id: connectionID,
                hostname: cleanHostname,
                port: result.port,
                useSSL: result.useSSL,
                version: .v5,
                passwordProtected: !apiToken.isEmpty,
                adminPanelURL: adminPanelURL,
                savePassword: false,
                requiresTOTP: false
            )
            connection.saveToken(apiToken)
            let api = PiholeAPI(connection: connection)

            do {
                let valid = try await api.testConnection()
                if valid {
                    step = .confirm
                } else {
                    authError = "Invalid API token."
                    connection.deleteToken()
                }
            } catch {
                authError = "Connection failed: \(error.localizedDescription)"
                connection.deleteToken()
            }
        }

        isAuthenticating = false
    }

    func buildConnection() -> PiholeConnection {
        let result = detectionResult!
        let cleanHostname = hostname.trimmingCharacters(in: .whitespacesAndNewlines)

        let connection = PiholeConnection(
            id: connectionID,
            hostname: cleanHostname,
            port: result.port,
            useSSL: result.useSSL,
            version: result.version,
            passwordProtected: result.passwordRequired,
            adminPanelURL: adminPanelURL,
            savePassword: result.version == .v6 ? savePassword : false,
            requiresTOTP: result.totpRequired
        )

        // Save credentials
        if result.version == .v5 && !apiToken.isEmpty {
            connection.saveToken(apiToken)
        }
        // v6 credentials were already saved during authenticate()

        return connection
    }
}

struct AddPiholeView: View {
    var store: PreferencesStore
    @State private var viewModel = AddPiholeViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.step {
            case .hostname:
                hostnameStep
            case .detecting:
                detectingStep
            case .authenticate:
                authenticateStep
            case .confirm:
                confirmStep
            }
        }
        .frame(width: 400)
        .padding()
    }

    // MARK: - Step 1: Hostname

    private var hostnameStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Pi-hole")
                .font(.headline)

            HStack {
                TextField("Hostname or IP address", text: $viewModel.hostname)
                    .textFieldStyle(.roundedBorder)
                TextField(viewModel.useSSL ? "443" : "80", text: $viewModel.customPort)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .onChange(of: viewModel.customPort) {
                        if viewModel.customPort == "443" {
                            viewModel.useSSL = true
                        }
                    }
            }

            Toggle("Use SSL", isOn: $viewModel.useSSL)

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Connect") {
                    Task { await viewModel.startDetection() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.hostname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Step 2: Detecting

    private var detectingStep: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(viewModel.statusMessage)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    // MARK: - Step 3: Authenticate

    private var authenticateStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Authentication Required")
                .font(.headline)

            if let result = viewModel.detectionResult {
                Text("Detected Pi-hole \(result.version == .v6 ? "v6+" : "v5") at \(viewModel.hostname):\(result.port)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            if viewModel.detectionResult?.version == .v6 {
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)

                if viewModel.detectionResult?.totpRequired == true {
                    TextField("TOTP Code", text: $viewModel.totp)
                        .textFieldStyle(.roundedBorder)
                }

                if viewModel.detectionResult?.totpRequired != true {
                    Toggle("Save password for automatic reconnection", isOn: $viewModel.savePassword)
                        .font(.caption)
                }
            } else {
                TextField("API Token", text: $viewModel.apiToken)
                    .textFieldStyle(.roundedBorder)
                Text("Find your API token in Pi-hole Admin > Settings > API")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.authError.isEmpty {
                Text(viewModel.authError)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Button("Back") { viewModel.step = .hostname }
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Authenticate") {
                    Task { await viewModel.authenticate() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isAuthenticating)
            }
        }
    }

    // MARK: - Step 4: Confirm

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connection Ready")
                .font(.headline)

            if let result = viewModel.detectionResult {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                    GridRow {
                        Text("Host:").bold()
                        Text(viewModel.hostname)
                    }
                    GridRow {
                        Text("Port:").bold()
                        Text("\(result.port)")
                    }
                    GridRow {
                        Text("SSL:").bold()
                        Text(result.useSSL ? "Yes" : "No")
                    }
                    GridRow {
                        Text("Version:").bold()
                        Text(result.version == .v6 ? "Pi-hole v6+" : "Pi-hole v5")
                    }
                }
            }

            TextField("Admin Panel URL (optional override)", text: $viewModel.adminPanelURL)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            HStack {
                Button("Back") {
                    if viewModel.detectionResult?.passwordRequired == true {
                        viewModel.step = .authenticate
                    } else {
                        viewModel.step = .hostname
                    }
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    let connection = viewModel.buildConnection()
                    store.addConnection(connection)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}
