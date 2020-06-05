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
                self.updateChart()
            }
        }
    }

    @IBOutlet weak var hostnameLabel: UILabel!
    @IBOutlet weak var currentStatusLabel: UILabel!
    @IBOutlet weak var totalQueriesLabel: UILabel!
    @IBOutlet weak var blockedQueriesLabel: UILabel!
    @IBOutlet weak var blocklistLabel: UILabel!

    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var chart: PiBarChartView!

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

    func updateChart() {
        if chartData.1.isEmpty { return }
        chart.loadDataOverTime(chartData.1, maxValue: chartData.0)
    }

}
