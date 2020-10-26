//
//  BubbleChartView.swift
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

open class BubbleChartView: BarLineChartViewBase, BubbleChartDataProvider {
    override open func initialize() {
        super.initialize()

        renderer = BubbleChartRenderer(dataProvider: self, animator: _animator, viewPortHandler: _viewPortHandler)
    }

    // MARK: - BubbleChartDataProvider

    open var bubbleData: BubbleChartData? { _data as? BubbleChartData }
}
