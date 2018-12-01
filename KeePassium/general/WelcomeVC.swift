//
//  WelcomeVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-05-31.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

/// Shown on first run of the app, provides user onboarding.
class WelcomeVC: UIViewController {
    static func make() -> UIViewController {
        let vc = WelcomeVC.instantiateFromStoryboard()
        let navVC = UINavigationController(rootViewController: vc)
        return navVC
    }
    
    @IBAction func didPressCreateDatabase(_ sender: Any) {
        let vc = CreateDatabaseVC.make()
        navigationController?.popViewController(animated: true)
        parent?.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func didPressOpenDatabase(_ sender: Any) {
        let picker = UIDocumentPickerViewController(documentTypes: FileType.databaseUTIs, in: .open)
        picker.delegate = self
        picker.modalPresentationStyle = .pageSheet
        present(picker, animated: true, completion: nil)
    }
}


extension WelcomeVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        switch controller.documentPickerMode {
        case .open:
            FileKeeper.shared.prepareToAddFile(url: url, mode: .openInPlace)
        case .import:
            FileKeeper.shared.prepareToAddFile(url: url, mode: .import)
        default:
            assertionFailure("Unexpected document picker mode")
        }
        processPendingFileOperations()
    }
    
    private func processPendingFileOperations() {
        FileKeeper.shared.processPendingOperations(
            success: {
                [weak self] addedRef in
                Settings.current.startupDatabase = addedRef
                // pop this VC with its embedded NavVC
                self?.navigationController?
                    .navigationController?
                    .popViewController(animated: false) //FIXME: refactor this ugliness
            },
            error: {
                [weak self] error in
                let alert = UIAlertController.make(
                    title: LString.titleError,
                    message: error.localizedDescription)
                self?.present(alert, animated: true, completion: nil)
            }
        )
    }
}
