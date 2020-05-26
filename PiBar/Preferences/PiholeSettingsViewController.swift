//
//  PiholeSettingsViewController.swift
//  PiBar
//
//  Created by Brad Root on 5/25/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import Cocoa

protocol PiholeSettingsViewControllerDelegate: AnyObject {
    func savePiholeConnection(_ connection: PiholeConnectionV2, at index: Int)
}

class PiholeSettingsViewController: NSViewController {

    var connection: PiholeConnectionV2?
    var currentIndex: Int = -1
    weak var delegate: PiholeSettingsViewControllerDelegate?

    var passwordProtected: Bool = true

    // MARK: - Outlets
    @IBOutlet weak var hostnameTextField: NSTextField!
    @IBOutlet weak var portTextField: NSTextField!
    @IBOutlet weak var useSSLCheckbox: NSButton!
    @IBOutlet weak var apiTokenTextField: NSTextField!
    @IBOutlet weak var adminURLTextField: NSTextField!

    @IBOutlet weak var testConnectionButton: NSButton!
    @IBOutlet weak var testConnectionLabel: NSTextField!
    @IBOutlet weak var saveAndCloseButton: NSButton!
    @IBOutlet weak var closeButton: NSButton!

    // MARK: - Actions
    @IBAction func textFieldDidChangeAction(_ sender: NSTextField) {
        updateAdminURLPlaceholder()
        saveAndCloseButton.isEnabled = false
    }

    @IBAction func useSSLCheckboxAction(_ sender: NSButton) {
        sslFailSafe()
        updateAdminURLPlaceholder()
        saveAndCloseButton.isEnabled = false
    }

    @IBAction func testConnectionButtonAction(_ sender: NSButton) {
        testConnection()
    }

    @IBAction func saveAndCloseButtonAction(_ sender: NSButton) {
        var adminPanelURL = adminURLTextField.stringValue
        if adminPanelURL.isEmpty {
            adminPanelURL = PiholeConnectionV2.generateAdminPanelURL(
                hostname: hostnameTextField.stringValue,
                port: Int(portTextField.stringValue) ?? 80,
                useSSL: apiTokenTextField.stringValue.isEmpty ? true : false)
        }
        delegate?.savePiholeConnection(PiholeConnectionV2(
            hostname: hostnameTextField.stringValue,
            port: Int(portTextField.stringValue) ?? 80,
            useSSL: useSSLCheckbox.state == .on ? true : false,
            token: apiTokenTextField.stringValue,
            passwordProtected: passwordProtected,
            adminPanelURL: adminPanelURL
        ), at: currentIndex)
        self.dismiss(self)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        adminURLTextField.toolTip = "Only fill this in if you have a custom Admin panel URL you'd like to use instead of the default shown here."
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
            adminURLTextField.stringValue = connection.adminPanelURL
        } else {
            hostnameTextField.stringValue = "pi.hole"
            portTextField.stringValue = "80"
            useSSLCheckbox.state = .off
            apiTokenTextField.stringValue = ""
            adminURLTextField.stringValue = ""
            adminURLTextField.placeholderString = PiholeConnectionV2.generateAdminPanelURL(
                hostname: "pi.hole",
                port: 80,
                useSSL: false
            )
        }
        testConnectionLabel.stringValue = ""
        saveAndCloseButton.isEnabled = false
    }

    // MARK: - Functions

    fileprivate func sslFailSafe() {
        let useSSL = useSSLCheckbox.state == .on ? true : false

        var port = portTextField.stringValue
        if useSSL, port == "80" {
            port = "443"
        } else if !useSSL, port == "443" {
            port = "80"
        }
        portTextField.stringValue = port
    }

    private func updateAdminURLPlaceholder() {
        let adminURLString = PiholeConnectionV2.generateAdminPanelURL(
           hostname: hostnameTextField.stringValue,
           port: Int(portTextField.stringValue) ?? 80,
           useSSL: (useSSLCheckbox.state == .on ? true : false)
       )
       adminURLTextField.placeholderString = "\(adminURLString)"
    }

    func testConnection() {
        Log.debug("Testing connection...")

        testConnectionLabel.stringValue = "Testing... Please wait..."

        let connection = PiholeConnectionV2(
            hostname: hostnameTextField.stringValue,
            port: Int(portTextField.stringValue) ?? 80,
            useSSL: useSSLCheckbox.state == .on ? true : false,
            token: apiTokenTextField.stringValue,
            passwordProtected: passwordProtected,
            adminPanelURL: ""
        )

        let api = PiholeAPI(connection: connection)

        api.testConnection { status in
            switch status {
            case .success:
                self.testConnectionLabel.stringValue = "Success"
                self.saveAndCloseButton.isEnabled = true
                if self.apiTokenTextField.stringValue.isEmpty {
                    self.passwordProtected = false
                } else {
                    self.passwordProtected = true
                }
            case .failure:
                self.testConnectionLabel.stringValue = "Unable to Connect"
                self.saveAndCloseButton.isEnabled = false
            case .failureInvalidToken:
                self.testConnectionLabel.stringValue = "Invalid API Token"
                self.saveAndCloseButton.isEnabled = false
            }
        }
    }
}
