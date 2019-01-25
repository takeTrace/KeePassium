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
import LocalAuthentication
import KeePassiumLib

class SettingsAppLockVC: UITableViewController, Refreshable {
    @IBOutlet weak var appLockEnabledSwitch: UISwitch!
    @IBOutlet weak var biometricsCell: UITableViewCell!
    @IBOutlet weak var appLockTimeoutCell: UITableViewCell!
    @IBOutlet weak var biometricsSwitch: UISwitch!
    @IBOutlet weak var biometricsLabel: UILabel!
    @IBOutlet weak var biometricsIcon: UIImageView!
    
    private var settingsNotifications: SettingsNotifications!
    private var isBiometricsSupported = false
    private var passcodeInputVC: PasscodeInputVC?
    
    // Table section numbers
    private enum Sections: Int {
        case passcode = 0
        case timeout = 1
        case biometrics = 2
    }
    
    public static func make() -> UIViewController {
        return SettingsAppLockVC.instantiateFromStoryboard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsNotifications = SettingsNotifications(observer: self)
        settingsNotifications.startObserving()
        clearsSelectionOnViewWillAppear = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkBiometricsSupport()
        refresh()
    }
    
    private func checkBiometricsSupport() {
        let context = LAContext()
        isBiometricsSupported =
            context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil)
        if !isBiometricsSupported {
            Settings.current.isBiometricAppLockEnabled = false
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.biometrics.rawValue && !isBiometricsSupported {
            // Hide biometric section content when not supported by hardware
            return 0
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(
        _ tableView: UITableView,
        titleForFooterInSection section: Int
        ) -> String?
    {
        if section == Sections.biometrics.rawValue && !isBiometricsSupported {
            // Hide biometric section footer when not supported by hardware
            return nil
        }
        return super.tableView(tableView, titleForFooterInSection: section)
    }
    
    func refresh() {
        let settings = Settings.current
        let isAppLockEnabled = settings.isAppLockEnabled
        appLockEnabledSwitch.isOn = isAppLockEnabled
        appLockTimeoutCell.detailTextLabel?.text = settings.appLockTimeout.shortTitle
        biometricsSwitch.isOn = settings.isBiometricAppLockEnabled
        
        appLockTimeoutCell.setEnabled(isAppLockEnabled)
        biometricsCell.setEnabled(isAppLockEnabled)
        biometricsSwitch.isEnabled = isAppLockEnabled
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCell = tableView.cellForRow(at: indexPath) else { return }
        switch selectedCell {
        case appLockTimeoutCell:
            let timeoutVC = SettingsAppTimeoutVC.make()
            show(timeoutVC, sender: self)
        default:
            assertionFailure("Unexpected cell selected")
        }
    }
    
    @IBAction func didChangeAppLockEnabledSwitch(_ sender: Any) {
        if !appLockEnabledSwitch.isOn {
            Settings.current.isAppLockEnabled = false
            do {
                try Keychain.shared.removeAppPasscode() // throws `KeychainError`
            } catch {
                Diag.error(error.localizedDescription)
                let alert = UIAlertController.make(
                    title: LString.titleKeychainError,
                    message: error.localizedDescription)
                present(alert, animated: true, completion: nil)
            }
        } else {
            // The user wants to enable App Lock, so we ask for passcode first
            passcodeInputVC = PasscodeInputVC.instantiateFromStoryboard()
            passcodeInputVC!.delegate = self
            passcodeInputVC!.mode = .setup
            present(passcodeInputVC!, animated: true, completion: nil)
        }
    }
    
    @IBAction func didToggleBiometricsSwitch(_ sender: Any) {
        Settings.current.isBiometricAppLockEnabled = biometricsSwitch.isOn
    }
}

extension SettingsAppLockVC: SettingsObserver {
    func settingsDidChange(key: Settings.Keys) {
        switch key {
        case .appLockEnabled, .appLockTimeout, .biometricAppLockEnabled:
            refresh()
        default:
            break
        }
    }
}

extension SettingsAppLockVC: PasscodeInputDelegate {
    func passcodeInputDidCancel(_ sender: PasscodeInputVC) {
        Settings.current.isAppLockEnabled = false
        passcodeInputVC?.dismiss(animated: true, completion: nil)
    }
    
    func passcodeInput(_sender: PasscodeInputVC, canAcceptPasscode passcode: String) -> Bool {
        return passcode.count > 0
    }
    
    func passcodeInput(_ sender: PasscodeInputVC, didEnterPasscode passcode: String) {
        passcodeInputVC?.dismiss(animated: true) {
            [weak self] in
            do {
                try Keychain.shared.setAppPasscode(passcode)
                Settings.current.isAppLockEnabled = true
            } catch {
                Diag.error(error.localizedDescription)
                let alert = UIAlertController.make(
                    title: LString.titleKeychainError,
                    message: error.localizedDescription)
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
}
