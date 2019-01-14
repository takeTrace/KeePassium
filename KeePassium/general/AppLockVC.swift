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

public class AppLockVC: UIViewController {
    @IBOutlet weak var textField: UITextField! // not watchdog aware - unlocking is not an activity
    @IBOutlet weak var unlockButton: UIButton!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    private var errorMessage: String?
    override public var canResignFirstResponder: Bool { return false }
    
    static public func make(message: String? = nil) -> AppLockVC {
        let vc = AppLockVC.instantiateFromStoryboard()
        vc.errorMessage = message
        print("AppLockVC created")
        return vc
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        if let errorMessage = errorMessage {
            errorMessageLabel.text = errorMessage
            errorMessageLabel.isHidden = false
        } else {
            errorMessageLabel.isHidden = true
        }

        print("AppLockVC loaded")
        textField.delegate = self
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("AppLockVC appeared")
        let isShowing = AppLockManager.shared.maybeShowBiometricAuth()
        {
            [weak self] (isAuthSuccess) in
            if !isAuthSuccess {
                // biometric authentication failed, so show the old faithful keyboard
                self?.textField.becomeFirstResponder()
            }
        }
        if !isShowing {
            textField.becomeFirstResponder()
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("AppLockVC disappeared")
    }
    
    @IBAction func didPressUnlockButton(_ sender: Any) {
        tryToUnlockWithPasscode()
    }
    
    private func tryToUnlockWithPasscode() {
        let alm = AppLockManager.shared
        let passcode = textField.text ?? ""
        do {
            if try alm.isPasscodeMatch(passcode: passcode) { // throws KeychainError
                textField.text = "" // clean up
                doUnlock()
            } else {
                textField.shake()
                textField.selectAll(nil)
            }
        } catch { // KeychainError
            let errorAlert = UIAlertController.make(
                title: LString.titleError,
                message: error.localizedDescription,
                cancelButtonTitle: LString.actionDismiss)
            present(errorAlert, animated: true, completion: nil)
        }
    }

    /// Unconditionally unlocks the app.
    private func doUnlock() {
        AppLockManager.shared.unlock()
        Watchdog.default.restart()
    }
}

extension AppLockVC: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tryToUnlockWithPasscode()
        return true
    }
}
