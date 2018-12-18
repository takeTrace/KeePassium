//
//  PasscodeEntryScreen.swift
//  KeePassium AutoFill
//
//  Created by Andrei Popleteev on 2018-12-17.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import KeePassiumLib

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
    @IBOutlet weak var keyboardTypeSegments: UISegmentedControl!
    
    weak var delegate: PasscodeEntryScreenDelegate?
    private var isBiometricAuthShown = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make background image
        view.backgroundColor = UIColor(patternImage: UIImage(asset: .backgroundPattern))
        view.layer.isOpaque = false
        
        passcodeTextField.delegate = self
        
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didPressCancelButton))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        passcodeTextField.becomeFirstResponder()
    }
    
    private func showError(message: String) {
        errorMessageLabel.isHidden = false
        errorMessageLabel.text = message
    }
    
    // MARK: - Actions
    
    @IBAction func didPressCancelButton(_ sender: Any) {
        delegate?.passcodeEntryScreenShouldCancel(self)
    }
    
    @IBAction func didPressUnlockButton(_ sender: Any) {
        let passcode = passcodeTextField.text ?? ""
        do {
            let isOK = try Keychain.shared.isAppPasscodeMatch(passcode) // throws KeychainError
            if isOK {
                delegate?.passcodeEntryScreenDidUnlock(self)
            } else {
                passcodeTextField.shake()
            }
        } catch {
            Diag.error("Keychain error [message: \(error.localizedDescription)]")
            showError(message: error.localizedDescription)
        }
    }
}

extension PasscodeEntryScreenVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didPressUnlockButton(textField)
        return false
    }
}
