//
//  DatabaseCreatorCoordinator.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2019-04-27.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

protocol DatabaseCreatorCoordinatorDelegate: class {
    func didCreateDatabase(
        in databaseCreatorCoordinator: DatabaseCreatorCoordinator,
        database urlRef: URLReference)
    func didPressCancel(in databaseCreatorCoordinator: DatabaseCreatorCoordinator)
}

class DatabaseCreatorCoordinator: NSObject {
    weak var delegate: DatabaseCreatorCoordinatorDelegate?
    
    private let navigationController: UINavigationController
    private weak var initialTopController: UIViewController?
    private let databaseCreatorVC: DatabaseCreatorVC
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.initialTopController = navigationController.topViewController
        
        databaseCreatorVC = DatabaseCreatorVC.create()
        super.init()

        databaseCreatorVC.delegate = self
    }
    
    func start() {
        navigationController.pushViewController(databaseCreatorVC, animated: true)
    }
    
    // MARK: - Database creation procedure

    /// Step 0. Create an app-local temporary empty file
    ///
    /// - Parameter fileName: name of the file to be created
    /// - Returns: URL of the created file
    /// - Throws: some IO error
    private func createEmptyLocalFile(fileName: String) throws -> URL {
        let fileManager = FileManager()
        let docDir = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let tmpDir = try fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: docDir,
            create: true
        )
        let tmpFileURL = tmpDir
            .appendingPathComponent(fileName, isDirectory: false)
            .appendingPathExtension(FileType.DatabaseExtensions.kdbx)
        
        do {
            // remove previous leftovers, if any
            try? fileManager.removeItem(at: tmpFileURL)
            try Data().write(to: tmpFileURL, options: []) // throws some IO error
        } catch {
            Diag.error("Failed to create temporary file [message: \(error.localizedDescription)]")
            throw error
        }
        return tmpFileURL
    }
    
    
    /// Step 1: Make in-memory database, point it to a temporary file
    private func instantiateDatabase(fileName: String) {
        let tmpFileURL: URL
        do {
            tmpFileURL = try createEmptyLocalFile(fileName: fileName)
        } catch {
            databaseCreatorVC.setError(message: error.localizedDescription, animated: true)
            return
        }
        
        DatabaseManager.shared.createDatabase(
            databaseURL: tmpFileURL,
            password: databaseCreatorVC.password,
            keyFile: databaseCreatorVC.keyFile,
            template: { [weak self] (database2) in
                self?.addTemplateItems(to: database2)
            },
            success: { [weak self] in
                self?.startSavingDatabase()
            },
            error: { [weak self] (message) in
                self?.databaseCreatorVC.setError(message: message, animated: true)
            }
        )
    }
    
    /// Step 2: Fill in-memory database with sample groups and entries
    private func addTemplateItems(to rootGroup: Group2) {
        //TODO: add some sample groups/entries
        let group = rootGroup.createGroup()
        group.name = NSLocalizedString("Internet", comment: "Predefined group in a new database")
    }
    
    /// Step 3: Save temporary database
    private func startSavingDatabase() {
        DatabaseManager.shared.addObserver(self)
        DatabaseManager.shared.startSavingDatabase()
    }
    
    /// Step 4: Show picker to move temporary database to its final location
    private func pickTargetLocation(for tmpDatabaseRef: URLReference) {
        do{
            let tmpUrl = try tmpDatabaseRef.resolve() // throws some UIKit error
            let picker = UIDocumentPickerViewController(url: tmpUrl, in: .exportToService)
            picker.modalPresentationStyle = navigationController.modalPresentationStyle
            picker.delegate = self
            databaseCreatorVC.present(picker, animated: true, completion: nil)
        } catch {
            Diag.error("Failed to resolve temporary DB reference [message: \(error.localizedDescription)]")
            databaseCreatorVC.setError(message: error.localizedDescription, animated: true)
        }
    }
    
    /// Step 5: Save final location in FileKeeper
    private func addCreatedDatabase(at finalURL: URL) {
        let fileKeeper = FileKeeper.shared
        fileKeeper.addFile(
            url: finalURL,
            mode: .openInPlace,
            success: { [weak self] (addedRef) in
                guard let _self = self else { return }
                if let initialTopController = _self.initialTopController {
                    _self.navigationController.popToViewController(initialTopController, animated: true)
                }
                _self.delegate?.didCreateDatabase(in: _self, database: addedRef)
            },
            error: { [weak self] (fileKeeperError) in
                Diag.error("Failed to add created file [mesasge: \(fileKeeperError.localizedDescription)]")
                self?.databaseCreatorVC.setError(
                    message: fileKeeperError.localizedDescription,
                    animated: true
                )
            }
        )
    }
}

// MARK: - DatabaseCreatorDelegate
extension DatabaseCreatorCoordinator: DatabaseCreatorDelegate {
    func didPressCancel(in databaseCreatorVC: DatabaseCreatorVC) {
        if let initialTopController = self.initialTopController {
            navigationController.popToViewController(initialTopController, animated: true)
        }
        delegate?.didPressCancel(in: self)
    }
    
    func didPressContinue(in databaseCreatorVC: DatabaseCreatorVC) {
        instantiateDatabase(fileName: databaseCreatorVC.databaseFileName)
    }
    
    func didPressPickKeyFile(in databaseCreatorVC: DatabaseCreatorVC, popoverSource: UIView) {
        //TODO: switch to unified key file pickerd
        let keyFileChooser = ChooseKeyFileVC.make(popoverSourceView: popoverSource, delegate: self)
        navigationController.present(keyFileChooser, animated: true, completion: nil)
    }
}

// MARK: - KeyFileChooserDelegate
extension DatabaseCreatorCoordinator: KeyFileChooserDelegate {
    func onKeyFileSelected(urlRef: URLReference?) {
        databaseCreatorVC.keyFile = urlRef
        databaseCreatorVC.becomeFirstResponder()
    }
}

// MARK: - DatabaseManagerObserver
extension DatabaseCreatorCoordinator: DatabaseManagerObserver {
    func databaseManager(willSaveDatabase urlRef: URLReference) {
        databaseCreatorVC.showProgressView(
            title: LString.databaseStatusSaving,
            allowCancelling: true)
    }
    
    func databaseManager(progressDidChange progress: ProgressEx) {
        databaseCreatorVC.updateProgressView(with: progress)
    }
    
    func databaseManager(didSaveDatabase urlRef: URLReference) {
        DatabaseManager.shared.removeObserver(self)
        databaseCreatorVC.hideProgressView()
        DatabaseManager.shared.closeDatabase(
            completion: { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    self?.pickTargetLocation(for: urlRef)
                }
            },
            clearStoredKey: true
        )
    }
    
    func databaseManager(database urlRef: URLReference, isCancelled: Bool) {
        DatabaseManager.shared.removeObserver(self)
        DatabaseManager.shared.abortDatabaseCreation()
        self.databaseCreatorVC.hideProgressView()
    }
    
    func databaseManager(database urlRef: URLReference, savingError message: String, reason: String?) {
        DatabaseManager.shared.removeObserver(self)
        DatabaseManager.shared.abortDatabaseCreation()
        databaseCreatorVC.hideProgressView()
        if let reason = reason {
            databaseCreatorVC.setError(message: "\(message)\n\(reason)", animated: true)
        } else {
            databaseCreatorVC.setError(message: message, animated: true)
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension DatabaseCreatorCoordinator: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // cancel overall database creation
        if let initialTopController = self.initialTopController {
            self.navigationController.popToViewController(initialTopController, animated: false)
        }
        self.delegate?.didPressCancel(in: self)
    }
    
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL])
    {
        guard let url = urls.first else { return }
        addCreatedDatabase(at: url)
    }
}
