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
import LaunchAtLogin


protocol PreferencesDelegate: AnyObject {
    func updatedPreferences()
    func updatedConnections()
}

class PreferencesViewController: NSViewController {
    weak var delegate: PreferencesDelegate?

    lazy var piholeSheetController: PiholeSettingsViewController? = {
        guard let controller = self.storyboard!.instantiateController(
            withIdentifier: "piHoleDialog"
        ) as? PiholeSettingsViewController else {
            return nil
        }
        return controller
    }()
    
    lazy var piholeV6SheetController: PiholeV6SettingsViewController? = {
        guard let controller = self.storyboard!.instantiateController(
            withIdentifier: "piHoleDialogV6"
        ) as? PiholeV6SettingsViewController else {
            return nil
        }
        return controller
    }()

    // MARK: - Outlets

    @IBOutlet var tableView: NSTableView!

    @IBOutlet var showBlockedCheckbox: NSButton!
    @IBOutlet var showQueriesCheckbox: NSButton!
    @IBOutlet var showPercentageCheckbox: NSButton!

    @IBOutlet var showLabelsCheckbox: NSButton!
    @IBOutlet var verboseLabelsCheckbox: NSButton!

    @IBOutlet var shortcutEnabledCheckbox: NSButton!
    @IBOutlet var launchAtLogincheckbox: NSButton!
    @IBOutlet var pollingRateTextField: NSTextField!

    @IBOutlet var editButton: NSButton!
    @IBOutlet var removeButton: NSButton!

    // MARK: - Actions

    @IBAction func addButtonActiom(_: NSButton) {
        let alert = NSAlert()
        alert.messageText = "Pi-hole Version"
        alert.informativeText = "What version of Pi-hole would you like to add?"
        alert.alertStyle = .warning
        
        // Adding buttons
        alert.addButton(withTitle: "Pi-hole v6+") // Index 0
        alert.addButton(withTitle: "Pi-hole v5 or earlier") // Index 1
        alert.addButton(withTitle: "Cancel")   // Index 2

        // Display alert and handle response
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            newPihole()
        case .alertSecondButtonReturn:
            legacyVersion()
        case .alertThirdButtonReturn:
            handleCancel()
        default:
            break
        }
    }
    
    func newPihole() {
        guard let controller = piholeV6SheetController else { return }
        controller.delegate = self
        controller.connection = nil
        controller.currentIndex = -1
        presentAsSheet(controller)
    }
    
    func legacyVersion() {
        guard let controller = piholeSheetController else { return }
        controller.delegate = self
        controller.connection = nil
        controller.currentIndex = -1
        presentAsSheet(controller)
    }
    
    func handleCancel() {
        print("Cancel selected")
        // Handle cancellation if needed
    }

    @IBAction func editButtonAction(_: NSButton) {
        if tableView.selectedRow >= 0 {
            let pihole = Preferences.standard.piholes[tableView.selectedRow]
            if pihole.isV6 {
                guard let controller = piholeV6SheetController else { return }
                controller.delegate = self
                controller.connection = pihole
                controller.currentIndex = tableView.selectedRow
                presentAsSheet(controller)
            } else {
                guard let controller = piholeSheetController else { return }
                controller.delegate = self
                controller.connection = pihole
                controller.currentIndex = tableView.selectedRow
                presentAsSheet(controller)
            }
        }
    }

    @IBAction func removeButtonAction(_: NSButton) {
        var piholes = Preferences.standard.piholes
        piholes.remove(at: tableView.selectedRow)
        tableView.removeRows(at: tableView.selectedRowIndexes, withAnimation: .slideUp)
        Preferences.standard.set(piholes: piholes)
        if piholes.isEmpty {
            removeButton.isEnabled = false
            editButton.isEnabled = false
        }
        delegate?.updatedConnections()
    }

    @IBAction func checkboxAction(_: NSButtonCell) {
        saveSettings()
    }
    
    @IBAction func launchAtLoginAction(_ sender: NSButton) {
        
    }
    
    @IBAction func pollingRateTextFieldAction(_: NSTextField) {
        saveSettings()
    }

    @IBAction func saveAndCloseButtonAction(_: NSButton) {
        saveSettings()
        view.window?.close()
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()

        shortcutEnabledCheckbox.toolTip = "This shortcut allows you to easily enable and disable your Pi-hole(s)"

        pollingRateTextField.toolTip = "Polling rate cannot be less than 3 seconds"
    }

    func updateUI() {
        Log.debug("Updating Preferences UI")

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
        
        launchAtLogincheckbox.state = LaunchAtLogin.isEnabled ? .on : .off

        pollingRateTextField.stringValue = "\(Preferences.standard.pollingRate)"
    }

    // MARK: - Functions

    func saveSettings() {
        Preferences.standard.set(showBlocked: showBlockedCheckbox.state == .on ? true : false)
        Preferences.standard.set(showQueries: showQueriesCheckbox.state == .on ? true : false)
        Preferences.standard.set(showPercentage: showPercentageCheckbox.state == .on ? true : false)

        if showLabelsCheckbox.state == .off {
            verboseLabelsCheckbox.state = .off
        }

        Preferences.standard.set(showLabels: showLabelsCheckbox.state == .on ? true : false)
        Preferences.standard.set(verboseLabels: verboseLabelsCheckbox.state == .on ? true : false)

        Preferences.standard.set(shortcutEnabled: shortcutEnabledCheckbox.state == .on ? true : false)
        
        if launchAtLogincheckbox.state == .on {
            LaunchAtLogin.isEnabled = true
        } else {
            LaunchAtLogin.isEnabled = false
        }


        let input = pollingRateTextField.stringValue
        if let intValue = Int(input), intValue >= 3 {
            Preferences.standard.set(pollingRate: intValue)
        } else {
            pollingRateTextField.stringValue = "\(Preferences.standard.pollingRate)"
        }

        delegate?.updatedPreferences()

        updateUI()
    }
}

extension PreferencesViewController: PiholeSettingsViewControllerDelegate {
    func savePiholeConnection(_ connection: PiholeConnectionV3, at index: Int) {
        var piholes = Preferences.standard.piholes
        if index == -1 {
            piholes.append(connection)
            Preferences.standard.set(piholes: piholes)
            let newRowIndexSet = IndexSet(integer: piholes.count - 1)
            tableView.insertRows(at: newRowIndexSet, withAnimation: .slideDown)
            tableView.selectRowIndexes(newRowIndexSet, byExtendingSelection: false)
        } else {
            piholes[index] = connection
            Preferences.standard.set(piholes: piholes)
            tableView.reloadData()
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
        delegate?.updatedConnections()
    }
}

extension PreferencesViewController: PiholeV6SettingsViewControllerDelegate {
    func savePiholeV3Connection(_ connection: PiholeConnectionV3, at index: Int) {
        var piholes = Preferences.standard.piholes
        if index == -1 {
            piholes.append(connection)
            Preferences.standard.set(piholes: piholes)
            let newRowIndexSet = IndexSet(integer: piholes.count - 1)
            tableView.insertRows(at: newRowIndexSet, withAnimation: .slideDown)
            tableView.selectRowIndexes(newRowIndexSet, byExtendingSelection: false)
        } else {
            piholes[index] = connection
            Preferences.standard.set(piholes: piholes)
            tableView.reloadData()
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
        delegate?.updatedConnections()
    }
}

// MARK: - TableView Data Source

extension PreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        let numberOfRows = Preferences.standard.piholes.count
        if numberOfRows > 0 {
            editButton.isEnabled = true
            removeButton.isEnabled = true
        } else {
            removeButton.isEnabled = false
            editButton.isEnabled = false
        }
        return numberOfRows
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
        } else if tableColumn == tableView.tableColumns[2] {
            text = pihole.isV6 ? ">=6" : "<6"
            cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "versionCell")
        }
        if let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }

    func tableViewSelectionDidChange(_: Notification) {
        editButton.isEnabled = true
        removeButton.isEnabled = true
    }
}
