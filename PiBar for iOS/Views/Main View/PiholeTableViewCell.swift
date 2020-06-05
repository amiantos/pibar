//
//  PiholeTableViewCell.swift
//  PiBar for iOS
//
//  Created by Brad Root on 6/3/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Charts
import UIKit

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
                self.updateChart()
            }
        }
    }

    @IBOutlet var hostnameLabel: UILabel!
    @IBOutlet var currentStatusLabel: UILabel!
    @IBOutlet var totalQueriesLabel: UILabel!
    @IBOutlet var blockedQueriesLabel: UILabel!
    @IBOutlet var blocklistLabel: UILabel!

    @IBOutlet var containerView: UIView!

    @IBOutlet var chart: PiBarChartView!

    fileprivate func roundCorners() {
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(
            roundedRect: containerView.bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: 15, height: 15)
        ).cgPath
        containerView.layer.mask = maskLayer
        containerView.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func updateChart() {
        if chartData.1.isEmpty { return }
        chart.loadDataOverTime(chartData.1, maxValue: chartData.0)
    }
}
