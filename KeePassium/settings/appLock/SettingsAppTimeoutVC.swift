//
//  SettingsAppTimeoutVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-07-15.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

class SettingsAppTimeoutVC: UITableViewController, Refreshable {
    private let cellID = "Cell"
    
    public static func make() -> UIViewController {
        return SettingsAppTimeoutVC.instantiateFromStoryboard()
    }
    
    func refresh() {
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Settings.AppLockTimeout.allValues.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let timeout = Settings.AppLockTimeout.allValues[indexPath.row]
        cell.textLabel?.text = timeout.fullTitle
        cell.detailTextLabel?.text = timeout.description
        if timeout == Settings.current.appLockTimeout {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let timeout = Settings.AppLockTimeout.allValues[indexPath.row]
        Settings.current.appLockTimeout = timeout
        Watchdog.default.restart() // apply the change
        refresh()
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
