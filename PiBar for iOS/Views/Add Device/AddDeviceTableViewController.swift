//
//  AddDeviceTableViewController.swift
//  PiBar for iOS
//
//  Created by Brad Root on 8/18/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit

protocol AddDeviceDelegate: AnyObject {
    func updatedConnections()
}

class AddDeviceTableViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBAction func saveButtonAction(_: UIBarButtonItem) {
        let hostname = (hostnameTextField.text == "" ? "pi.hole" : hostnameTextField.text) ?? "pi.hole" // swiftlint:disable empty_string
        let port = Int(portTextField.text ?? "80") ?? 80
        var adminPanelURL = adminURLTextField.text ?? ""
        var apiToken = ""
        if let token = apiTokenTextField.text {
            if !token.isEmpty {
                passwordProtected = true
                apiToken = token
            }
        }

        if adminPanelURL.isEmpty {
            adminPanelURL = PiholeConnectionV2.generateAdminPanelURL(
                hostname: hostname,
                port: port,
                useSSL: useSSLStatus
            )
        }

        let connection = PiholeConnectionV2(
            hostname: hostname,
            port: port,
            useSSL: useSSLStatus,
            token: apiToken,
            passwordProtected: passwordProtected,
            adminPanelURL: adminPanelURL
        )

        var piholes = Preferences.standard.piholes
        piholes.append(connection)
        Preferences.standard.set(piholes: piholes)
        delegate?.updatedConnections()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelButtonAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBOutlet var hostnameTextField: UITextField!
    @IBOutlet var portTextField: UITextField!

    @IBOutlet var useSSLStatusLabel: UILabel!

    @IBOutlet var apiTokenTextField: UITextField!
    @IBOutlet var adminURLTextField: UITextField!

    @IBOutlet var testingStatusLabel: UILabel!

    @IBOutlet var testButton: UIButton!
    @IBAction func testButtonAction(_: UIButton) {
        testConnection()
    }

    private var useSSLStatus: Bool = false

    private var passwordProtected: Bool = true

    weak var delegate: AddDeviceDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        testButton.layer.cornerRadius = testButton.frame.height / 2

        adminURLTextField.delegate = self
        apiTokenTextField.delegate = self
        hostnameTextField.delegate = self
        portTextField.delegate = self
    }

    // TextFields

    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    func textFieldDidEndEditing(_: UITextField) {
        updateAdminURLPlaceholder()
        saveButton.isEnabled = false
        sslFailSafe()
    }

    func textFieldDidBeginEditing(_: UITextField) {
        saveButton.isEnabled = false
    }

    // TableView

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 2, section: 0) {
            // Selected "Use SSL" cell
            showUseSSLAlert()
        } else if indexPath == IndexPath(row: 1, section: 1) {
            // Selected "Where do I find my API token?"
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension AddDeviceTableViewController {
    private func updateAdminURLPlaceholder() {
        let adminURLString = PiholeConnectionV2.generateAdminPanelURL(
            hostname: (hostnameTextField.text == "" ? "pi.hole" : hostnameTextField.text) ?? "pi.hole",
            port: Int(portTextField.text ?? "80") ?? 80,
            useSSL: useSSLStatus
        )
        adminURLTextField.placeholder = "\(adminURLString)"
    }

    private func showUseSSLAlert() {
        var alertStyle = UIAlertController.Style.actionSheet
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertStyle = UIAlertController.Style.alert
        }
        let actionSheet = UIAlertController(
            title: "Use SSL?",
            message: "Select whether this connection should use SSL or not.",
            preferredStyle: alertStyle
        )
        let actionOn = UIAlertAction(title: "Yes", style: .default) { _ in
            self.useSSLStatus = true
            self.useSSLStatusLabel.text = "Yes"
            self.portTextField.placeholder = "443"
            self.sslFailSafe()
            self.updateAdminURLPlaceholder()
        }
        let actionOff = UIAlertAction(title: "No", style: .default) { _ in
            self.useSSLStatus = false
            self.useSSLStatusLabel.text = "No"
            self.portTextField.placeholder = "80"
            self.updateAdminURLPlaceholder()
            self.sslFailSafe()
        }
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        actionSheet.addAction(actionOn)
        actionSheet.addAction(actionOff)
        actionSheet.addAction(actionCancel)

        present(actionSheet, animated: true, completion: nil)
    }

    private func showTokenHelp() {
        // TODO:
    }

    fileprivate func sslFailSafe() {
        var port = portTextField.text
        if useSSLStatus, port == "80" {
            port = "443"
        } else if !useSSLStatus, port == "443" {
            port = "80"
        }
        portTextField.text = port
    }

    func testConnection() {
        Log.debug("Testing Connection...")

        testingStatusLabel.text = "Testing... Please wait..."

        var passwordProtected = false
        var apiToken = ""
        if let token = apiTokenTextField.text {
            if token != "" {
                passwordProtected = true
                apiToken = token
            }
        }

        let connection = PiholeConnectionV2(
            hostname: (hostnameTextField.text == "" ? "pi.hole" : hostnameTextField.text) ?? "pi.hole",
            port: Int(portTextField.text ?? "80") ?? 80,
            useSSL: useSSLStatus,
            token: apiToken,
            passwordProtected: passwordProtected,
            adminPanelURL: ""
        )

        let api = PiholeAPI(connection: connection)

        api.testConnection { status in
            switch status {
            case .success:
                self.testingStatusLabel.text = "Success!"
                self.saveButton.isEnabled = true
            case .failure:
                self.testingStatusLabel.text = "Unable to Connect"
                self.saveButton.isEnabled = false
            case .failureInvalidToken:
                self.testingStatusLabel.text = "Invalid API Token"
                self.saveButton.isEnabled = false
            }
        }
    }
}

extension UITextField {
    @IBInspectable var doneAccessory: Bool {
        get {
            return self.doneAccessory
        }
        set(hasDone) {
            if hasDone {
                addDoneButtonOnKeyboard()
            }
        }
    }

    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction() {
        resignFirstResponder()
    }
}
