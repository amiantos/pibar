//
//  PiholeSettingsViewController.swift
//  PiBar
//
//  Created by Brad Root on 5/25/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Cocoa

protocol PiholeSettingsViewControllerDelegate: AnyObject {
    func savePiholeConnection(_ connection: PiholeConnectionV2, at index: Int?)
}

class PiholeSettingsViewController: NSViewController {

    var connection: PiholeConnectionV2?
    var currentIndex: Int = -1

    // MARK: - Outlets
    @IBOutlet weak var hostnameTextField: NSTextField!
    @IBOutlet weak var portTextField: NSTextField!
    @IBOutlet weak var useSSLCheckbox: NSButton!
    @IBOutlet weak var apiTokenTextField: NSTextField!

    @IBOutlet weak var testConnectionButton: NSButton!
    @IBOutlet weak var saveAndCloseButton: NSButton!
    @IBOutlet weak var closeButton: NSButton!

    // MARK: - Actions
    @IBAction func useSSLCheckboxAction(_ sender: NSButton) {
    }

    @IBAction func testConnectionButtonAction(_ sender: NSButton) {
    }

    @IBAction func saveAndCloseButtonAction(_ sender: NSButton) {
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        loadPiholeConnection()
    }

    func loadPiholeConnection() {
        Log.debug("Loading Pi-hole at index \(currentIndex)")
        if let connection = connection {
            hostnameTextField.stringValue = connection.hostname
            portTextField.stringValue = "\(connection.port)"
            useSSLCheckbox.state = connection.useSSL ? .on : .off
            apiTokenTextField.stringValue = connection.token
        } else {
            hostnameTextField.stringValue = "pi.hole"
            portTextField.stringValue = "80"
            useSSLCheckbox.state = .off
            apiTokenTextField.stringValue = ""
        }
    }
}
