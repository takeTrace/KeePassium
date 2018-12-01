//
//  SettingsAppLockVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-08-03.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import LocalAuthentication
import KeePassiumLib

class SettingsAppLockVC: UITableViewController, Refreshable {
    @IBOutlet weak var passcodeCell: UITableViewCell!
    @IBOutlet weak var biometricsCell: UITableViewCell!
    @IBOutlet weak var appLockTimeoutCell: UITableViewCell!
    @IBOutlet weak var biometricsSwitch: UISwitch!
    @IBOutlet weak var biometricsLabel: UILabel!
    @IBOutlet weak var biometricsIcon: UIImageView!
    
    private var settingsNotifications: SettingsNotifications!
    private var isBiometricsSupported = false
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
        appLockTimeoutCell.detailTextLabel?.text = settings.appLockTimeout.shortTitle
        biometricsSwitch.isOn = settings.isBiometricAppLockEnabled
        
        // Disable timeout cell when passcode is not set.
        // (plus keychain error handling)
        let isPasscodeSet: Bool
        do {
            isPasscodeSet = try AppLockManager.shared.isPasscodeSet() // throws KeychainError
            if isPasscodeSet {
                passcodeCell.detailTextLabel?.text = LString.statusPasscodeSet
            } else {
                passcodeCell.detailTextLabel?.text = LString.statusPasscodeNotSet
            }
            passcodeCell.detailTextLabel?.textColor = UIColor.secondaryText
        } catch { // KeychainError
            passcodeCell.detailTextLabel?.text = LString.titleKeychainError
            passcodeCell.detailTextLabel?.textColor = UIColor.errorMessage
            
            let alert = UIAlertController.make(
                title: LString.titleKeychainError,
                message: error.localizedDescription)
            present(alert, animated: true, completion: nil)
            isPasscodeSet = false
        }
        appLockTimeoutCell.setEnabled(isPasscodeSet)
        biometricsCell.setEnabled(isPasscodeSet)
        biometricsCell.contentView.alpha = isPasscodeSet ? 1.0 : 0.44 // simulate disabled view
        biometricsSwitch.isEnabled = isPasscodeSet
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCell = tableView.cellForRow(at: indexPath) else { return }
        switch selectedCell {
        case passcodeCell:
            let passcodeVC = SettingsPasscodeVC.make(completion: {
                [unowned self] in
                self.navigationController?.popToViewController(self, animated: true)
            })
            show(passcodeVC, sender: self)
        case appLockTimeoutCell:
            let timeoutVC = SettingsAppTimeoutVC.make()
            show(timeoutVC, sender: self)
        default:
            assertionFailure("Unexpected cell selected")
        }
    }
    @IBAction func didToggleBiometricsSwitch(_ sender: Any) {
        Settings.current.isBiometricAppLockEnabled = biometricsSwitch.isOn
    }
}

extension SettingsAppLockVC: SettingsObserver {
    func settingsDidChange(key: Settings.Keys) {
        switch key {
        case .appLockTimeout, .biometricAppLockEnabled:
            refresh()
        default:
            break
        }
    }
}
