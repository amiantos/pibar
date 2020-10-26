//
//  ChangePiholeStatusOperation.swift
//  PiBar
//
//  Created by Brad Root on 5/26/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

enum Status {
    case enable
    case disable
}

final class ChangePiholeStatusOperation: AsyncOperation {
    private let pihole: Pihole
    private let status: Status
    private let seconds: Int?

    init(pihole: Pihole, status: Status, seconds: Int? = nil) {
        self.pihole = pihole
        self.status = status
        self.seconds = seconds
    }

    override func main() {
        if status == .disable {
            pihole.api.disable(seconds: seconds) { _ in
                self.state = .isFinished
            }
        } else {
            pihole.api.enable { _ in
                self.state = .isFinished
            }
        }
    }
}
