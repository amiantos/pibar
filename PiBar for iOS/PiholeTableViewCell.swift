//
//  PiholeTableViewCell.swift
//  PiBar for iOS
//
//  Created by Brad Root on 6/3/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit
import Charts

class PiholeTableViewCell: UITableViewCell {

    var pihole: Pihole? {
        didSet {
            DispatchQueue.main.async {
                guard let pihole = self.pihole, let summary = pihole.summary else { return }
                self.hostnameLabel.text = pihole.api.connection.hostname
                self.totalQueriesLabel.text = summary.dnsQueriesToday.string
                self.blockedQueriesLabel.text = summary.adsBlockedToday.string
                self.blocklistLabel.text = summary.domainsBeingBlocked.string
                self.currentStatusLabel.text = summary.status.capitalized
            }
        }
    }

    var chartData: (Double, [Double: (Double, Double)]) = (0, [:]) {
        didSet {
            DispatchQueue.main.async {
                self.setupChart()
            }
        }
    }

    @IBOutlet weak var hostnameLabel: UILabel!
    @IBOutlet weak var currentStatusLabel: UILabel!
    @IBOutlet weak var totalQueriesLabel: UILabel!
    @IBOutlet weak var blockedQueriesLabel: UILabel!
    @IBOutlet weak var blocklistLabel: UILabel!

    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var chart: BarChartView!

    fileprivate func roundCorners() {
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: containerView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 15, height: 15)).cgPath
        containerView.layer.mask = maskLayer
        containerView.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        roundCorners()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setupChart() {
        if chartData.1.isEmpty { return }

        // Chart setup
        chart.chartDescription?.enabled = false
        chart.isUserInteractionEnabled = false
        chart.leftAxis.drawLabelsEnabled = false
        chart.legend.enabled = false
        chart.minOffset = 0
        chart.xAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawGridLinesEnabled = false
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.drawAxisLineEnabled = false
        chart.xAxis.drawAxisLineEnabled = false
        chart.xAxis.enabled = false
        chart.leftAxis.enabled = false
        let xAxis = chart.xAxis
        xAxis.labelPosition = .bottom
        chart.rightAxis.enabled = false
        chart.xAxis.drawLabelsEnabled = false

        // Chart Data
        var yVals: [BarChartDataEntry] = []

        let sorted = chartData.1.sorted { $0.key < $1.key }

        for (key, value) in sorted {
            let entry = BarChartDataEntry(x: key, yValues: [value.0, value.1])
            yVals.append(entry)
        }

        if yVals.isEmpty { return }

        var set1: BarChartDataSet! = nil
        if let set = chart.data?.dataSets.first as? BarChartDataSet {
            set1 = set
            set1.replaceEntries(yVals)
//            chart.leftAxis.axisMaximum = chartData.0
            chart.data?.notifyDataChanged()
            chart.notifyDataSetChanged()
        } else {
            set1 = BarChartDataSet(entries: yVals)
            set1.label = "Queries Over Time"
            set1.colors = [UIColor(named: "red") ?? .systemRed, .darkGray]
            set1.drawValuesEnabled = false

//            chart.leftAxis.axisMaximum = chartData.0

            let data = BarChartData(dataSet: set1)
            data.barWidth = 0.8
            chart.data = data
        }

    }

}
