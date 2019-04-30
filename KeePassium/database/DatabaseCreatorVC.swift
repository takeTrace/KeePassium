//
//  DatabaseCreatorVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2019-04-27.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

protocol DatabaseCreatorDelegate: class {
    func didPressCancel(in databaseCreatorVC: DatabaseCreatorVC)
    func didPressContinue(in databaseCreatorVC: DatabaseCreatorVC)
    func didPressPickKeyFile(in databaseCreatorVC: DatabaseCreatorVC, popoverSource: UIView)
}

class DatabaseCreatorVC: UITableViewController {

    public var databaseFileName: String { return fileNameField.text ?? "" }
    public var password: String { return passwordField.text ?? ""}
    public var keyFile: URLReference? {
        didSet {
            showKeyFile(keyFile)
        }
    }

    @IBOutlet weak var fileNameField: ValidatingTextField!
    @IBOutlet weak var passwordField: ProtectedTextField!
    @IBOutlet weak var keyFileField: WatchdogAwareTextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet var errorWrapperView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    weak var delegate: DatabaseCreatorDelegate?
    
    private enum SectionID: Int {
        case fileName = 0
        case masterKey = 1
    }
    private var progressOverlay: ProgressOverlay?
    
    public static func create() -> DatabaseCreatorVC {
        return DatabaseCreatorVC.instantiateFromStoryboard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LString.titleCreateDatabase
        
        errorLabel.text = nil // hide error message
        
        fileNameField.validityDelegate = self
        passwordField.validityDelegate = self
        keyFileField.delegate = self
    }

    private func showKeyFile(_ keyFile: URLReference?) {
        guard let info = keyFile?.getInfo() else {
            keyFileField.text = nil
            return
        }
        
        if info.hasError {
            keyFileField.text = info.errorMessage
            keyFileField.textColor = .errorMessage
        } else {
            keyFileField.text = info.fileName
            keyFileField.textColor = .primaryText
        }
        setError(message: nil)
    }
    
    func setError(message: String?) {
        errorLabel.text = message
        tableView.reloadSections([SectionID.masterKey.rawValue], with: .automatic)
    }
    
    // MARK: - Table view data source
    
    override func tableView(
        _ tableView: UITableView,
        viewForFooterInSection section: Int
        ) -> UIView?
    {
        guard section == SectionID.masterKey.rawValue else {
            return super.tableView(tableView, viewForFooterInSection: section)
        }
        
        let hasError = (errorLabel.text?.isNotEmpty ?? false)
        if hasError {
            return errorWrapperView
        } else {
            return super.tableView(tableView, viewForFooterInSection: section)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func didPressCancel(_ sender: Any) {
        delegate?.didPressCancel(in: self)
    }
    
    @IBAction func didPressContinue(_ sender: Any) {
        let hasPassword = passwordField.text?.isNotEmpty ?? false
        guard hasPassword || (keyFile != nil) else {
            setError(message: NSLocalizedString("Please enter a password or choose a key file.", comment: "Hint shown when both password and key file are empty."))
            return
        }
        delegate?.didPressContinue(in: self)
    }
}

extension DatabaseCreatorVC: ValidatingTextFieldDelegate {
    func validatingTextFieldShouldValidate(_ sender: ValidatingTextField) -> Bool {
        guard let text = sender.text else { return false }
        switch sender {
        case fileNameField:
            return text.isNotEmpty && !text.contains("/")
        case passwordField:
            return true
        default:
            return true
        }
    }
    func validatingTextField(_ sender: ValidatingTextField, textDidChange text: String) {
        if sender === passwordField {
            setError(message: nil)
        }
    }
}

extension DatabaseCreatorVC: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === keyFileField {
            setError(message: nil)
            passwordField.becomeFirstResponder()
            delegate?.didPressPickKeyFile(in: self, popoverSource: textField)
            return false
        }
        return true
    }
}

// MARK: - ProgressViewHost
extension DatabaseCreatorVC: ProgressViewHost {
    
    func showProgressView(title: String, allowCancelling: Bool) {
        if progressOverlay != nil {
            // something is already shown, just update it
            progressOverlay?.title = title
            progressOverlay?.isCancellable = allowCancelling
            return
        }
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem?.isEnabled = false
        continueButton.isEnabled = false
        progressOverlay = ProgressOverlay.addTo(
            self.view,
            title: title,
            animated: true)
        progressOverlay?.isCancellable = allowCancelling
    }
    
    func updateProgressView(with progress: ProgressEx) {
        progressOverlay?.update(with: progress)
    }
    
    func hideProgressView() {
        guard progressOverlay != nil else { return }
        navigationItem.hidesBackButton = false
        navigationItem.rightBarButtonItem?.isEnabled = true
        continueButton.isEnabled = true
        progressOverlay?.dismiss(animated: true) {
            [weak self] (finished) in
            guard let _self = self else { return }
            _self.progressOverlay?.removeFromSuperview()
            _self.progressOverlay = nil
        }
    }
}
