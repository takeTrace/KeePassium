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
                passcodeTextField.selectAll(nil)
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
