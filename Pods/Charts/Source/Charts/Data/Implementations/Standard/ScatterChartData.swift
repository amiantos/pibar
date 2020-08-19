//
//  ScatterChartData.swift
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

open class ScatterChartData: BarLineScatterCandleBubbleChartData {
    override public init() {
        super.init()
    }

    override public init(dataSets: [IChartDataSet]?) {
        super.init(dataSets: dataSets)
    }

    /// - Returns: The maximum shape-size across all DataSets.
    @objc open func getGreatestShapeSize() -> CGFloat {
        return (_dataSets as? [IScatterChartDataSet])?
            .max { $0.scatterShapeSize < $1.scatterShapeSize }?
            .scatterShapeSize ?? 0
    }
}
