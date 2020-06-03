//
//  MainViewController.swift
//  PiBar for iOS
//
//  Created by Brad Root on 6/2/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    private let manager: PiBarManager = PiBarManager()

    @IBOutlet weak var networkOverviewView: NetworkOverviewView!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        networkOverviewView.layer.cornerRadius = 50
        networkOverviewView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        networkOverviewView.clipsToBounds = true

        networkOverviewView.manager = manager

        Preferences.standard.set(piholes: [PiholeConnectionV2(
            hostname: "pi-hole.local",
            port: 80,
            useSSL: false,
            token: "",
            passwordProtected: false,
            adminPanelURL: "http://pi-hole.local/admin"
            )])

        manager.delegate = self

        manager.loadConnections()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.contentInset.bottom = networkOverviewView.frame.height - 25
        tableView.scrollIndicatorInsets.bottom = networkOverviewView.frame.height - 60
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MainViewController: PiBarManagerDelegate {
    func updateNetwork(_ network: PiholeNetworkOverview) {
        networkOverviewView.networkOverview = network
    }
}

extension MainViewController: UITableViewDelegate {

}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "piholeCell", for: indexPath)

        return cell
    }


}
