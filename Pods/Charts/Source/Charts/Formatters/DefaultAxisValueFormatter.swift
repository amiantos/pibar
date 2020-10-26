//
//  DefaultAxisValueFormatter.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation

@objc(ChartDefaultAxisValueFormatter)
open class DefaultAxisValueFormatter: NSObject, IAxisValueFormatter {
    public typealias Block = (
        _ value: Double,
        _ axis: AxisBase?
    ) -> String

    @objc open var block: Block?

    @objc open var hasAutoDecimals: Bool = false

    private var _formatter: NumberFormatter?
    @objc open var formatter: NumberFormatter? {
        get { _formatter }
        set {
            hasAutoDecimals = false
            _formatter = newValue
        }
    }

    // TODO: Documentation. Especially the nil case
    private var _decimals: Int?
    open var decimals: Int? {
        get { _decimals }
        set {
            _decimals = newValue

            if let digits = newValue {
                self.formatter?.minimumFractionDigits = digits
                self.formatter?.maximumFractionDigits = digits
                self.formatter?.usesGroupingSeparator = true
            }
        }
    }

    override public init() {
        super.init()

        formatter = NumberFormatter()
        hasAutoDecimals = true
    }

    @objc public init(formatter: NumberFormatter) {
        super.init()

        self.formatter = formatter
    }

    @objc public init(decimals: Int) {
        super.init()

        formatter = NumberFormatter()
        formatter?.usesGroupingSeparator = true
        self.decimals = decimals
        hasAutoDecimals = true
    }

    @objc public init(block: @escaping Block) {
        super.init()

        self.block = block
    }

    @objc public static func with(block: @escaping Block) -> DefaultAxisValueFormatter? {
        DefaultAxisValueFormatter(block: block)
    }

    open func stringForValue(_ value: Double,
                             axis: AxisBase?) -> String
    {
        if let block = block {
            return block(value, axis)
        } else {
            return formatter?.string(from: NSNumber(floatLiteral: value)) ?? ""
        }
    }
}
