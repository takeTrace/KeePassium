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
import KeePassiumLib

protocol CreateDatabaseVCDelegate: class {
    func databaseCreator(didCreateDatabase urlRef: URLReference)
}

class CreateDatabaseVC: UIViewController {
    private let kdbxExtension = "kdbx" //TODO: maybe move somewhere else?
    
    @IBOutlet weak var fileNameField: ValidatingTextField!
    @IBOutlet weak var passwordField: ValidatingTextField!
    @IBOutlet weak var continueButton: UIButton!
    
    private weak var delegate: CreateDatabaseVCDelegate?
    private var templateFile: TemporaryFileURL?
    
    static func make(delegate: CreateDatabaseVCDelegate?=nil) -> UIViewController {
        let vc = CreateDatabaseVC.instantiateFromStoryboard()
        vc.delegate = delegate
        
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .formSheet
        return navVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fileNameField.delegate = self
        passwordField.delegate = self
        fileNameField.validityDelegate = self
        passwordField.validityDelegate = self
        fileNameField.text = LString.defaultNewDatabaseName
        passwordField.becomeFirstResponder()
        continueButton.isEnabled = false
    }

    // - MARK: Actions
    
    @IBAction func didPressCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressContinue(_ sender: Any) {
        guard let fileNameBase = fileNameField.text else { return }
        
        // Ensure the filename ends with .kdbx
        guard var url = URL(string: fileNameBase) else { return }
        if url.pathExtension != kdbxExtension {
            url.appendPathExtension(kdbxExtension)
        }
        let fileName = url.absoluteString
        
        do {
            templateFile = try TemporaryFileURL(fileName: fileName)
            try Data().write(to: templateFile!.url) //TODO write some real template instead
        } catch {
            Diag.error("Error creating temporary file [message: \(error.localizedDescription)]")
            let alert = UIAlertController.make(
                title: LString.titleError,
                message: error.localizedDescription)
            present(alert, animated: true)
            return
        }
        
        let picker = UIDocumentPickerViewController(url: templateFile!.url, in: .exportToService)
        picker.delegate = self
        picker.modalPresentationStyle = .currentContext
        present(picker, animated: true, completion: nil)
    }
}

extension CreateDatabaseVC: UITextFieldDelegate, ValidatingTextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === fileNameField {
            passwordField.becomeFirstResponder()
        } else if textField === passwordField {
            didPressContinue(self)
        }
        return true
    }
    
    private func isValidFileName(_ text: String?) -> Bool {
        guard let text = text else { return false }
        return text.isNotEmpty
    }
    
    func validatingTextFieldShouldValidate(_ sender: ValidatingTextField) -> Bool {
        if sender === fileNameField {
            return isValidFileName(fileNameField.text)
        } else if sender === passwordField {
            return passwordField.text?.isNotEmpty ?? false
        }
        return false
    }

    func validatingTextField(_ sender: ValidatingTextField, validityDidChange isValid: Bool) {
        continueButton.isEnabled = fileNameField.isValid && passwordField.isValid
    }
}

extension CreateDatabaseVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        FileKeeper.shared.prepareToAddFile(url: url, mode: .openInPlace)
        FileKeeper.shared.processPendingOperations(success: { [weak self] urlRef in
            self?.dismiss(animated: true, completion: nil)
        }, error: { [weak self] (error: FileKeeperError) -> Void in
            let errorAlert = UIAlertController.make(
                title: LString.titleError,
                message: error.localizedDescription)
            self?.present(errorAlert, animated: true, completion: nil)
        })
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        templateFile = nil
    }
}
