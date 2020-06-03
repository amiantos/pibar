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
            }
        }
    }

    @IBOutlet weak var networkOverviewView: NetworkOverviewView!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 38.5, height: 38.5)).cgPath
        networkOverviewView.layer.mask = maskLayer
        networkOverviewView.clipsToBounds = true
    
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
        networkOverview = network
    }
}

extension MainViewController: UITableViewDelegate {

}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let networkOverview = self.networkOverview else { return 0 }

        return networkOverview.piholes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "piholeCell", for: indexPath)

        return cell
    }


}
