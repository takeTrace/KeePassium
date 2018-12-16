//
//  DatabaseUnlockerVC.swift
//  KeePassium AutoFill
//
//  Created by Andrei Popleteev on 2018-12-13.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import KeePassiumLib

protocol DatabaseUnlockerDelegate: class {
    /// Called when the user presses "Unlock"
    func databaseUnlockerShouldUnlock(
        _ sender: DatabaseUnlockerVC,
        database: URLReference,
        password: String,
        keyFile: URLReference?)
}

class DatabaseUnlockerVC: UIViewController {

    @IBOutlet weak var errorMessagePanel: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var errorDetailsButton: UIButton!
    @IBOutlet weak var databaseLocationIconImage: UIImageView!
    @IBOutlet weak var databaseFileNameLabel: UILabel!
    @IBOutlet weak var inputPanel: UIView!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var keyFileField: UITextField!
    @IBOutlet weak var rememberMasterKeySwitch: UISwitch!
    
    weak var coordinator: MainCoordinator?
    weak var delegate: DatabaseUnlockerDelegate?
    var shouldAutofocus = false
    var databaseRef: URLReference? {
        didSet { refreshDatabaseInfo() }
    }
    var keyFileRef: URLReference? {
        didSet {
            keyFileField.text = keyFileRef?.info.fileName
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rememberMasterKeySwitch.isOn = Settings.current.isRememberDatabaseKey
        
        // make background image
        view.backgroundColor = UIColor(patternImage: UIImage(asset: .backgroundPattern))
        view.layer.isOpaque = false
        
        refreshDatabaseInfo()
        
        keyFileField.delegate = self
        passwordField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
        if shouldAutofocus {
            DispatchQueue.main.async { [weak self] in
                self?.passwordField?.becomeFirstResponder()
            }
        }
    }
    
    func showErrorMessage(text: String) {
        errorMessageLabel.text = text
        errorMessagePanel.isHidden = false
    }
    
    func hideErrorMessage() {
        errorMessageLabel.text = ""
        errorMessagePanel.isHidden = true
    }

    func showMasterKeyInvalid(message: String) {
        showErrorMessage(text: message)
        inputPanel.shake()
    }
    
    private func refreshDatabaseInfo() {
        guard isViewLoaded else { return }
        guard let dbRef = databaseRef else {
            databaseLocationIconImage.image = nil
            databaseFileNameLabel.text = ""
            return
        }
        let fileInfo = dbRef.info
        if let errorMessage = fileInfo.errorMessage {
            databaseFileNameLabel.text = errorMessage
            databaseFileNameLabel.textColor = UIColor.errorMessage
            databaseLocationIconImage.image = nil
        } else {
            databaseFileNameLabel.text = fileInfo.fileName
            databaseFileNameLabel.textColor = UIColor.primaryText
            databaseLocationIconImage.image = UIImage.databaseIcon(for: dbRef)
        }
    }
    
    // MARK: - Progress overlay
    private(set) var progressOverlay: ProgressOverlay?

    public func showProgressOverlay(animated: Bool) {
        progressOverlay = ProgressOverlay.addTo(
            self.view,
            title: LString.databaseStatusLoading,
            animated: animated)
    }
    
    public func updateProgress(with progress: ProgressEx) {
        progressOverlay?.update(with: progress)
    }
    
    public func hideProgressOverlay() {
        progressOverlay?.dismiss(animated: true) {
            [weak self] (finished) in
            guard finished, let _self = self else { return }
            _self.progressOverlay?.removeFromSuperview()
            _self.progressOverlay = nil
        }
    }

    
    // MARK: - Actions
    
    @IBAction func keyFileFieldDidBeginEdit(_ sender: Any) {
    }
    
    @IBAction func didPressErrorDetailsButton(_ sender: Any) {
        coordinator?.showDiagnostics()
    }
    
    @IBAction func didToggleRememberSwitch(_ sender: Any) {
        Settings.current.isRememberDatabaseKey = rememberMasterKeySwitch.isOn
    }
    
    @IBAction func didPressUnlock(_ sender: Any) {
        guard let databaseRef = databaseRef else { return }
        delegate?.databaseUnlockerShouldUnlock(
            self,
            database: databaseRef,
            password: passwordField.text ?? "",
            keyFile: keyFileRef)
        passwordField.text = "" 
    }
}

extension DatabaseUnlockerVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField === keyFileField {
            coordinator?.selectKeyFile()
            passwordField.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === passwordField {
            didPressUnlock(textField)
            return false
        }
        return true // use default behavior
    }
}
