//
//  ChangePiholeStatusOperation.swift
//  PiBar
//
//  Created by Brad Root on 5/26/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

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
        if self.status == .disable {
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
