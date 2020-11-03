//
//  NetworkOverviewView.swift
//  PiBar for iOS
//
//  Created by Brad Root on 6/2/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Charts
import UIKit

enum ButtonBehavior {
    case enable
    case disable
    case pending
}

class NetworkOverviewView: UIView {
    weak var manager: PiBarManager?

    var buttonBehavior: ButtonBehavior = .disable {
        didSet {
            switch buttonBehavior {
            case .enable:
                disableButton.setTitle("Enable", for: .normal)
                disableButton.isEnabled = true
            case .disable:
                disableButton.setTitle("Disable", for: .normal)
                disableButton.isEnabled = true
            case .pending:
                disableButton.setTitle("Disable", for: .normal)
                disableButton.isEnabled = false
            }
        }
    }

    @IBOutlet var totalQueriesLabel: UILabel!
    @IBOutlet var blockedQueriesLabel: UILabel!
    @IBOutlet var networkStatusLabel: UILabel!
    @IBOutlet var avgBlocklistLabel: UILabel!

    @IBOutlet var disableButton: UIButton!
    @IBOutlet var viewQueriesButton: UIButton!

    @IBOutlet var chart: PiBarChartView!

    @IBAction func disableButtonAction(_ sender: UIButton) {
        if buttonBehavior == .disable {
            let seconds = Preferences.standard.defaultDisableDuration
            if seconds > 0 {
                Log.info("Disabling via Menu for \(String(describing: seconds)) seconds")
                manager?.disableNetwork(seconds: seconds)
            } else if seconds == 0 {
                Log.info("Disabling via Menu permanently")
                manager?.disableNetwork()
            } else {
                showDisableMenu()
            }
        } else if buttonBehavior == .enable {
            manager?.enableNetwork()
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

                switch networkOverview.networkStatus {
                case .enabled:
                    self.buttonBehavior = .disable
                case .disabled:
                    self.buttonBehavior = .enable
                case .partiallyEnabled:
                    self.buttonBehavior = .disable
                case .offline:
                    self.buttonBehavior = .pending
                case .partiallyOffline:
                    self.buttonBehavior = .disable
                case .noneSet:
                    self.buttonBehavior = .pending
                case .initializing:
                    self.buttonBehavior = .pending
                }

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

    func showDisableMenu() {
        let disableActionSheet = UIAlertController(title: "Disable Pi-holes", message: nil, preferredStyle: .actionSheet)

        disableActionSheet.popoverPresentationController?.sourceView = disableButton.superview!
        disableActionSheet.popoverPresentationController?.sourceRect = disableButton.frame

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        disableActionSheet.addAction(cancelAction)

        let permAction = UIAlertAction(title: "Permanently", style: .destructive) { (_) in
            self.manager?.disableNetwork()
        }
        disableActionSheet.addAction(permAction)

        let disableTimes: [(Int, String)] = [
            (3600, "1 Hour"),
            (900, "15 Minutes"),
            (300, "5 Minutes"),
            (30, "30 Seconds"),
            (10, "10 Seconds"),
        ]
        for time in disableTimes {
            let action = UIAlertAction(title: time.1, style: .default) { (_) in
                self.manager?.disableNetwork(seconds: time.0)
            }
            disableActionSheet.addAction(action)
        }

        UIApplication.topViewController()?.present(disableActionSheet, animated: true, completion: nil)
    }

}
