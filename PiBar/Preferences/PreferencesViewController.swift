//
//  PreferencesViewController.swift
//  PiBar
//
//  Created by Brad Root on 5/17/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa

protocol PreferencesDelegate: AnyObject {
    func updatedPreferences()
    func updatedConnections()
}

class PreferencesViewController: NSViewController {
    weak var delegate: PreferencesDelegate?

    // MARK: - Outlets

    @IBOutlet var tableView: NSTableView!

    @IBOutlet var testLabel: NSTextField!
    @IBOutlet var testButton: NSButton!

    @IBOutlet var hostnameTextField: NSTextField!
    @IBOutlet var portTextField: NSTextField!
    @IBOutlet var tokenTextField: NSTextField!
    @IBOutlet var useSSLCheckbox: NSButton!

    @IBOutlet var showBlockedCheckbox: NSButton!
    @IBOutlet var showQueriesCheckbox: NSButton!
    @IBOutlet var showPercentageCheckbox: NSButton!

    @IBOutlet var showLabelsCheckbox: NSButton!
    @IBOutlet var verboseLabelsCheckbox: NSButton!

    @IBOutlet var shortcutEnabledCheckbox: NSButton!

    @IBOutlet var removeButton: NSButton!
    @IBOutlet var saveButton: NSButton!

    // MARK: - Actions

    @IBAction func addButtonActiom(_: NSButton) {
        var piholes = Preferences.standard.piholes
        piholes.append(PiholeConnection(hostname: "pi-hole.local", port: 80, useSSL: false, token: ""))
        Preferences.standard.set(piholes: piholes)
        let newRowIndexSet = IndexSet(integer: piholes.count - 1)
        tableView.insertRows(at: newRowIndexSet, withAnimation: .slideDown)
        tableView.selectRowIndexes(newRowIndexSet, byExtendingSelection: false)
        delegate?.updatedConnections()
    }

    @IBAction func removeButtonAction(_: NSButton) {
        var piholes = Preferences.standard.piholes
        piholes.remove(at: tableView.selectedRow)
        tableView.removeRows(at: tableView.selectedRowIndexes, withAnimation: .slideUp)
        Preferences.standard.set(piholes: piholes)
        delegate?.updatedConnections()
    }

    @IBAction func textFieldChangedAction(_: NSTextField) {
        saveButton.isEnabled = false
        saveButton.toolTip = "Test connection to save changes."
        testLabel.stringValue = ""
        sslFailSafe()
    }

    @IBAction func useSSLCheckboxAction(_: NSButton) {
        sslFailSafe()
    }

    @IBAction func saveButtonAction(_: Any) {
        let selectedIndex = tableView.selectedRow
        var piholes = Preferences.standard.piholes

        piholes[selectedIndex] = PiholeConnection(
            hostname: hostnameTextField.stringValue,
            port: Int(portTextField.stringValue) ?? 80,
            useSSL: useSSLCheckbox.state == .on ? true : false,
            token: tokenTextField.stringValue
        )

        Preferences.standard.set(piholes: piholes)
        tableView.reloadData()
        tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
        delegate?.updatedConnections()
    }

    @IBAction func checkboxAction(_: NSButtonCell) {
        saveSettings()
    }

    @IBAction func testButtonAction(_: NSButton) {
        testConnection()
    }

    @IBAction func linkAction(_: NSButton) {
        let url = URL(string: "https://github.com/amiantos/pibar")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()

        loadDataFromTable()

        tokenTextField.toolTip = "Get your API token from Pi-hole: Settings -> API / Web Interface -> Show API token"
        shortcutEnabledCheckbox.toolTip = "This shortcut allows you to easily enable and disable your Pi-hole(s)"
    }

    func updateUI() {
        showBlockedCheckbox.state = Preferences.standard.showBlocked ? .on : .off
        showQueriesCheckbox.state = Preferences.standard.showQueries ? .on : .off
        showPercentageCheckbox.state = Preferences.standard.showPercentage ? .on : .off

        showLabelsCheckbox.state = Preferences.standard.showLabels ? .on : .off
        verboseLabelsCheckbox.state = Preferences.standard.verboseLabels ? .on : .off

        if !Preferences.standard.showTitle {
            showLabelsCheckbox.isEnabled = false
            verboseLabelsCheckbox.isEnabled = false
        } else {
            showLabelsCheckbox.isEnabled = true
            verboseLabelsCheckbox.isEnabled = showLabelsCheckbox.state == .on ? true : false
        }
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

    func saveSettings() {
        testLabel.stringValue = ""

        Preferences.standard.set(showBlocked: showBlockedCheckbox.state == .on ? true : false)
        Preferences.standard.set(showQueries: showQueriesCheckbox.state == .on ? true : false)
        Preferences.standard.set(showPercentage: showPercentageCheckbox.state == .on ? true : false)

        if showLabelsCheckbox.state == .off {
            verboseLabelsCheckbox.state = .off
        }

        Preferences.standard.set(showLabels: showLabelsCheckbox.state == .on ? true : false)
        Preferences.standard.set(verboseLabels: verboseLabelsCheckbox.state == .on ? true : false)

        Preferences.standard.set(shortcutEnabled: shortcutEnabledCheckbox.state == .on ? true : false)

        delegate?.updatedPreferences()

        updateUI()
    }

    func testConnection() {
        let connection = PiholeConnection(
            hostname: hostnameTextField.stringValue,
            port: Int(portTextField.stringValue) ?? 80,
            useSSL: useSSLCheckbox.state == .on ? true : false,
            token: tokenTextField.stringValue
        )

        let api = PiholeAPI(connection: connection)

        api.testConnection { status in
            switch status {
            case .success:
                self.testLabel.stringValue = "Success!"
                self.saveButton.isEnabled = true
            case .successNoToken:
                self.testLabel.stringValue = "Success (No Admin)"
                self.saveButton.isEnabled = true
            case .failure:
                self.testLabel.stringValue = "Failure (No Connection)"
                self.saveButton.isEnabled = false
            case .failureInvalidToken:
                self.testLabel.stringValue = "Failure (Invalid Token)"
                self.saveButton.isEnabled = false
            }
        }
    }
}

// MARK: - TableView Data Source

extension PreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return Preferences.standard.piholes.count
    }
}

// MARK: - TableView Delegate

extension PreferencesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        var cellIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "")

        let pihole = Preferences.standard.piholes[row]
        if tableColumn == tableView.tableColumns[0] {
            text = pihole.hostname
            cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "hostnameCell")
        } else if tableColumn == tableView.tableColumns[1] {
            text = "\(pihole.port)"
            cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "portCell")
        }
        if let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }

    fileprivate func loadDataFromTable() {
        if tableView.selectedRow >= 0 {
            let pihole = Preferences.standard.piholes[tableView.selectedRow]
            hostnameTextField.stringValue = pihole.hostname
            portTextField.stringValue = "\(pihole.port)"
            tokenTextField.stringValue = pihole.token
            useSSLCheckbox.state = pihole.useSSL ? .on : .off

            hostnameTextField.isEnabled = true
            portTextField.isEnabled = true
            tokenTextField.isEnabled = true
            useSSLCheckbox.isEnabled = true

            removeButton.isEnabled = true
            testButton.isEnabled = true
            saveButton.isEnabled = false
            saveButton.toolTip = "Test connection to save changes."
            testLabel.stringValue = ""
        } else {
            hostnameTextField.stringValue = ""
            portTextField.stringValue = ""
            tokenTextField.stringValue = ""
            useSSLCheckbox.state = .off

            hostnameTextField.isEnabled = false
            portTextField.isEnabled = false
            tokenTextField.isEnabled = false
            useSSLCheckbox.isEnabled = false

            removeButton.isEnabled = false
            testButton.isEnabled = false
            saveButton.isEnabled = false
            saveButton.toolTip = nil

            testLabel.stringValue = ""
        }
    }

    func tableViewSelectionDidChange(_: Notification) {
        loadDataFromTable()
    }
}
