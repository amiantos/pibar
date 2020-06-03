//
//  PiholeTableViewCell.swift
//  PiBar for iOS
//
//  Created by Brad Root on 6/3/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

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

    @IBOutlet weak var hostnameLabel: UILabel!
    @IBOutlet weak var currentStatusLabel: UILabel!
    @IBOutlet weak var totalQueriesLabel: UILabel!
    @IBOutlet weak var blockedQueriesLabel: UILabel!
    @IBOutlet weak var blocklistLabel: UILabel!

    @IBOutlet weak var containerView: UIView!

    fileprivate func roundCorners() {
        let cornerPath = UIBezierPath(roundedRect: containerView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 20, height: 20)).cgPath

        let maskLayer = CAShapeLayer()
        maskLayer.path = cornerPath

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

}
