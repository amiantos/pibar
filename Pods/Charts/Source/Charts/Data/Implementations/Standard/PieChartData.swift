//
//  PieData.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation

open class PieChartData: ChartData {
    override public init() {
        super.init()
    }

    override public init(dataSets: [IChartDataSet]?) {
        super.init(dataSets: dataSets)
    }

    /// All DataSet objects this ChartData object holds.
    @objc override open var dataSets: [IChartDataSet] {
        get {
            assert(super.dataSets.count <= 1, "Found multiple data sets while pie chart only allows one")
            return super.dataSets
        }
        set {
            super.dataSets = newValue
        }
    }

    @objc var dataSet: IPieChartDataSet? {
        get {
            dataSets.count > 0 ? dataSets[0] as? IPieChartDataSet : nil
        }
        set {
            if let newValue = newValue {
                dataSets = [newValue]
            } else {
                dataSets = []
            }
        }
    }

    override open func getDataSetByIndex(_ index: Int) -> IChartDataSet? {
        if index != 0 {
            return nil
        }
        return super.getDataSetByIndex(index)
    }

    override open func getDataSetByLabel(_ label: String, ignorecase: Bool) -> IChartDataSet? {
        if dataSets.count == 0 || dataSets[0].label == nil {
            return nil
        }

        if ignorecase {
            if let label = dataSets[0].label, label.caseInsensitiveCompare(label) == .orderedSame {
                return dataSets[0]
            }
        } else {
            if label == dataSets[0].label {
                return dataSets[0]
            }
        }
        return nil
    }

    override open func entryForHighlight(_ highlight: Highlight) -> ChartDataEntry? {
        dataSet?.entryForIndex(Int(highlight.x))
    }

    override open func addDataSet(_ d: IChartDataSet!) {
        super.addDataSet(d)
    }

    /// Removes the DataSet at the given index in the DataSet array from the data object.
    /// Also recalculates all minimum and maximum values.
    ///
    /// - Returns: `true` if a DataSet was removed, `false` ifno DataSet could be removed.
    override open func removeDataSetByIndex(_ index: Int) -> Bool {
        if index >= _dataSets.count || index < 0 {
            return false
        }

        return false
    }

    /// The total y-value sum across all DataSet objects the this object represents.
    @objc open var yValueSum: Double {
        guard let dataSet = dataSet else { return 0.0 }
        return (0 ..< dataSet.entryCount).reduce(into: 0) {
            $0 += dataSet.entryForIndex($1)?.y ?? 0
        }
    }
}
