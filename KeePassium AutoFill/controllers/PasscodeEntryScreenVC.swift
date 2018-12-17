//
//  PasscodeEntryScreen.swift
//  KeePassium AutoFill
//
//  Created by Andrei Popleteev on 2018-12-17.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import KeePassiumLib
import LocalAuthentication

protocol PasscodeEntryScreenDelegate: class {
    /// Called when the user passes TouchID/FaceID check or enters correct passcode
    func passcodeEntryScreenDidUnlock(_ sender: PasscodeEntryScreenVC)
    /// Called when the user presses "Cancel"
    func passcodeEntryScreenShouldCancel(_ sender: PasscodeEntryScreenVC)
}

class PasscodeEntryScreenVC: UIViewController {

    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var passcodeTextField: PasswordTextField!
    @IBOutlet weak var unlockButton: UIButton!
    
    weak var delegate: PasscodeEntryScreenDelegate?
    private var isBiometricAuthShown = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didPressCancelButton))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let isUsingBiometrics = maybeShowBiometricAuth() {
            [weak self] (successful) in
            guard let _self = self else { return }
            if successful {
                _self.delegate?.passcodeEntryScreenDidUnlock(_self)
            } else {
                _self.passcodeTextField.becomeFirstResponder()
            }
        }
        
        if !isUsingBiometrics {
            passcodeTextField.becomeFirstResponder()
        }
    }
    
    private func showError(message: String) {
        errorMessageLabel.isHidden = false
        errorMessageLabel.text = message
    }
    
    /// Shows biometric authentication UI, if supported and enabled.
    ///
    /// - Parameter completion: called after biometric authentication,
    ///         with a `Bool` parameter indicating success of the bioauth.
    /// - Returns: `true` if biometric authentication is shown, `false` otherwise.
    open func maybeShowBiometricAuth(completion: @escaping ((Bool) -> Void)) -> Bool {
        guard Settings.current.isBiometricAppLockEnabled else { return false }
        guard !isBiometricAuthShown else { return false }
        
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        context.localizedFallbackTitle = "" // hide "Enter Password" fallback; nil won't work
        
        let isBiometricsAvailable = context.canEvaluatePolicy(policy, error: nil)
        if isBiometricsAvailable {
            Diag.debug("Biometric auth: showing request")
            context.evaluatePolicy(policy, localizedReason: LString.titleTouchID) {
                [unowned self] (authSuccessful, authError) in
                self.isBiometricAuthShown = false
                if authSuccessful {
                    Diag.info("Biometric auth successful")
                    DispatchQueue.main.async {
                        completion(true)
                    }
                } else {
                    if let error = authError {
                        self.showError(message: error.localizedDescription)
                        Diag.warning("Biometric auth failed [error: \(error.localizedDescription)]")
                    } else {
                        Diag.error("Biometric auth failed [error: nil]")
                    }
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
            isBiometricAuthShown = true
        }
        return isBiometricAuthShown
    }
    
    
    // MARK: - Actions
    
    @objc func didPressCancelButton(_ sender: Any) {
        delegate?.passcodeEntryScreenShouldCancel(self)
    }
    
    @IBAction func didChangePasscodeField(_ sender: Any) {
        unlockButton.isEnabled = passcodeTextField.text?.isNotEmpty ?? false
    }
    
    @IBAction func didPressUnlockButton(_ sender: Any) {
        let passcode = passcodeTextField.text ?? ""
        do {
            let isOK = try Keychain.shared.isAppPasscodeMatch(passcode) // throws KeychainError
            if isOK {
                delegate?.passcodeEntryScreenDidUnlock(self)
            } else {
//                showError(message: LString.NSLocalizedString("Try again", comment: "Shown when entered app passcode is wrong"))
                passcodeTextField.shake()
            }
        } catch {
            Diag.error("Keychain error [message: \(error.localizedDescription)]")
            showError(message: error.localizedDescription)
        }
    }
    
}
