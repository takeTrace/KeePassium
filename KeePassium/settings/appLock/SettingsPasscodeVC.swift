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

class SettingsPasscodeVC: UITableViewController {
    @IBOutlet weak var passcodeField: ValidatingTextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var clearPasscodeCell: UITableViewCell!
    
    typealias CompletionHandler = (()->Void)
    private var completionHandler: CompletionHandler?
    
    
    /// Returns a new instance of this VC.
    ///
    /// - Parameter completion: called when the VC needs to be dismissed.
    /// - Returns: VC instance.
    public static func make(completion: @escaping(CompletionHandler)) -> SettingsPasscodeVC {
        let vc = SettingsPasscodeVC.instantiateFromStoryboard()
        vc.completionHandler = completion
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        passcodeField.delegate = self
        passcodeField.validityDelegate = self
        passcodeField.invalidBackgroundColor = nil // don't change color when invalid (only disable the Done button)
        passcodeField.validate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passcodeField.becomeFirstResponder()
        if let isPasscodeSet = try? AppLockManager.shared.isPasscodeSet() { // throws KeychainError
            clearPasscodeCell.setEnabled(isPasscodeSet)
        }
    }
    
    @IBAction func didPressCancel(_ sender: Any) {
        completionHandler?()
    }
    
    @IBAction func didPressDone(_ sender: Any) {
        setPasscodeAndDismiss(passcode: passcodeField.text)
    }
    
    /// Saves changes and dismisses the VC.
    /// - Parameters
    ///     passcode: if `nil`, the passcode is removed from the keychain.
    fileprivate func setPasscodeAndDismiss(passcode: String?) {
        do {
            if let passcode = passcode {
                try AppLockManager.shared.setPasscode(passcode: passcode) // throws KeychainError
            } else {
                try AppLockManager.shared.resetPasscode() // throws KeychainError
            }
            completionHandler?()
        } catch {
            let errorAlert = UIAlertController.make(
                title: LString.titleKeychainError,
                message: error.localizedDescription,
                cancelButtonTitle: LString.actionDismiss)
            present(errorAlert, animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let selectedCell = tableView.cellForRow(at: indexPath) else { return }
        if selectedCell === clearPasscodeCell {
            setPasscodeAndDismiss(passcode: nil)
        }
    }
}

extension SettingsPasscodeVC: ValidatingTextFieldDelegate {
    func validatingTextFieldShouldValidate(_ sender: ValidatingTextField) -> Bool {
        let text = (sender.text ?? "").trimmingCharacters(in: CharacterSet.whitespaces)
        return text.isNotEmpty
    }
    
    func validatingTextField(_ sender: ValidatingTextField, validityDidChange isValid: Bool) {
        doneButton.isEnabled = passcodeField.isValid
    }
}

extension SettingsPasscodeVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if passcodeField.isValid {
            setPasscodeAndDismiss(passcode: passcodeField.text)
            return true
        } else {
            return false
        }
    }
}
