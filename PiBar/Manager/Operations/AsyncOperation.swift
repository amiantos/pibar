//
//  AsyncOperation.swift
//  PiBar
//
//  Created by Brad Root on 5/26/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Foundation

class AsyncOperation: Operation {
    enum State: String {
        case isReady, isExecuting, isFinished
    }

    override var isAsynchronous: Bool {
        return true
    }

    var state = State.isReady {
        willSet {
            willChangeValue(forKey: state.rawValue)
            willChangeValue(forKey: newValue.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }

    override var isExecuting: Bool {
        return state == .isExecuting
    }

    override var isFinished: Bool {
        return state == .isFinished
    }

    override func start() {
        guard !isCancelled else {
            state = .isFinished
            return
        }

        state = .isExecuting
        main()
    }
}
