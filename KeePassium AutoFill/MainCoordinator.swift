//
//  MainCoordinator.swift
//  KeePassium AutoFill
//
//  Created by Andrei Popleteev on 2018-12-12.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib
import AuthenticationServices
import LocalAuthentication

class MainCoordinator: NSObject, Coordinator {
    unowned var rootController: CredentialProviderViewController
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    
    var serviceIdentifiers = [ASCredentialServiceIdentifier]()
    fileprivate var databaseManagerNotifications: DatabaseManagerNotifications?
    fileprivate var isLoadingUsingStoredDatabaseKey = false
    
    fileprivate weak var addDatabasePicker: UIDocumentPickerViewController?
    fileprivate weak var addKeyFilePicker: UIDocumentPickerViewController?
    
    init(rootController: CredentialProviderViewController) {
        self.rootController = rootController
        navigationController = UINavigationController()
        super.init()

        navigationController.delegate = self
    }
    
    func start() {
        databaseManagerNotifications = DatabaseManagerNotifications(observer: self)
        databaseManagerNotifications?.startObserving()
        
        let isBiometricsShown = showBiometricAuthIfEnabled() {
            [weak self] (authSuccess) in
            self?.startMainFlow(requirePasscode: !authSuccess)
        }
        
        if !isBiometricsShown {
            startMainFlow(requirePasscode: true)
        }
    }

    /// Instantiates root navigation controller and its first VC.
    /// If `requirePasscode` is `true`, requires the user to enter
    /// a correct passcode first.
    ///
    /// - Parameter requirePasscode: whether to require App Lock
    ///     passcode first. If passcode has not been set,
    ///     this parameter is ignored.
    private func startMainFlow(requirePasscode: Bool) {
        if requirePasscode {
            do {
                if try Keychain.shared.isAppPasscodeSet() { // throws KeychainError
                    try showPasscodeRequest() // throws KeychainError
                    return
                }
            } catch {
                Diag.error("Keychain error [message: \(error.localizedDescription)]")
                let errorAlert = UIAlertController.make(
                    title: LString.titleKeychainError,
                    message: error.localizedDescription,
                    cancelButtonTitle: LString.actionDismiss)
                rootController.present(errorAlert, animated: true, completion: nil)
                return
            }
        }
        
        rootController.present(navigationController, animated: true, completion: nil)
        showDatabaseChooser()
    }

    // Clears and closes any resources before quitting the extension.
    func cleanup() {
        DatabaseManager.shared.closeDatabase(clearStoredKey: false)
    }

    /// Closes all view controllers and quits the extension.
    func dismissAndQuit() {
        rootController.dismiss()
        cleanup()
    }

    /// Provides entry's details to the authentication services
    /// and quits the extension.
    func returnCredentials(entry: Entry) {
        let passwordCredential = ASPasswordCredential(user: entry.userName, password: entry.password)
        rootController.extensionContext.completeRequest(
            withSelectedCredential: passwordCredential,
            completionHandler: nil)
        cleanup()
    }
    
    
    /// If the visible VC contains a list of files - refreshes it.
    private func refreshFileList() {
        guard let topVC = navigationController.topViewController else { return }
        (topVC as? DatabaseChooserVC)?.refresh()
        (topVC as? KeyFileChooserVC)?.refresh()
    }
    
    private func tryToUnlockDatabase(
        database: URLReference,
        password: String,
        keyFile: URLReference?)
    {
        isLoadingUsingStoredDatabaseKey = false
        DatabaseManager.shared.startLoadingDatabase(
            database: database,
            password: password,
            keyFile: keyFile)
    }
    
    private func tryToUnlockDatabase(
        database: URLReference,
        compositeKey: SecureByteArray)
    {
        isLoadingUsingStoredDatabaseKey = true
        DatabaseManager.shared.startLoadingDatabase(
            database: database,
            compositeKey: compositeKey)
    }
    
    // MARK: - Actions
    
    /// Shows biometric authentication UI, if supported and enabled.
    ///
    /// - Parameter completion: called after biometric authentication,
    ///         with a `Bool` parameter indicating success of the bioauth.
    /// - Returns: `true` if biometric authentication is shown, `false` otherwise.
    open func showBiometricAuthIfEnabled(completion: @escaping ((Bool) -> Void)) -> Bool {
        guard Settings.current.isBiometricAppLockEnabled else { return false }
        
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        context.localizedFallbackTitle = "" // hide "Enter Password" fallback; nil won't work
        
        let isBiometricsAvailable = context.canEvaluatePolicy(policy, error: nil)
        if isBiometricsAvailable {
            Diag.debug("Biometric auth: showing request")
            context.evaluatePolicy(policy, localizedReason: LString.titleTouchID) {
                (authSuccessful, authError) in
                if authSuccessful {
                    Diag.info("Biometric auth successful")
                    DispatchQueue.main.async {
                        completion(true)
                    }
                } else {
                    Diag.warning("Biometric auth failed [error: \(authError?.localizedDescription ?? "nil")]")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
            return true
        }
        return false
    }
    
    /// - Throws: KeychainError
    func showPasscodeRequest() throws {
        let passcodeVC = PasscodeEntryScreenVC.instantiateFromStoryboard()
        passcodeVC.delegate = self
        rootController.present(passcodeVC, animated: true, completion: nil)
    }
    
    func showDatabaseChooser() {
        let databaseChooserVC = DatabaseChooserVC.instantiateFromStoryboard()
        databaseChooserVC.coordinator = self
        databaseChooserVC.delegate = self
        navigationController.pushViewController(databaseChooserVC, animated: false)
        
        let allRefs = FileKeeper.shared.getAllReferences(fileType: .database, includeBackup: false)
        if allRefs.isEmpty {
            let firstSetupVC = FirstSetupVC.make(coordinator: self)
            firstSetupVC.navigationItem.hidesBackButton = true
            navigationController.pushViewController(firstSetupVC, animated: false)
        } else if allRefs.count == 1 {
            // If only one database, open it straight away
            showDatabaseUnlocker(database: allRefs.first!, animated: false)
        }
    }
    
    func addDatabase() {
        let picker = UIDocumentPickerViewController(documentTypes: FileType.databaseUTIs, in: .open)
        picker.delegate = self
        navigationController.topViewController?.present(picker, animated: true, completion: nil)
        
        // remember the instance to recognize it in delegate method
        addDatabasePicker = picker
    }
    
    func removeDatabase(_ urlRef: URLReference) {
        //TODO: ask for confirmation
        FileKeeper.shared.removeExternalReference(urlRef, fileType: .database)
        try? Keychain.shared.removeDatabaseKey(databaseRef: urlRef)
        refreshFileList()
    }
    
    func showDatabaseFileInfo(fileRef: URLReference) {
        let databaseInfoVC = FileInfoVC.make(urlRef: fileRef, popoverSource: nil)
        navigationController.pushViewController(databaseInfoVC, animated: true)
    }

    func showDatabaseUnlocker(database: URLReference, animated: Bool) {
        let storedDatabaseKey: SecureByteArray?
        do {
            storedDatabaseKey = try Keychain.shared.getDatabaseKey(databaseRef: database)
                // throws KeychainError
        } catch {
            storedDatabaseKey = nil
            Diag.warning("Keychain error [message: \(error.localizedDescription)]")
            // just log, nothing else
        }
        
        let vc = DatabaseUnlockerVC.instantiateFromStoryboard()
        vc.delegate = self
        vc.coordinator = self
        vc.databaseRef = database
        vc.shouldAutofocus = (storedDatabaseKey == nil)
        navigationController.pushViewController(vc, animated: animated)
        if let storedDatabaseKey = storedDatabaseKey {
            tryToUnlockDatabase(database: database, compositeKey: storedDatabaseKey)
        }
    }
    
    func addKeyFile() {
        let picker = UIDocumentPickerViewController(documentTypes: FileType.keyFileUTIs, in: .open)
        picker.delegate = self
        navigationController.topViewController?.present(picker, animated: true, completion: nil)
        
        // remember the instance to recognize it in delegate method
        addKeyFilePicker = picker
    }
    
    func removeKeyFile(_ urlRef: URLReference) {
        //TODO: ask for confirmation
        FileKeeper.shared.removeExternalReference(urlRef, fileType: .keyFile)
        refreshFileList()
    }
    
    func selectKeyFile() {
        let vc = KeyFileChooserVC.instantiateFromStoryboard()
        vc.coordinator = self
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showDiagnostics() {
        let vc = DiagnosticsViewerVC.instantiateFromStoryboard()
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showDatabaseContent(database: Database, databaseRef: URLReference) {
        let fileName = databaseRef.info.fileName
        let databaseName = URL(string: fileName)?.deletingPathExtension().absoluteString ?? fileName
        
        let entriesVC = EntryFinderVC.instantiateFromStoryboard()
        entriesVC.coordinator = self
        entriesVC.delegate = self
        entriesVC.database = database
        entriesVC.databaseName = databaseName
        entriesVC.serviceIdentifiers = serviceIdentifiers

        var vcs = navigationController.viewControllers
        vcs[vcs.count - 1] = entriesVC
        navigationController.setViewControllers(vcs, animated: true)
    }
}

extension MainCoordinator: PasscodeEntryScreenDelegate {
    func passcodeEntryScreenShouldCancel(_ sender: PasscodeEntryScreenVC) {
        dismissAndQuit()
    }
    
    func passcodeEntryScreenDidUnlock(_ sender: PasscodeEntryScreenVC) {
        rootController.dismiss(animated: true, completion: nil)
        startMainFlow(requirePasscode: false)
    }
}

extension MainCoordinator: DatabaseChooserDelegate {
    func databaseChooserShouldCancel(_ sender: DatabaseChooserVC) {
        dismissAndQuit()
    }
    
    func databaseChooserShouldAddDatabase(_ sender: DatabaseChooserVC) {
        addDatabase()
    }
    
    func databaseChooser(_ sender: DatabaseChooserVC, didSelectDatabase urlRef: URLReference) {
        showDatabaseUnlocker(database: urlRef, animated: true)
    }
    
    func databaseChooser(_ sender: DatabaseChooserVC, shouldRemoveDatabase urlRef: URLReference) {
        removeDatabase(urlRef)
    }
    
    func databaseChooser(_ sender: DatabaseChooserVC, shouldShowInfoForDatabase urlRef: URLReference) {
        showDatabaseFileInfo(fileRef: urlRef)
    }
}

extension MainCoordinator: DatabaseUnlockerDelegate {
    func databaseUnlockerShouldUnlock(
        _ sender: DatabaseUnlockerVC,
        database: URLReference,
        password: String,
        keyFile: URLReference?)
    {
        tryToUnlockDatabase(database: database, password: password, keyFile: keyFile)
    }
}

extension MainCoordinator: KeyFileChooserDelegate {
    func keyFileChooser(_ sender: KeyFileChooserVC, didSelectFile urlRef: URLReference?) {
        navigationController.popViewController(animated: true) // bye-bye, key file chooser
        if let databaseUnlockerVC = navigationController.topViewController as? DatabaseUnlockerVC {
            databaseUnlockerVC.keyFileRef = urlRef
        } else {
            assertionFailure()
        }
    }
}

extension MainCoordinator: DatabaseManagerObserver {
    
    func databaseManager(willLoadDatabase urlRef: URLReference) {
        guard let databaseUnlockerVC = navigationController.topViewController
            as? DatabaseUnlockerVC else { return }
        databaseUnlockerVC.showProgressOverlay(animated: !isLoadingUsingStoredDatabaseKey)
    }

    func databaseManager(progressDidChange progress: ProgressEx) {
        guard let databaseUnlockerVC = navigationController.topViewController
            as? DatabaseUnlockerVC else { return }
        databaseUnlockerVC.updateProgress(with: progress)
    }
    
    func databaseManager(database urlRef: URLReference, isCancelled: Bool) {
        guard let databaseUnlockerVC = navigationController.topViewController
            as? DatabaseUnlockerVC else { return }
        databaseUnlockerVC.hideProgressOverlay()
    }
    
    func databaseManager(database urlRef: URLReference, invalidMasterKey message: String) {
        guard let databaseUnlockerVC = navigationController.topViewController
            as? DatabaseUnlockerVC else { return }
        databaseUnlockerVC.hideProgressOverlay()
        databaseUnlockerVC.showMasterKeyInvalid(message: message)
    }
    
    func databaseManager(database urlRef: URLReference, loadingError message: String, reason: String?) {
        guard let databaseUnlockerVC = navigationController.topViewController
            as? DatabaseUnlockerVC else { return }
        databaseUnlockerVC.hideProgressOverlay()

        let errorText = (reason != nil) ? (message + "\n" + reason!) : message
        databaseUnlockerVC.showErrorMessage(text: errorText)
    }
    
    func databaseManager(didLoadDatabase urlRef: URLReference) {
        // not hiding progress overlay, for nicer transition
        
        if Settings.current.isRememberDatabaseKey {
            do {
                try DatabaseManager.shared.rememberDatabaseKey() // throws KeychainError
            } catch {
                Diag.warning("Failed to remember database key [message: \(error.localizedDescription)]")
                // only log, nothing else
            }
        }

        guard let database = DatabaseManager.shared.database else { fatalError() }
        showDatabaseContent(database: database, databaseRef: urlRef)
    }
}

extension MainCoordinator: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // left empty
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        if controller === addDatabasePicker {
            addDatabaseURL(url)
        } else if controller === addKeyFilePicker {
            addKeyFileURL(url)
        }
    }
    
    private func addDatabaseURL(_ url: URL) {
        FileKeeper.shared.prepareToAddFile(url: url, mode: .openInPlace)
        FileKeeper.shared.processPendingOperations(
            success: { (urlRef) in
                self.navigationController.popToRootViewController(animated: true)
                self.refreshFileList()
            },
            error: { (error) in
                let alert = UIAlertController.make(
                    title: LString.titleError,
                    message: error.localizedDescription)
                self.navigationController.present(alert, animated: true, completion: nil)
            }
        )
    }

    private func addKeyFileURL(_ url: URL) {
        if FileType.isDatabaseFile(url: url) {
            let errorAlert = UIAlertController.make(
                title: LString.titleWarning,
                message: LString.dontUseDatabaseAsKeyFile,
                cancelButtonTitle: LString.actionOK)
            navigationController.present(errorAlert, animated: true, completion: nil)
            return
        }

        FileKeeper.shared.prepareToAddFile(url: url, mode: .openInPlace)
        FileKeeper.shared.processPendingOperations(
            success: { [weak self] (urlRef) in
                self?.refreshFileList()
            },
            error: { [weak self] (error) in
                let alert = UIAlertController.make(
                    title: LString.titleError,
                    message: error.localizedDescription)
                self?.navigationController.present(alert, animated: true, completion: nil)
            }
        )
    }
}

extension MainCoordinator: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool)
    {
        // make sure the VC is popping
        guard let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from),
            !navigationController.viewControllers.contains(fromVC) else { return }
        
        if fromVC is EntryFinderVC {
            DatabaseManager.shared.closeDatabase(clearStoredKey: false)
//            navigationController.popToRootViewController(animated: true)
        }
    }
}

extension MainCoordinator: EntryFinderDelegate {
    func entryFinder(_ sender: EntryFinderVC, didSelectEntry entry: Entry) {
        returnCredentials(entry: entry)
    }
    
    func entryFinderShouldLockDatabase(_ sender: EntryFinderVC) {
        DatabaseManager.shared.closeDatabase(clearStoredKey: true)
        navigationController.popToRootViewController(animated: true)
    }
}

extension MainCoordinator: DiagnosticsViewerDelegate {
    func diagnosticsViewer(_ sender: DiagnosticsViewerVC, didCopyContents text: String) {
        let infoAlert = UIAlertController.make(
            title: nil,
            message: NSLocalizedString(
                "Diagnostic log has been copied to clipboard.",
                comment: "[Diagnostics] notification/confirmation message"),
            cancelButtonTitle: LString.actionOK)
        navigationController.present(infoAlert, animated: true, completion: nil)
    }
}
