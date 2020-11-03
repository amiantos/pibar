//
//  NetworkOverviewView.swift
//  PiBar for iOS
//
//  Created by Brad Root on 6/2/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Charts
import UIKit

class NetworkOverviewView: UIView {
    weak var manager: PiBarManager?

    @IBOutlet var totalQueriesLabel: UILabel!
    @IBOutlet var blockedQueriesLabel: UILabel!
    @IBOutlet var networkStatusLabel: UILabel!
    @IBOutlet var avgBlocklistLabel: UILabel!

    @IBOutlet var disableButton: UIButton!
    @IBOutlet var viewQueriesButton: UIButton!

    @IBOutlet var chart: PiBarChartView!

    @IBAction func disableButtonAction(_ sender: UIButton) {
        let seconds = Preferences.standard.defaultDisableDuration
        if seconds > 0 {
            Log.info("Disabling via Menu for \(String(describing: seconds)) seconds")
            manager?.disableNetwork(seconds: seconds)
        } else if seconds == 0 {
            Log.info("Disabling via Menu permanently")
            manager?.disableNetwork()
        } else {
            // Show selection menu...
        }
    }

    var networkOverview: PiholeNetworkOverview? {
        didSet {
            DispatchQueue.main.async {
                guard let networkOverview = self.networkOverview else { return }
                self.totalQueriesLabel.text = networkOverview.totalQueriesToday.string
                self.blockedQueriesLabel.text = networkOverview.adsBlockedToday.string
                self.networkStatusLabel.text = networkOverview.networkStatus.rawValue
                self.avgBlocklistLabel.text = networkOverview.averageBlocklist.string
                self.updateChart()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        disableButton.layer.cornerRadius = disableButton.frame.height / 2
        viewQueriesButton.layer.cornerRadius = viewQueriesButton.frame.height / 2

        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 38.5, height: 38.5)
        ).cgPath
        layer.mask = maskLayer
        clipsToBounds = true
    }

    func updateChart() {
        // Chart Data
        guard let dataOverTime = networkOverview?.overTimeData, !dataOverTime.overview.isEmpty else { return }
        chart.loadDataOverTime(dataOverTime.overview, maxValue: dataOverTime.maximumValue)
    }

    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
         // Drawing code
     }
     */
}
