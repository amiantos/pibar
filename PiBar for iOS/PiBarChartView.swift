//
//  PiBarChartView.swift
//  PiBar for iOS
//
//  Created by Brad Root on 6/5/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Charts

class PiBarChartView: BarChartView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupChartPreferences()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupChartPreferences()
    }

    func setupChartPreferences() {
        // Chart setup
        chartDescription?.enabled = false
        isUserInteractionEnabled = false
        legend.enabled = false
        minOffset = 0

        xAxis.drawGridLinesEnabled = true
        xAxis.drawAxisLineEnabled = false
        xAxis.drawLabelsEnabled = false
        xAxis.enabled = true

        xAxis.gridColor = UIColor(named: "chartGridLines") ?? UIColor.darkGray
        xAxis.gridLineWidth = 0.5

        leftAxis.enabled = false
        leftAxis.drawGridLinesEnabled = false
        leftAxis.axisMinimum = 0
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawLabelsEnabled = false

        rightAxis.enabled = false
    }

    func loadDataOverTime(_ dataOverTime: [Double: (Double, Double)], maxValue: Double) {
        var yVals: [BarChartDataEntry] = []
        let sorted = dataOverTime.sorted { $0.key < $1.key }

        for (key, value) in sorted {
            let entry = BarChartDataEntry(x: key, yValues: [value.0, value.1])
            yVals.append(entry)
        }

        if yVals.isEmpty { return }

        xAxis.labelCount = yVals.count

        var set1: BarChartDataSet!
        if let set = data?.dataSets.first as? BarChartDataSet {
            set1 = set
            set1.replaceEntries(yVals)
            leftAxis.axisMaximum = maxValue
            data?.notifyDataChanged()
            notifyDataSetChanged()
        } else {
            set1 = BarChartDataSet(entries: yVals)
            set1.label = "Queries Over Time"
            set1.colors = [UIColor(named: "red") ?? .systemRed, .darkGray]
            set1.drawValuesEnabled = false

            leftAxis.axisMaximum = maxValue

            let barChartData = BarChartData(dataSet: set1)
            barChartData.barWidth = 0.8
            data = barChartData
        }
    }
}
