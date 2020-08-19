//
//  AddDeviceTableViewController.swift
//  PiBar for iOS
//
//  Created by Brad Root on 8/18/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit

class AddDeviceTableViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet var hostnameTextField: UITextField!
    @IBOutlet var portTextField: UITextField!

    @IBOutlet var useSSLStatusLabel: UILabel!

    @IBOutlet var apiTokenTextField: UITextField!
    @IBOutlet var adminURLTextField: UITextField!

    @IBOutlet var testingStatusLabel: UILabel!

    @IBOutlet var testButton: UIButton!
    @IBAction func testButtonAction(_: UIButton) {}

    override func viewDidLoad() {
        super.viewDidLoad()

        testButton.layer.cornerRadius = testButton.frame.height / 2

        adminURLTextField.delegate = self
        apiTokenTextField.delegate = self
        hostnameTextField.delegate = self
        portTextField.delegate = self

        portTextField.addDoneButtonOnKeyboard()
    }

    // TextFields

    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    // TableView

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 2, section: 0) {
            // Selected "Use SSL" cell
        } else if indexPath == IndexPath(row: 1, section: 1) {
            // Selected "Where do I find my API token?"
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
