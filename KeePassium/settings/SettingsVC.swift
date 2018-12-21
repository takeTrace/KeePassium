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

class SettingsVC: UITableViewController, Refreshable {
    @IBOutlet weak var startWithSearchSwitch: UISwitch!

    @IBOutlet weak var appLockCell: UITableViewCell!
    @IBOutlet weak var databaseTimeoutCell: UITableViewCell!
    @IBOutlet weak var clipboardTimeoutCell: UITableViewCell!

    @IBOutlet weak var rememberKeyFilesSwitch: UISwitch!

    @IBOutlet weak var makeBackupsSwitch: UISwitch!

    @IBOutlet weak var diagnosticLogCell: UITableViewCell!
    @IBOutlet weak var contactSupportCell: UITableViewCell!
    @IBOutlet weak var rateTheAppCell: UITableViewCell!
    @IBOutlet weak var aboutAppCell: UITableViewCell!
    
    private var settingsNotifications: SettingsNotifications!
    
    static func make(popoverFromBar barButtonSource: UIBarButtonItem?=nil) -> UIViewController {
        let vc = SettingsVC.instantiateFromStoryboard()
        
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .popover
        if let popover = navVC.popoverPresentationController {
            popover.barButtonItem = barButtonSource
        }
        return navVC
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        settingsNotifications = SettingsNotifications(observer: self)
        settingsNotifications.startObserving()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    func dismissPopover(animated: Bool) {
        navigationController?.dismiss(animated: animated, completion: nil)
    }
    
    func refresh() {
        let settings = Settings.current
        startWithSearchSwitch.isOn = settings.isStartWithSearch
        rememberKeyFilesSwitch.isOn = settings.isKeepKeyFileAssociations
        makeBackupsSwitch.isOn = settings.isBackupDatabaseOnSave
        appLockCell.detailTextLabel?.text = getAppLockStatus()
        databaseTimeoutCell.detailTextLabel?.text = settings.databaseCloseTimeout.shortTitle
        clipboardTimeoutCell.detailTextLabel?.text = settings.clipboardTimeout.shortTitle
    }
    
    /// Returns App Lock status description: needs passcode/timeout/error
    private func getAppLockStatus() -> String {
        do {
            let isPasscodeSet = try AppLockManager.shared.isPasscodeSet() // throws KeychainError
            if isPasscodeSet {
                return Settings.current.appLockTimeout.shortTitle
            } else {
                return LString.statusAppLockIsDisabled
            }
        } catch { // KeychainError
            return LString.titleKeychainError
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let selectedCell = tableView.cellForRow(at: indexPath) else { return }
        switch selectedCell {
        case appLockCell:
            let appLockSettingsVC = SettingsAppLockVC.make()
            show(appLockSettingsVC, sender: self)
        case databaseTimeoutCell:
            let databaseTimeoutSettingsVC = SettingsDatabaseTimeoutVC.make()
            show(databaseTimeoutSettingsVC, sender: self)
        case clipboardTimeoutCell:
            let clipboardTimeoutSettingsVC = SettingsClipboardTimeoutVC.make()
            show(clipboardTimeoutSettingsVC, sender: self)
        case diagnosticLogCell:
            let viewer = ViewDiagnosticsVC.make()
            present(viewer, animated: true, completion: nil) //TODO: change to show()?
        case contactSupportCell:
            SupportEmailComposer.show(includeDiagnostics: false)
        case rateTheAppCell:
            AppStoreReviewHelper.writeReview()
        case aboutAppCell:
            let aboutVC = AboutVC.make()
            navigationController?.pushViewController(aboutVC, animated: true)//TODO: change to show()?
//            present(aboutVC, animated: true, completion: nil)
        default:
            assertionFailure("Unexpected cell selection")
        }
    }
    
    // MARK: Actions
    @IBAction func doneButtonTapped(_ sender: Any) {
        dismissPopover(animated: true)
    }
    
    @IBAction func didChangeStartWithSearch(_ sender: Any) {
        Settings.current.isStartWithSearch = startWithSearchSwitch.isOn
        refresh()
    }
    @IBAction func didChangeRememberKeyFiles(_ sender: Any) {
        Settings.current.isKeepKeyFileAssociations = rememberKeyFilesSwitch.isOn
        refresh()
    }
    
    @IBAction func didChangeMakeBackups(_ sender: Any) {
        Settings.current.isBackupDatabaseOnSave = makeBackupsSwitch.isOn
        refresh()
    }
}

extension SettingsVC: SettingsObserver {
    func settingsDidChange(key: Settings.Keys) {
        refresh()
    }
}

