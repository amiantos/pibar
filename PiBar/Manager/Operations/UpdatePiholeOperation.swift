//
//  UpdatePiholeOperation.swift
//  PiBar
//
//  Created by Brad Root on 5/26/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Foundation

final class UpdatePiholeOperation: AsyncOperation {
    private(set) var pihole: Pihole

    init(_ pihole: Pihole) {
        self.pihole = pihole
    }

    override func main() {
        Log.debug("Updating Pi-hole: \(pihole.identifier)")
        pihole.api.fetchSummary { summary in
            Log.debug("Updating Pi-hole: \(self.pihole.identifier) - Received Summary")
            var enabled: Bool? = true
            var online = true
            var canBeManaged: Bool = false

            if let summary = summary {
                if summary.status != "enabled" {
                    enabled = false
                }
                if !self.pihole.api.connection.token.isEmpty || !self.pihole.api.connection.passwordProtected {
                    canBeManaged = true
                }
            } else {
                enabled = nil
                online = false
                canBeManaged = false
            }

            let updatedPihole: Pihole = Pihole(
                api: self.pihole.api,
                identifier: self.pihole.api.identifier,
                online: online,
                summary: summary,
                canBeManaged: canBeManaged,
                enabled: enabled
            )

            self.pihole = updatedPihole

            self.state = .isFinished
        }
    }
}
