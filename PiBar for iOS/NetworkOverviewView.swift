//
//  NetworkOverviewView.swift
//  PiBar for iOS
//
//  Created by Brad Root on 6/2/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit

class NetworkOverviewView: UIView {

    weak var manager: PiBarManager?

    @IBOutlet var totalQueriesLabel: UILabel!
    @IBOutlet var blockedQueriesLabel: UILabel!
    @IBOutlet var networkStatusLabel: UILabel!
    @IBOutlet var avgBlocklistLabel: UILabel!

    @IBOutlet var disableButton: UIButton!
    @IBOutlet var viewQueriesButton: UIButton!

    @IBAction func disableButtonAction(_ sender: UIButton) {
        let seconds = sender.tag > 0 ? sender.tag : nil
        Log.info("Disabling via Menu for \(String(describing: seconds)) seconds")
        manager?.disableNetwork(seconds: seconds)
    }

    var networkOverview: PiholeNetworkOverview? {
        didSet {
            DispatchQueue.main.async {
                guard let networkOverview = self.networkOverview else { return }
                self.totalQueriesLabel.text = networkOverview.totalQueriesToday.string
                self.blockedQueriesLabel.text = networkOverview.adsBlockedToday.string
                self.networkStatusLabel.text = networkOverview.networkStatus.rawValue
                self.avgBlocklistLabel.text = networkOverview.averageBlocklist.string
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        disableButton.layer.cornerRadius = disableButton.frame.height / 2
        viewQueriesButton.layer.cornerRadius = viewQueriesButton.frame.height / 2
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
