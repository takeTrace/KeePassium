//
//  SettingsItemListVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-07-07.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

class SettingsItemListVC: UITableViewController, Refreshable {
    private let cellID = "Cell"
    private enum Section: Int {
        static let allValues = [groupSorting, entrySubtitle]
        case entrySubtitle = 0
        case groupSorting = 1
        var title: String? {
            switch self {
            case .groupSorting:
                return NSLocalizedString("Sort Order", comment: "Title of list with group sorting settings")
            case .entrySubtitle:
                return NSLocalizedString("Entry Subtitle", comment: "Title of list with settings: which details to show below entries")
            }
        }
    }
    
    static func make(barPopoverSource: UIBarButtonItem?) -> UIViewController {
        let vc = SettingsItemListVC.instantiateFromStoryboard()
        
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .popover
        if let popover = navVC.popoverPresentationController {
            popover.barButtonItem = barPopoverSource
        }
        return navVC
    }

    func refresh() {
        tableView.reloadData()
    }
    
    // MARK: - Action handlers
    
    @IBAction func didPressDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allValues.count
    }

    override func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
        ) -> String?
    {
        guard let section = Section(rawValue: section) else {
            return nil
        }
        return section.title
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            return 0
        }
        switch section {
        case .groupSorting:
            return Settings.GroupSortOrder.allValues.count
        case .entrySubtitle:
            return Settings.EntryListDetail.allValues.count
        }
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        guard let section = Section(rawValue: indexPath.section) else {
            assertionFailure()
            return cell
        }
        switch section {
        case .groupSorting:
            let groupSorting = Settings.GroupSortOrder.allValues[indexPath.row]
            cell.textLabel?.text = groupSorting.longTitle
            if groupSorting == Settings.current.groupSortOrder {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        case .entrySubtitle:
            let entrySubtitle = Settings.EntryListDetail.allValues[indexPath.row]
            cell.textLabel?.text = entrySubtitle.longTitle
            if entrySubtitle == Settings.current.entryListDetail {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else {
            assertionFailure()
            return
        }
        
        switch section {
        case .groupSorting:
            Settings.current.groupSortOrder = Settings.GroupSortOrder.allValues[indexPath.row]
        case .entrySubtitle:
            Settings.current.entryListDetail = Settings.EntryListDetail.allValues[indexPath.row]
        }
        refresh()
//        dismiss(animated: true, completion: nil)
    }
}
