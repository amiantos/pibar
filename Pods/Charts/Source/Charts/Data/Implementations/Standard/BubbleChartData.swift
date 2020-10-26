//
//  BubbleChartData.swift
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

open class BubbleChartData: BarLineScatterCandleBubbleChartData {
    override public init() {
        super.init()
    }

    override public init(dataSets: [IChartDataSet]?) {
        super.init(dataSets: dataSets)
    }

    /// Sets the width of the circle that surrounds the bubble when highlighted for all DataSet objects this data object contains
    @objc open func setHighlightCircleWidth(_ width: CGFloat) {
        (_dataSets as? [IBubbleChartDataSet])?.forEach { $0.highlightCircleWidth = width }
    }
}
