//
//  PreferencesTableViewController.swift
//  PiBar for iOS
//
//  Created by Brad Root on 8/24/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Foundation
import MessageUI
import UIKit

class PreferencesTableViewController: UITableViewController {
    @IBOutlet var interfaceColorLabel: UILabel!
    @IBOutlet var normalizeChartsLabel: UILabel!

    @IBAction func doneButtonAction(_: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    override func viewWillAppear(_: Bool) {
        interfaceColorLabel.text = Preferences.standard.interfaceColor.capitalized
        normalizeChartsLabel.text = Preferences.standard.normalizeCharts ? "On" : "Off"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 0, section: 2) {
            UIApplication.shared.open(URL(string: "https://github.com/amiantos/pibar")!)
        } else if indexPath == IndexPath(row: 1, section: 2) {
            UIApplication.shared.open(URL(string: "https://reddit.com/r/pibar")!)

        } else if indexPath == IndexPath(row: 2, section: 2) {
            UIApplication.shared.open(URL(string: "https://twitter.com/amiantos")!)
        } else if indexPath == IndexPath(row: 3, section: 2) {
            sendEmail()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PreferencesTableViewController: MFMailComposeViewControllerDelegate {
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["bradroot@me.com"])
            mail.setSubject("PiBar for iOS Feedback")
            mail.setMessageBody(
                """
                <P>System Information:<br>
                App Version: \(Bundle.main.appVersionShort!) (\(Bundle.main.appVersionLong!))<br>
                OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)</P>
                <P>Put your suggestion/question/problem here:</P>
                """,
                isHTML: true
            )

            present(mail, animated: true)
        } else {
            let alert = UIAlertController(
                title: "Unable to Compose",
                message: "PiBar was unable to compose an email for you, please email bradroot@me.com if you need help.",
                preferredStyle: .alert
            )
            if let themeColor = ThemeManager.getColor() {
                alert.view.tintColor = themeColor
            }
            let alertClose = UIAlertAction(title: "Close", style: .cancel, handler: nil)
            alert.addAction(alertClose)
            present(alert, animated: true)
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith _: MFMailComposeResult, error _: Error?) {
        controller.dismiss(animated: true)
    }
}
