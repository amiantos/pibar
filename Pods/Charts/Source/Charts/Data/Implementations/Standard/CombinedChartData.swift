//
//  CombinedChartData.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation

open class CombinedChartData: BarLineScatterCandleBubbleChartData {
    private var _lineData: LineChartData!
    private var _barData: BarChartData!
    private var _scatterData: ScatterChartData!
    private var _candleData: CandleChartData!
    private var _bubbleData: BubbleChartData!

    override public init() {
        super.init()
    }

    override public init(dataSets: [IChartDataSet]?) {
        super.init(dataSets: dataSets)
    }

    @objc open var lineData: LineChartData! {
        get {
            _lineData
        }
        set {
            _lineData = newValue
            notifyDataChanged()
        }
    }

    @objc open var barData: BarChartData! {
        get {
            _barData
        }
        set {
            _barData = newValue
            notifyDataChanged()
        }
    }

    @objc open var scatterData: ScatterChartData! {
        get {
            _scatterData
        }
        set {
            _scatterData = newValue
            notifyDataChanged()
        }
    }

    @objc open var candleData: CandleChartData! {
        get {
            _candleData
        }
        set {
            _candleData = newValue
            notifyDataChanged()
        }
    }

    @objc open var bubbleData: BubbleChartData! {
        get {
            _bubbleData
        }
        set {
            _bubbleData = newValue
            notifyDataChanged()
        }
    }

    override open func calcMinMax() {
        _dataSets.removeAll()

        _yMax = -Double.greatestFiniteMagnitude
        _yMin = Double.greatestFiniteMagnitude
        _xMax = -Double.greatestFiniteMagnitude
        _xMin = Double.greatestFiniteMagnitude

        _leftAxisMax = -Double.greatestFiniteMagnitude
        _leftAxisMin = Double.greatestFiniteMagnitude
        _rightAxisMax = -Double.greatestFiniteMagnitude
        _rightAxisMin = Double.greatestFiniteMagnitude

        let allData = self.allData

        for data in allData {
            data.calcMinMax()

            let sets = data.dataSets
            _dataSets.append(contentsOf: sets)

            if data.yMax > _yMax {
                _yMax = data.yMax
            }

            if data.yMin < _yMin {
                _yMin = data.yMin
            }

            if data.xMax > _xMax {
                _xMax = data.xMax
            }

            if data.xMin < _xMin {
                _xMin = data.xMin
            }

            for dataset in sets {
                if dataset.axisDependency == .left {
                    if dataset.yMax > _leftAxisMax {
                        _leftAxisMax = dataset.yMax
                    }
                    if dataset.yMin < _leftAxisMin {
                        _leftAxisMin = dataset.yMin
                    }
                } else {
                    if dataset.yMax > _rightAxisMax {
                        _rightAxisMax = dataset.yMax
                    }
                    if dataset.yMin < _rightAxisMin {
                        _rightAxisMin = dataset.yMin
                    }
                }
            }
        }
    }

    /// All data objects in row: line-bar-scatter-candle-bubble if not null.
    @objc open var allData: [ChartData] {
        var data = [ChartData]()

        if lineData !== nil {
            data.append(lineData)
        }
        if barData !== nil {
            data.append(barData)
        }
        if scatterData !== nil {
            data.append(scatterData)
        }
        if candleData !== nil {
            data.append(candleData)
        }
        if bubbleData !== nil {
            data.append(bubbleData)
        }

        return data
    }

    @objc open func dataByIndex(_ index: Int) -> ChartData {
        allData[index]
    }

    open func dataIndex(_ data: ChartData) -> Int? {
        allData.firstIndex(of: data)
    }

    override open func removeDataSet(_ dataSet: IChartDataSet) -> Bool {
        allData.contains { $0.removeDataSet(dataSet) }
    }

    override open func removeDataSetByIndex(_: Int) -> Bool {
        print("removeDataSet(index) not supported for CombinedData", terminator: "\n")
        return false
    }

    override open func removeEntry(_: ChartDataEntry, dataSetIndex _: Int) -> Bool {
        print("removeEntry(entry, dataSetIndex) not supported for CombinedData", terminator: "\n")
        return false
    }

    override open func removeEntry(xValue _: Double, dataSetIndex _: Int) -> Bool {
        print("removeEntry(xValue, dataSetIndex) not supported for CombinedData", terminator: "\n")
        return false
    }

    override open func notifyDataChanged() {
        if _lineData !== nil {
            _lineData.notifyDataChanged()
        }
        if _barData !== nil {
            _barData.notifyDataChanged()
        }
        if _scatterData !== nil {
            _scatterData.notifyDataChanged()
        }
        if _candleData !== nil {
            _candleData.notifyDataChanged()
        }
        if _bubbleData !== nil {
            _bubbleData.notifyDataChanged()
        }

        super.notifyDataChanged() // recalculate everything
    }

    /// Get the Entry for a corresponding highlight object
    ///
    /// - Parameters:
    ///   - highlight:
    /// - Returns: The entry that is highlighted
    override open func entryForHighlight(_ highlight: Highlight) -> ChartDataEntry? {
        if highlight.dataIndex >= allData.count {
            return nil
        }

        let data = dataByIndex(highlight.dataIndex)

        if highlight.dataSetIndex >= data.dataSetCount {
            return nil
        }

        // The value of the highlighted entry could be NaN - if we are not interested in highlighting a specific value.
        let entries = data.getDataSetByIndex(highlight.dataSetIndex).entriesForXValue(highlight.x)
        return entries.first { $0.y == highlight.y || highlight.y.isNaN }
    }

    /// Get dataset for highlight
    ///
    /// - Parameters:
    ///   - highlight: current highlight
    /// - Returns: dataset related to highlight
    @objc open func getDataSetByHighlight(_ highlight: Highlight) -> IChartDataSet! {
        if highlight.dataIndex >= allData.count {
            return nil
        }

        let data = dataByIndex(highlight.dataIndex)

        if highlight.dataSetIndex >= data.dataSetCount {
            return nil
        }

        return data.dataSets[highlight.dataSetIndex]
    }
}
