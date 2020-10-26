//
//  Platform+Gestures.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

// MARK: - UIKit

#if canImport(UIKit)
    import UIKit

    public typealias NSUIGestureRecognizer = UIGestureRecognizer
    public typealias NSUIGestureRecognizerState = UIGestureRecognizer.State
    public typealias NSUIGestureRecognizerDelegate = UIGestureRecognizerDelegate
    public typealias NSUITapGestureRecognizer = UITapGestureRecognizer
    public typealias NSUIPanGestureRecognizer = UIPanGestureRecognizer

    extension NSUITapGestureRecognizer {
        @objc final func nsuiNumberOfTouches() -> Int {
            numberOfTouches
        }

        @objc final var nsuiNumberOfTapsRequired: Int {
            get {
                numberOfTapsRequired
            }
            set {
                numberOfTapsRequired = newValue
            }
        }
    }

    extension NSUIPanGestureRecognizer {
        @objc final func nsuiNumberOfTouches() -> Int {
            numberOfTouches
        }

        @objc final func nsuiLocationOfTouch(_ touch: Int, inView: UIView?) -> CGPoint {
            super.location(ofTouch: touch, in: inView)
        }
    }

    #if !os(tvOS)
        public typealias NSUIPinchGestureRecognizer = UIPinchGestureRecognizer
        public typealias NSUIRotationGestureRecognizer = UIRotationGestureRecognizer

        extension NSUIRotationGestureRecognizer {
            @objc final var nsuiRotation: CGFloat {
                get { rotation }
                set { rotation = newValue }
            }
        }

        extension NSUIPinchGestureRecognizer {
            @objc final var nsuiScale: CGFloat {
                get {
                    scale
                }
                set {
                    scale = newValue
                }
            }

            @objc final func nsuiLocationOfTouch(_ touch: Int, inView: UIView?) -> CGPoint {
                super.location(ofTouch: touch, in: inView)
            }
        }
    #endif
#endif

// MARK: - AppKit

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    public typealias NSUIGestureRecognizer = NSGestureRecognizer
    public typealias NSUIGestureRecognizerState = NSGestureRecognizer.State
    public typealias NSUIGestureRecognizerDelegate = NSGestureRecognizerDelegate
    public typealias NSUITapGestureRecognizer = NSClickGestureRecognizer
    public typealias NSUIPanGestureRecognizer = NSPanGestureRecognizer
    public typealias NSUIPinchGestureRecognizer = NSMagnificationGestureRecognizer
    public typealias NSUIRotationGestureRecognizer = NSRotationGestureRecognizer

    /** The 'tap' gesture is mapped to clicks. */
    extension NSUITapGestureRecognizer {
        final func nsuiNumberOfTouches() -> Int {
            1
        }

        final var nsuiNumberOfTapsRequired: Int {
            get {
                numberOfClicksRequired
            }
            set {
                numberOfClicksRequired = newValue
            }
        }
    }

    extension NSUIPanGestureRecognizer {
        final func nsuiNumberOfTouches() -> Int {
            1
        }

        // FIXME: Currently there are no more than 1 touch in OSX gestures, and not way to create custom touch gestures.
        final func nsuiLocationOfTouch(_: Int, inView: NSView?) -> NSPoint {
            super.location(in: inView)
        }
    }

    extension NSUIRotationGestureRecognizer {
        // FIXME: Currently there are no velocities in OSX gestures, and not way to create custom touch gestures.
        final var velocity: CGFloat {
            0.1
        }

        final var nsuiRotation: CGFloat {
            get { -rotation }
            set { rotation = -newValue }
        }
    }

    extension NSUIPinchGestureRecognizer {
        final var nsuiScale: CGFloat {
            get {
                magnification + 1.0
            }
            set {
                magnification = newValue - 1.0
            }
        }

        // FIXME: Currently there are no more than 1 touch in OSX gestures, and not way to create custom touch gestures.
        final func nsuiLocationOfTouch(_: Int, inView view: NSView?) -> NSPoint {
            super.location(in: view)
        }
    }
#endif
