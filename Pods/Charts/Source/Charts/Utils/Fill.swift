//
//  Fill.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import CoreGraphics
import Foundation

@objc(ChartFillType)
public enum FillType: Int {
    case empty
    case color
    case linearGradient
    case radialGradient
    case image
    case tiledImage
    case layer
}

@objc(ChartFill)
open class Fill: NSObject {
    private var _type = FillType.empty
    private var _color: CGColor?
    private var _gradient: CGGradient?
    private var _gradientAngle: CGFloat = 0.0
    private var _gradientStartOffsetPercent = CGPoint()
    private var _gradientStartRadiusPercent: CGFloat = 0.0
    private var _gradientEndOffsetPercent = CGPoint()
    private var _gradientEndRadiusPercent: CGFloat = 0.0
    private var _image: CGImage?
    private var _layer: CGLayer?

    // MARK: Properties

    @objc open var type: FillType {
        _type
    }

    @objc open var color: CGColor? {
        _color
    }

    @objc open var gradient: CGGradient? {
        _gradient
    }

    @objc open var gradientAngle: CGFloat {
        _gradientAngle
    }

    @objc open var gradientStartOffsetPercent: CGPoint {
        _gradientStartOffsetPercent
    }

    @objc open var gradientStartRadiusPercent: CGFloat {
        _gradientStartRadiusPercent
    }

    @objc open var gradientEndOffsetPercent: CGPoint {
        _gradientEndOffsetPercent
    }

    @objc open var gradientEndRadiusPercent: CGFloat {
        _gradientEndRadiusPercent
    }

    @objc open var image: CGImage? {
        _image
    }

    @objc open var layer: CGLayer? {
        _layer
    }

    // MARK: Constructors

    override public init() {}

    @objc public init(CGColor: CGColor) {
        _type = .color
        _color = CGColor
    }

    @objc public convenience init(color: NSUIColor) {
        self.init(CGColor: color.cgColor)
    }

    @objc public init(linearGradient: CGGradient, angle: CGFloat) {
        _type = .linearGradient
        _gradient = linearGradient
        _gradientAngle = angle
    }

    @objc public init(
        radialGradient: CGGradient,
        startOffsetPercent: CGPoint,
        startRadiusPercent: CGFloat,
        endOffsetPercent: CGPoint,
        endRadiusPercent: CGFloat
    ) {
        _type = .radialGradient
        _gradient = radialGradient
        _gradientStartOffsetPercent = startOffsetPercent
        _gradientStartRadiusPercent = startRadiusPercent
        _gradientEndOffsetPercent = endOffsetPercent
        _gradientEndRadiusPercent = endRadiusPercent
    }

    @objc public convenience init(radialGradient: CGGradient) {
        self.init(
            radialGradient: radialGradient,
            startOffsetPercent: CGPoint(x: 0.0, y: 0.0),
            startRadiusPercent: 0.0,
            endOffsetPercent: CGPoint(x: 0.0, y: 0.0),
            endRadiusPercent: 1.0
        )
    }

    @objc public init(CGImage: CGImage, tiled: Bool) {
        _type = tiled ? .tiledImage : .image
        _image = CGImage
    }

    @objc public convenience init(image: NSUIImage, tiled: Bool) {
        self.init(CGImage: image.cgImage!, tiled: tiled)
    }

    @objc public convenience init(CGImage: CGImage) {
        self.init(CGImage: CGImage, tiled: false)
    }

    @objc public convenience init(image: NSUIImage) {
        self.init(image: image, tiled: false)
    }

    @objc public init(CGLayer: CGLayer) {
        _type = .layer
        _layer = CGLayer
    }

    // MARK: Constructors

    @objc open class func fillWithCGColor(_ CGColor: CGColor) -> Fill {
        Fill(CGColor: CGColor)
    }

    @objc open class func fillWithColor(_ color: NSUIColor) -> Fill {
        Fill(color: color)
    }

    @objc open class func fillWithLinearGradient(
        _ linearGradient: CGGradient,
        angle: CGFloat
    ) -> Fill {
        Fill(linearGradient: linearGradient, angle: angle)
    }

    @objc open class func fillWithRadialGradient(
        _ radialGradient: CGGradient,
        startOffsetPercent: CGPoint,
        startRadiusPercent: CGFloat,
        endOffsetPercent: CGPoint,
        endRadiusPercent: CGFloat
    ) -> Fill {
        Fill(
            radialGradient: radialGradient,
            startOffsetPercent: startOffsetPercent,
            startRadiusPercent: startRadiusPercent,
            endOffsetPercent: endOffsetPercent,
            endRadiusPercent: endRadiusPercent
        )
    }

    @objc open class func fillWithRadialGradient(_ radialGradient: CGGradient) -> Fill {
        Fill(radialGradient: radialGradient)
    }

    @objc open class func fillWithCGImage(_ CGImage: CGImage, tiled: Bool) -> Fill {
        Fill(CGImage: CGImage, tiled: tiled)
    }

    @objc open class func fillWithImage(_ image: NSUIImage, tiled: Bool) -> Fill {
        Fill(image: image, tiled: tiled)
    }

    @objc open class func fillWithCGImage(_ CGImage: CGImage) -> Fill {
        Fill(CGImage: CGImage)
    }

    @objc open class func fillWithImage(_ image: NSUIImage) -> Fill {
        Fill(image: image)
    }

    @objc open class func fillWithCGLayer(_ CGLayer: CGLayer) -> Fill {
        Fill(CGLayer: CGLayer)
    }

    // MARK: Drawing code

    /// Draws the provided path in filled mode with the provided area
    @objc open func fillPath(
        context: CGContext,
        rect: CGRect
    ) {
        let fillType = _type
        if fillType == .empty {
            return
        }

        context.saveGState()

        switch fillType {
        case .color:

            context.setFillColor(_color!)
            context.fillPath()

        case .image:

            context.clip()
            context.draw(_image!, in: rect)

        case .tiledImage:

            context.clip()
            context.draw(_image!, in: rect, byTiling: true)

        case .layer:

            context.clip()
            context.draw(_layer!, in: rect)

        case .linearGradient:

            let radians = (360.0 - _gradientAngle).DEG2RAD
            let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
            let xAngleDelta = cos(radians) * rect.width / 2.0
            let yAngleDelta = sin(radians) * rect.height / 2.0
            let startPoint = CGPoint(
                x: centerPoint.x - xAngleDelta,
                y: centerPoint.y - yAngleDelta
            )
            let endPoint = CGPoint(
                x: centerPoint.x + xAngleDelta,
                y: centerPoint.y + yAngleDelta
            )

            context.clip()
            context.drawLinearGradient(_gradient!,
                                       start: startPoint,
                                       end: endPoint,
                                       options: [.drawsAfterEndLocation, .drawsBeforeStartLocation])

        case .radialGradient:

            let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
            let radius = max(rect.width, rect.height) / 2.0

            context.clip()
            context.drawRadialGradient(_gradient!,
                                       startCenter: CGPoint(
                                           x: centerPoint.x + rect.width * _gradientStartOffsetPercent.x,
                                           y: centerPoint.y + rect.height * _gradientStartOffsetPercent.y
                                       ),
                                       startRadius: radius * _gradientStartRadiusPercent,
                                       endCenter: CGPoint(
                                           x: centerPoint.x + rect.width * _gradientEndOffsetPercent.x,
                                           y: centerPoint.y + rect.height * _gradientEndOffsetPercent.y
                                       ),
                                       endRadius: radius * _gradientEndRadiusPercent,
                                       options: [.drawsAfterEndLocation, .drawsBeforeStartLocation])

        case .empty:
            break
        }

        context.restoreGState()
    }
}
