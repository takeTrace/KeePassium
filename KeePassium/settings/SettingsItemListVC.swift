//  KeePassium Password Manager
//  Copyright © 2018 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
