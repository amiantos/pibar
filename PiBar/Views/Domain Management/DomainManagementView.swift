//
//  DomainManagementView.swift
//  PiBar
//
//  Created by Brad Root on 3/24/26.
//  Copyright © 2026 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct DomainManagementView: View {
    @Bindable var store: DomainManagementStore
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Blocked").tag(0)
                Text("Allowed").tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            if store.isLoading {
                ProgressView("Loading queries...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if selectedTab == 0 {
                    domainList(domains: store.blockedDomains, isBlockedTab: true)
                } else {
                    domainList(domains: store.allowedDomains, isBlockedTab: false)
                }
            }

            Divider()

            // Bottom bar: status + manual entry
            VStack(spacing: 12) {
                if let message = store.actionMessage {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(message.starts(with: "Error") ? .red : .green)
                }

                HStack {
                    TextField("Enter domain...", text: $store.manualDomain)
                        .textFieldStyle(.roundedBorder)
                    Button("Allow") {
                        let domain = store.manualDomain.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !domain.isEmpty else { return }
                        Task {
                            await store.addToAllowList(domain: domain)
                            store.manualDomain = ""
                        }
                    }
                    .disabled(store.manualDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Deny") {
                        let domain = store.manualDomain.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !domain.isEmpty else { return }
                        Task {
                            await store.addToDenyList(domain: domain)
                            store.manualDomain = ""
                        }
                    }
                    .disabled(store.manualDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Refresh") {
                        Task { await store.loadQueries() }
                    }
                    .disabled(store.isLoading)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 12)
        }
        .frame(minWidth: 500, minHeight: 500)
        .task {
            await store.loadQueries()
        }
    }

    private func domainList(domains: [DomainEntry], isBlockedTab: Bool) -> some View {
        Group {
            if domains.isEmpty {
                VStack {
                    Spacer()
                    Text("No domains found.")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List(domains) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.domain)
                                .font(.body)
                            Text("\(entry.queryCount) queries")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isBlockedTab {
                            Button("Allow") {
                                Task { await store.addToAllowList(domain: entry.domain) }
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                        } else {
                            Button("Deny") {
                                Task { await store.addToDenyList(domain: entry.domain) }
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
