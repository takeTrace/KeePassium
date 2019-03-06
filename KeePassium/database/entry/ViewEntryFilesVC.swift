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

class ViewEntryFilesVC: UITableViewController, Refreshable {
    private enum CellID {
        static let fileItem = "FileItemCell"
        static let noFiles = "NoFilesCell"
        static let addFile = "AddFileCell"
    }
    
    private weak var entry: Entry?
    private var editButton: UIBarButtonItem!
    private var isHistoryMode = false
    private var canAddFiles: Bool { return !isHistoryMode }
    private var databaseManagerNotifications: DatabaseManagerNotifications!

    static func make(with entry: Entry?, historyMode: Bool) -> ViewEntryFilesVC {
        let viewEntryFilesVC = ViewEntryFilesVC.instantiateFromStoryboard()
        viewEntryFilesVC.entry = entry
        viewEntryFilesVC.isHistoryMode = historyMode
        return viewEntryFilesVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editButton = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(didPressEdit))
        navigationItem.rightBarButtonItem = isHistoryMode ? nil : editButton
        
        databaseManagerNotifications = DatabaseManagerNotifications(observer: self)
        
        // Early instantiation reduces the lag when the user selects a file.
        exportController = UIDocumentInteractionController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    func refresh() {
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // only attachments section
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let entry = entry else { return 0 }
        let contentCellCount = max(1, entry.attachments.count) // at least one for "Nothing here"
        if canAddFiles {
            return contentCellCount + 1 // +1 for "Add File"
        } else {
            return contentCellCount
        }
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell
    {
        guard let entry = entry else { fatalError() }
        guard entry.attachments.count > 0 else {
            switch indexPath.row {
            case 0:
                return tableView.dequeueReusableCell(withIdentifier: CellID.noFiles, for: indexPath)
            case 1:
                assert(canAddFiles)
                return tableView.dequeueReusableCell(withIdentifier: CellID.addFile, for: indexPath)
            default:
                fatalError()
            }
        }
        
        if indexPath.row < entry.attachments.count {
            let att = entry.attachments[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.fileItem, for: indexPath)
            cell.textLabel?.text = att.name
            cell.detailTextLabel?.text = ByteCountFormatter.string(
                fromByteCount: Int64(att.size),
                countStyle: .file
            )
            return cell
        } else {
            assert(canAddFiles)
            return tableView.dequeueReusableCell(withIdentifier: CellID.addFile, for: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let attachments = entry?.attachments else { return }
        guard let sourceCell = tableView.cellForRow(at: indexPath) else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = indexPath.row
        if row < attachments.count {
            if tableView.isEditing {
                didPressRenameAttachment(at: indexPath)
            } else {
                didPressExportAttachment(attachments[row], sourceCell: sourceCell)
            }
        } else {
            assert(canAddFiles)
            didPressAddAttachment()
        }
    }
    
    override func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        guard let attachments = entry?.attachments else { return .none }
        let row = indexPath.row
        guard attachments.count > 0 else {
            switch row {
            case 0: // "nothing here"
                return .none
            case 1: // "add file"
                assert(canAddFiles)
                return .insert
            default:
                fatalError()
            }
        }
        
        if row < attachments.count {
            return .delete
        } else {
            assert(canAddFiles)
            return .insert
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let attachments = entry?.attachments else { return false }
        guard !isHistoryMode else { return false }
        let row = indexPath.row
        if row == 0 && attachments.isEmpty {
            // "Nothing here" cell
            return false
        } else {
            // some content
            return true
        }
    }
    
    override func tableView(
        _ tableView: UITableView,
        editActionsForRowAt indexPath: IndexPath
        ) -> [UITableViewRowAction]?
    {
        let deleteAction = UITableViewRowAction(
            style: .destructive,
            title: LString.actionDeleteFile,
            handler: { [weak self] (rowAction, indexPath) in
                self?.didPressDeleteAttachment(at: indexPath)
            }
        )
        
        return [deleteAction]
    }
    
    // MARK: - Actions
    
    @objc func didPressEdit() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    // MARK: - Attachment management routines

    fileprivate var exportController: UIDocumentInteractionController!
    fileprivate var exportFileURL: TemporaryFileURL?

    private func didPressExportAttachment(_ att: Attachment, sourceCell: UITableViewCell) {
        // iOS can only share file URLs, so we save the attachment
        // to an app-local tmp file, then export its URL.
        // TODO: when is is removed?
        
        guard let encodedAttName = att.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let fileName = URL(string: encodedAttName)?.lastPathComponent else
        {
            Diag.warning("Failed to create a URL from attachment name [att.name: \(att.name)]")
            let alert = UIAlertController.make(title: LString.titleExportError, message: nil)
            present(alert, animated: true, completion: nil)
            return
        }
        
        do {
            exportFileURL = try TemporaryFileURL(fileName: fileName)
                // throws some FileManager error
            let uncompressedBytes = att.isCompressed ? try att.data.gunzipped() : att.data
                // throws `GzipError`
            try uncompressedBytes.write(to: exportFileURL!.url, options: [.completeFileProtection])
            exportController.url = exportFileURL!.url
            if let icon = exportController.icons.first {
                sourceCell.imageView?.image = icon
            }
            exportController.delegate = self
            Diag.info("Will present attachment")
            if !exportController.presentPreview(animated: true) {
                Diag.verbose("Preview not available, showing menu")
                exportController.presentOptionsMenu(
                    from: sourceCell.frame,
                    in: tableView,
                    animated: true)
            }
        } catch {
            Diag.error("Failed to write attachment [reason: \(error.localizedDescription)]")
            let alert = UIAlertController.make(
                title: LString.titleExportError,
                message: error.localizedDescription)
            present(alert, animated: true, completion: nil)
        }
    }
    
    private func didPressAddAttachment() {
        guard let entry = entry else { return }
        
        let capacityOK = entry.isSupportsMultipleAttachments || entry.attachments.isEmpty
        if capacityOK {
            // no limits on attachments, can just add one
            addAttachment()
            return
        }
        
        // Ask permission to replace the existing attachment
        let replacementAlert = UIAlertController(
            title: NSLocalizedString("Replace existing attachment?", comment: "Confirmation message to replace an existing entry attachment with a new one."),
            message: NSLocalizedString("This database supports only one attachment per entry, and there is already one. ", comment: "Explanation for replacing the only attachment of KeePass1 entry"),
            preferredStyle: .alert)
        let cancelAction = UIAlertAction(
            title: LString.actionCancel,
            style: .cancel,
            handler: nil)
        let replaceAction = UIAlertAction(
            title: LString.actionReplace,
            style: .destructive,
            handler: { [weak self] _ in
                Diag.debug("Will replace an existing attachment")
                self?.addAttachment()
            }
        )
        replacementAlert.addAction(cancelAction)
        replacementAlert.addAction(replaceAction)
        present(replacementAlert, animated: true, completion: nil)
    }
    
    private func didPressRenameAttachment(at indexPath: IndexPath) {
        print("did press Rename Attachment")
        //TODO
    }
    
    private func didPressDeleteAttachment(at indexPath: IndexPath) {
        guard let entry = entry else { return }
        // already confirmed by two taps in UI
        entry.backupState()
        entry.modified()
        entry.attachments.remove(at: indexPath.row)
        Diag.info("Attachment deleted OK")
        
        tableView.deleteRows(at: [indexPath], with: .automatic)
        applyChangesAndSaveDatabase()
    }
    
    // MARK: - Attachment management
    
    /// Shows document picker to add an attachment (or replace KP1's existing one).
    private func addAttachment() {
        // once we are here, the user has confirmed replacing of the eventual KP1 attachment.
        let picker = UIDocumentPickerViewController(
            documentTypes: FileType.publicDataUTIs,
            in: .import)
        picker.modalPresentationStyle = .formSheet
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    // MARK: - Database saving routines
    
    private func applyChangesAndSaveDatabase() {
        guard let entry = entry else { return }
        entry.modified()
        databaseManagerNotifications.startObserving()
        DatabaseManager.shared.startSavingDatabase()
    }

    private var savingOverlay: ProgressOverlay?
    
    private func showSavingOverlay() {
        //FIXME: does not disable master VC on iPad
        navigationController?.setNavigationBarHidden(true, animated: true)
        savingOverlay = ProgressOverlay.addTo(
            view,
            title: LString.databaseStatusSaving,
            animated: true)
        savingOverlay?.isCancellable = true
    }
    
    private func hideSavingOverlay() {
        guard savingOverlay != nil else { return }
        navigationController?.setNavigationBarHidden(false, animated: true)
        savingOverlay?.dismiss(animated: true)
        {
            [weak self] (finished) in
            guard let _self = self else { return }
            _self.savingOverlay?.removeFromSuperview()
            _self.savingOverlay = nil
        }
    }
}

// MARK: - DatabaseManagerObserver
extension ViewEntryFilesVC: DatabaseManagerObserver {
    
    func databaseManager(willSaveDatabase urlRef: URLReference) {
        showSavingOverlay()
    }
    
    func databaseManager(progressDidChange progress: ProgressEx) {
        savingOverlay?.update(with: progress)
    }
    
    func databaseManager(didSaveDatabase urlRef: URLReference) {
        databaseManagerNotifications.stopObserving()
        hideSavingOverlay()
        if let entry = entry {
            EntryChangeNotifications.post(entryDidChange: entry)
        }
    }
    
    func databaseManager(database urlRef: URLReference, isCancelled: Bool) {
        databaseManagerNotifications.stopObserving()
        hideSavingOverlay()
    }

    func databaseManager(
        database urlRef: URLReference,
        savingError message: String,
        reason: String?)
    {
        databaseManagerNotifications.stopObserving()
        hideSavingOverlay()
        
        let errorAlert = UIAlertController.make(
            title: message,
            message: reason,
            cancelButtonTitle: LString.actionDismiss)
        let showDetailsAction = UIAlertAction(title: LString.actionShowDetails, style: .default)
        {
            [weak self] _ in
            let diagnosticsVC = ViewDiagnosticsVC.instantiateFromStoryboard()
            self?.present(diagnosticsVC, animated: true, completion: nil)
        }
        errorAlert.addAction(showDetailsAction)
        present(errorAlert, animated: true, completion: nil)
    }
}

// MARK: - UIDocumentPickerDelegate
extension ViewEntryFilesVC: UIDocumentPickerDelegate {
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL])
    {
        guard let url = urls.first else { return }
        let doc = FileDocument(fileURL: url)
        doc.open(
            successHandler: { [weak self] in
                self?.addAttachment(name: url.lastPathComponent, data: doc.data)
            },
            errorHandler: { [weak self] (error) in
                Diag.error("Failed to open source file [message: \(error.localizedDescription)]")
                let alert = UIAlertController.make(
                    title: LString.titleError,
                    message: error.localizedDescription,
                    cancelButtonTitle: LString.actionDismiss)
                self?.present(alert, animated: true, completion: nil)
            }
        )
    }

    private func addAttachment(name: String, data: ByteArray) {
        guard let entry = entry, let database = entry.database else { return }
        entry.backupState()
        entry.modified()

        let newAttachment = database.makeAttachment(name: name, data: data)
        if !entry.isSupportsMultipleAttachments {
            // already allowed by the user
            entry.attachments.removeAll()
        }
        entry.attachments.append(newAttachment)
        Diag.info("Attachment added OK")

        refresh()
        EntryChangeNotifications.post(entryDidChange: entry)
        
        applyChangesAndSaveDatabase()
    }
}

// MARK: - UIDocumentInteractionControllerDelegate
extension ViewEntryFilesVC: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(
        _ controller: UIDocumentInteractionController
        ) -> UIViewController
    {
        return navigationController!
    }
}
