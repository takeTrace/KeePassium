//
//  SettingsClipboardTimeoutVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-07-06.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

class SettingsClipboardTimeoutVC: UITableViewController, Refreshable {
    private let cellID = "Cell"
    
    public static func make() -> UIViewController {
        return SettingsClipboardTimeoutVC.instantiateFromStoryboard()
    }

    func refresh() {
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Settings.ClipboardTimeout.allValues.count
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("When you copy some text from an entry, the app will automatically clear your clipboard (pasteboard) after this time.", comment: "[Settings/Pasteboard Timeout/Footer]")
    }
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let timeout = Settings.ClipboardTimeout.allValues[indexPath.row]
        cell.textLabel?.text = timeout.fullTitle
        if timeout == Settings.current.clipboardTimeout {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let timeout = Settings.ClipboardTimeout.allValues[indexPath.row]
        Settings.current.clipboardTimeout = timeout
        refresh()
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
