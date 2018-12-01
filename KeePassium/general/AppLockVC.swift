//
//  AppLockVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-07-14.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

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
