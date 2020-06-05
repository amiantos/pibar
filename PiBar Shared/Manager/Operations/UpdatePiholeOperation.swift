//
//  UpdatePiholeOperation.swift
//  PiBar
//
//  Created by Brad Root on 5/26/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

final class UpdatePiholeOperation: AsyncOperation {
    private(set) var pihole: Pihole

    init(_ pihole: Pihole) {
        self.pihole = pihole
    }

    override func main() {
        Log.debug("Updating Pi-hole: \(pihole.identifier)")

        var enabled: Bool? = true
        var online = true
        var canBeManaged: Bool = false

        var receivedSummary: PiholeAPISummary?
        var receivedOverTimeData: PiholeOverTimeData?

        let group = DispatchGroup()

        group.enter()
        pihole.api.fetchSummary { summary in
            Log.debug("Received Summary for \(self.pihole.identifier)")
            receivedSummary = summary
            group.leave()
        }

        group.enter()
        pihole.api.fetchOverTimeData { overTimeData in
            Log.debug("Received Over Time Data for \(self.pihole.identifier)")
            receivedOverTimeData = overTimeData
            group.leave()
        }

        group.wait()

        if let summary = receivedSummary {
            if summary.status != "enabled" {
                enabled = false
            }
            if !pihole.api.connection.token.isEmpty || !pihole.api.connection.passwordProtected {
                canBeManaged = true
            }
        } else {
            enabled = nil
            online = false
            canBeManaged = false
        }

        let updatedPihole: Pihole = Pihole(
            api: pihole.api,
            identifier: pihole.api.identifier,
            online: online,
            summary: receivedSummary,
            overTimeData: receivedOverTimeData,
            canBeManaged: canBeManaged,
            enabled: enabled
        )

        pihole = updatedPihole

        state = .isFinished
    }
}
