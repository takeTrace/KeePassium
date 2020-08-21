//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit
import KeePassiumLib

class ChangeMasterKeyVC: UIViewController {
    @IBOutlet weak var keyboardAdjView: UIView!
    @IBOutlet weak var databaseNameLabel: UILabel!
    @IBOutlet weak var databaseIcon: UIImageView!
    @IBOutlet weak var passwordField: ValidatingTextField!
    @IBOutlet weak var repeatPasswordField: ValidatingTextField!
    @IBOutlet weak var keyFileField: KeyFileTextField!
    @IBOutlet weak var passwordMismatchImage: UIImageView!
    
    private var databaseRef: URLReference!
    private var keyFileRef: URLReference?
    private var yubiKey: YubiKey?
    
    static func make(dbRef: URLReference) -> UIViewController {
        let vc = ChangeMasterKeyVC.instantiateFromStoryboard()
        vc.databaseRef = dbRef
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .formSheet
        return navVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        databaseNameLabel.text = databaseRef.visibleFileName
        databaseIcon.image = databaseRef.getIcon(fileType: .database)
        
        passwordField.invalidBackgroundColor = nil
        repeatPasswordField.invalidBackgroundColor = nil
        keyFileField.invalidBackgroundColor = nil
        passwordField.delegate = self
        passwordField.validityDelegate = self
        repeatPasswordField.delegate = self
        repeatPasswordField.validityDelegate = self
        keyFileField.delegate = self
        keyFileField.validityDelegate = self
        setupHardwareKeyPicker()
        
        view.backgroundColor = UIColor(patternImage: UIImage(asset: .backgroundPattern))
        view.layer.isOpaque = false
        
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordField.becomeFirstResponder()
    }
    
    
    private func setupHardwareKeyPicker() {
        keyFileField.yubikeyHandler = {
            [weak self] (field) in
            guard let self = self else { return }
            let popoverAnchor = PopoverAnchor(
                sourceView: self.keyFileField,
                sourceRect: self.keyFileField.bounds)
            self.showYubiKeyPicker(at: popoverAnchor)
        }
    }
    
    private func showYubiKeyPicker(at popoverAnchor: PopoverAnchor) {
        let hardwareKeyPicker = HardwareKeyPicker.create(delegate: self)
        hardwareKeyPicker.modalPresentationStyle = .popover
        if let popover = hardwareKeyPicker.popoverPresentationController {
            popoverAnchor.apply(to: popover)
            popover.delegate = hardwareKeyPicker.dismissablePopoverDelegate
        }
        hardwareKeyPicker.key = yubiKey
        present(hardwareKeyPicker, animated: true, completion: nil)
    }
    
    
    @IBAction func didPressCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressSaveChanges(_ sender: Any) {
        guard let db = DatabaseManager.shared.database else {
            assertionFailure()
            return
        }
        
        let _challengeHandler = ChallengeResponseManager.makeHandler(for: yubiKey)
        DatabaseManager.createCompositeKey(
            keyHelper: db.keyHelper,
            password: passwordField.text ?? "",
            keyFile: keyFileRef,
            challengeHandler: _challengeHandler,
            success: {
                [weak self] (_ newCompositeKey: CompositeKey) -> Void in
                guard let self = self else { return }
                let dbm = DatabaseManager.shared
                dbm.changeCompositeKey(to: newCompositeKey)
                DatabaseSettingsManager.shared.updateSettings(for: self.databaseRef) {
                    [weak self] (dbSettings) in
                    guard let self = self else { return }
                    dbSettings.maybeSetMasterKey(newCompositeKey)
                    dbSettings.maybeSetAssociatedKeyFile(self.keyFileRef)
                    dbSettings.maybeSetAssociatedYubiKey(self.yubiKey)
                }
                dbm.addObserver(self)
                dbm.startSavingDatabase()
            },
            error: {
                [weak self] (_ errorMessage: String) -> Void in
                guard let _self = self else { return }
                Diag.error("Failed to create new composite key [message: \(errorMessage)]")
                let errorAlert = UIAlertController.make(
                    title: LString.titleError,
                    message: errorMessage)
                _self.present(errorAlert, animated: true, completion: nil)
            }
        )
    }
    
    
    private var progressOverlay: ProgressOverlay?
    fileprivate func showProgressOverlay() {
        progressOverlay = ProgressOverlay.addTo(
            view, title: LString.databaseStatusSaving, animated: true)
        progressOverlay?.isCancellable = true
        
        if #available(iOS 13, *) {
            isModalInPresentation = true
        }
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.hidesBackButton = true
    }
    
    fileprivate func hideProgressOverlay() {
        progressOverlay?.dismiss(animated: true) {
            [weak self] finished in
            guard let self = self else { return }
            self.progressOverlay?.removeFromSuperview()
            self.progressOverlay = nil
        }
        if #available(iOS 13, *) {
            isModalInPresentation = false
        }
        navigationItem.leftBarButtonItem?.isEnabled = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        navigationItem.hidesBackButton = false
    }
}

extension ChangeMasterKeyVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case passwordField:
            repeatPasswordField.becomeFirstResponder()
        case repeatPasswordField:
            if repeatPasswordField.isValid {
                didPressSaveChanges(self)
            } else {
                repeatPasswordField.shake()
                passwordMismatchImage.shake()
            }
        default:
            break
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField === keyFileField {
            passwordField.becomeFirstResponder()
            let keyFileChooserVC = ChooseKeyFileVC.make(
                popoverSourceView: keyFileField,
                delegate: self)
            present(keyFileChooserVC, animated: true, completion: nil)
        }
    }
}

extension ChangeMasterKeyVC: ValidatingTextFieldDelegate {
    func validatingTextFieldShouldValidate(_ sender: ValidatingTextField) -> Bool {
        switch sender {
        case passwordField, keyFileField:
            let gotPassword = passwordField.text?.isNotEmpty ?? false
            let gotKeyFile = keyFileRef != nil
            return gotPassword || gotKeyFile
        case repeatPasswordField:
            let isPasswordsMatch = (passwordField.text == repeatPasswordField.text)
            UIView.animate(withDuration: 0.5) {
                self.passwordMismatchImage.alpha = isPasswordsMatch ? 0.0 : 1.0
            }
            return isPasswordsMatch
        default:
            return true
        }
    }
    
    func validatingTextField(_ sender: ValidatingTextField, textDidChange text: String) {
        if sender === passwordField {
            repeatPasswordField.validate()
        }
    }
    
    func validatingTextField(_ sender: ValidatingTextField, validityDidChange isValid: Bool) {
        let allValid = passwordField.isValid && repeatPasswordField.isValid && keyFileField.isValid
        navigationItem.rightBarButtonItem?.isEnabled = allValid
    }
}

extension ChangeMasterKeyVC: KeyFileChooserDelegate {
    func onKeyFileSelected(urlRef: URLReference?) {
        keyFileRef = urlRef
        DatabaseSettingsManager.shared.updateSettings(for: databaseRef) { (dbSettings) in
            dbSettings.maybeSetAssociatedKeyFile(keyFileRef)
        }
        
        guard let keyFileRef = urlRef else {
            keyFileField.text = ""
            return
        }
        
        if let error = keyFileRef.error {
            keyFileField.text = ""
            showErrorAlert(error)
        } else {
            keyFileField.text = keyFileRef.visibleFileName
        }
    }
}

extension ChangeMasterKeyVC: HardwareKeyPickerDelegate {
    func didDismiss(_ picker: HardwareKeyPicker) {
    }
    func didSelectKey(yubiKey: YubiKey?, in picker: HardwareKeyPicker) {
        setYubiKey(yubiKey)
    }
    
    func setYubiKey(_ yubiKey: YubiKey?) {
        self.yubiKey = yubiKey
        keyFileField.isYubiKeyActive = (yubiKey != nil)

        DatabaseSettingsManager.shared.updateSettings(for: databaseRef) { (dbSettings) in
            dbSettings.maybeSetAssociatedYubiKey(yubiKey)
        }
        if let _yubiKey = yubiKey {
            Diag.info("Hardware key selected [key: \(_yubiKey)]")
        } else {
            Diag.info("No hardware key selected")
        }
    }
}

extension ChangeMasterKeyVC: DatabaseManagerObserver {
    func databaseManager(willSaveDatabase urlRef: URLReference) {
        showProgressOverlay()
    }
    
    func databaseManager(didSaveDatabase urlRef: URLReference) {
        DatabaseManager.shared.removeObserver(self)
        hideProgressOverlay()
        let parentVC = presentingViewController
        dismiss(animated: true, completion: {
            let alert = UIAlertController.make(
                title: LString.databaseStatusSavingDone,
                message: LString.masterKeySuccessfullyChanged,
                cancelButtonTitle: LString.actionOK)
            parentVC?.present(alert, animated: true, completion: nil)
        })
    }
    
    func databaseManager(progressDidChange progress: ProgressEx) {
        progressOverlay?.update(with: progress)
    }
    
    func databaseManager(database urlRef: URLReference, isCancelled: Bool) {
        Diag.info("Master key change cancelled")
        DatabaseManager.shared.removeObserver(self)
        hideProgressOverlay()
    }
    
    func databaseManager(
        database urlRef: URLReference,
        savingError message: String,
        reason: String?)
    {
        let errorAlert = UIAlertController.make(title: message, message: reason)
        present(errorAlert, animated: true, completion: nil)
        
        DatabaseManager.shared.removeObserver(self)
        hideProgressOverlay()
    }
}
