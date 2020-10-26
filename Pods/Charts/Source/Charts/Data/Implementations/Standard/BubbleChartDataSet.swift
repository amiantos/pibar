//
//  BubbleChartDataSet.swift
//  Charts
//
//  Bubble chart implementation:
//    Copyright 2015 Pierre-Marc Airoldi
//    Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import CoreGraphics
import Foundation

open class BubbleChartDataSet: BarLineScatterCandleBubbleChartDataSet, IBubbleChartDataSet {
    // MARK: - Data functions and accessors

    internal var _maxSize = CGFloat(0.0)

    open var maxSize: CGFloat { _maxSize }
    @objc open var normalizeSizeEnabled: Bool = true
    open var isNormalizeSizeEnabled: Bool { normalizeSizeEnabled }

    override open func calcMinMax(entry e: ChartDataEntry) {
        guard let e = e as? BubbleChartDataEntry
        else { return }

        super.calcMinMax(entry: e)

        let size = e.size

        if size > _maxSize {
            _maxSize = size
        }
    }

    // MARK: - Styling functions and accessors

    /// Sets/gets the width of the circle that surrounds the bubble when highlighted
    open var highlightCircleWidth: CGFloat = 2.5

    // MARK: - NSCopying

    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! BubbleChartDataSet
        copy._xMin = _xMin
        copy._xMax = _xMax
        copy._maxSize = _maxSize
        copy.normalizeSizeEnabled = normalizeSizeEnabled
        copy.highlightCircleWidth = highlightCircleWidth
        return copy
    }
}
