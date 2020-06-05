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
    private var networkOverview: PiholeNetworkOverview? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.tableView.layoutSubviews()
            }
        }
    }

    @IBOutlet var networkOverviewView: NetworkOverviewView!
    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        networkOverviewView.manager = manager

        Preferences.standard.set(piholes: [
            PiholeConnectionV2(
                hostname: "pi-hole.local",
                port: 80,
                useSSL: false,
                token: "",
                passwordProtected: false,
                adminPanelURL: "http://pi-hole.local/admin"
            ),
            PiholeConnectionV2(
                hostname: "rickenbacker.local",
                port: 80,
                useSSL: false,
                token: "b17660b345e1871a06177e27b06404cd10088d3e19f5d4248b8b349e14f127b8",
                passwordProtected: true,
                adminPanelURL: "http://rickenbacker.local/admin"
            ),
        ])

        manager.delegate = self

        manager.loadConnections()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.contentInset.bottom = networkOverviewView.frame.height - view.safeAreaInsets.bottom + 10
        if UIDevice.current.userInterfaceIdiom == .phone {
            // I like how insets look on iPhone, but not iPad
            tableView.scrollIndicatorInsets.bottom = networkOverviewView.frame.height - view.safeAreaInsets.bottom
        }
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
        networkOverview = network
    }
}

extension MainViewController: UITableViewDelegate {}

extension MainViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let networkOverview = self.networkOverview else { return 0 }

        return networkOverview.piholes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let piholes = networkOverview?.piholes,
            let cell = tableView.dequeueReusableCell(withIdentifier: "piholeCell", for: indexPath) as? PiholeTableViewCell else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "piholeCell", for: indexPath)
            return cell
        }

        let piholeIdentifiersAlphabetized: [String] = piholes.keys.sorted()

        cell.pihole = piholes[piholeIdentifiersAlphabetized[indexPath.row]]

        if let overTimeData = networkOverview?.overTimeData,
            let piholeData = overTimeData.piholes[piholeIdentifiersAlphabetized[indexPath.row]] {
            cell.chartData = (overTimeData.maximumValue, piholeData)
        }

        return cell
    }
}
