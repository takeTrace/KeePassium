//
//  SettingsDatabaseTimeoutVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-07-06.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

class SettingsDatabaseTimeoutVC: UITableViewController, Refreshable {
    private let cellID = "Cell"
    
    public static func make() -> UIViewController {
        return SettingsDatabaseTimeoutVC.instantiateFromStoryboard()
    }
    
    func refresh() {
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Settings.DatabaseCloseTimeout.allValues.count
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 0 else { return nil }
        return NSLocalizedString("If you are not interacting with the app for some time, the database will be closed for your safety. To open it, you will need to enter its master password again.", comment: "[Settings/Database Timeout/Footer]")
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let timeout = Settings.DatabaseCloseTimeout.allValues[indexPath.row]
        cell.textLabel?.text = timeout.fullTitle
        cell.detailTextLabel?.text = timeout.description
        if timeout == Settings.current.databaseCloseTimeout {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let timeout = Settings.DatabaseCloseTimeout.allValues[indexPath.row]
        Settings.current.databaseCloseTimeout = timeout
        Watchdog.default.restart() // apply the change
        refresh()
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
