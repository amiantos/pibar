//
//  PiholeV6SettingsViewController.swift
//  PiBar
//
//  Created by Brad Root on 3/16/25.
//  Copyright © 2025 Brad Root. All rights reserved.
//

import Cocoa

protocol PiholeV6SettingsViewControllerDelegate: AnyObject {
    func savePiholeV3Connection(_ connection: PiholeConnectionV3, at index: Int)
}

class PiholeV6SettingsViewController: NSViewController {
    var connection: PiholeConnectionV3?
    var currentIndex: Int = -1
    weak var delegate: PiholeV6SettingsViewControllerDelegate?

    var passwordProtected: Bool = true
    var validSidToken: String = ""

    // MARK: - Outlets

    @IBOutlet var hostnameTextField: NSTextField!
    @IBOutlet var portTextField: NSTextField!
    @IBOutlet var useSSLCheckbox: NSButton!

    @IBOutlet var adminURLTextField: NSTextField!


    @IBOutlet weak var totpTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet var testConnectionLabel: NSTextField!
    @IBOutlet var saveAndCloseButton: NSButton!
    @IBOutlet var closeButton: NSButton!

    // MARK: - Actions

    @IBAction func textFieldDidChangeAction(_: NSTextField) {
        updateAdminURLPlaceholder()
        saveAndCloseButton.isEnabled = false
    }

    @IBAction func useSSLCheckboxAction(_: NSButton) {
        sslFailSafe()
        updateAdminURLPlaceholder()
        saveAndCloseButton.isEnabled = false
    }

    @IBAction func authenticateRequestAction(_ sender: NSButton) {
        guard let password = passwordTextField.stringValue as? String else { return }
        let totp: Int? = Int(totpTextField.stringValue) ?? nil
        Log.debug("Authenticating connection...")

        testConnectionLabel.stringValue = "Authenticating..."

        let connection = PiholeConnectionV3(
            hostname: hostnameTextField.stringValue,
            port: Int(portTextField.stringValue) ?? 80,
            useSSL: useSSLCheckbox.state == .on ? true : false,
            token: "",
            passwordProtected: passwordProtected,
            adminPanelURL: "",
            isV6: false
        )

        let api = Pihole6API(connection: connection)
        
        Task {
            do {
                let result = try await api.checkPassword(password: password, totp: totp)
                if result.session.valid, let token = result.session.sid {
                    self.validSidToken = token
                    self.testConnectionLabel.stringValue = "Authenticated!"
                    self.saveAndCloseButton.isEnabled = true
                } else if result.session.valid {
                    self.validSidToken = ""
                    self.passwordProtected = false
                    self.testConnectionLabel.stringValue = "Authenticated!"
                    self.saveAndCloseButton.isEnabled = true
                }
            } catch {
                Log.error(error)
                self.testConnectionLabel.stringValue = "Error"
                self.saveAndCloseButton.isEnabled = false
            }
        }
        
    }
    
    @IBAction func testConnectionButtonAction(_: NSButton) {
        testConnection()
    }

    @IBAction func saveAndCloseButtonAction(_: NSButton) {
        var adminPanelURL = adminURLTextField.stringValue
        if adminPanelURL.isEmpty {
            adminPanelURL = PiholeConnectionV3.generateAdminPanelURL(
                hostname: hostnameTextField.stringValue,
                port: Int(portTextField.stringValue) ?? 80,
                useSSL: useSSLCheckbox.state == .on ? true : false
            )
        }
        delegate?.savePiholeV3Connection(PiholeConnectionV3(
            hostname: hostnameTextField.stringValue,
            port: Int(portTextField.stringValue) ?? 80,
            useSSL: useSSLCheckbox.state == .on ? true : false,
            token: self.validSidToken,
            passwordProtected: passwordProtected,
            adminPanelURL: adminPanelURL,
            isV6: true
        ), at: currentIndex)
        dismiss(self)
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
//            apiTokenTextField.stringValue = connection.token
            adminURLTextField.stringValue = connection.adminPanelURL
        } else {
            hostnameTextField.stringValue = "pi.hole"
            portTextField.stringValue = "80"
            useSSLCheckbox.state = .off
//            apiTokenTextField.stringValue = ""
            adminURLTextField.stringValue = ""
            adminURLTextField.placeholderString = PiholeConnectionV3.generateAdminPanelURL(
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
        let adminURLString = PiholeConnectionV3.generateAdminPanelURL(
            hostname: hostnameTextField.stringValue,
            port: Int(portTextField.stringValue) ?? 80,
            useSSL: useSSLCheckbox.state == .on ? true : false
        )
        adminURLTextField.placeholderString = "\(adminURLString)"
    }

    func testConnection() {
        Log.debug("Testing connection...")

        testConnectionLabel.stringValue = "Testing... Please wait..."

        let connection = PiholeConnectionV3(
            hostname: hostnameTextField.stringValue,
            port: Int(portTextField.stringValue) ?? 80,
            useSSL: useSSLCheckbox.state == .on ? true : false,
            token: "",
            passwordProtected: passwordProtected,
            adminPanelURL: "",
            isV6: false
        )

        let api = PiholeAPI(connection: connection)

        api.testConnection { status in
            switch status {
            case .success:
                self.testConnectionLabel.stringValue = "Success"
                self.saveAndCloseButton.isEnabled = true
//                if self.apiTokenTextField.stringValue.isEmpty {
//                    self.passwordProtected = false
//                } else {
//                    self.passwordProtected = true
//                }
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
