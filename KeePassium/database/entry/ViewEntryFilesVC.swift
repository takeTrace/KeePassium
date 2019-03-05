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
    private var isModified = false // true iff there are unsaved changes
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
        let willBeEditing = !tableView.isEditing
        tableView.setEditing(willBeEditing, animated: true)
        if isEditing && isModified {
            applyChangesAndSaveDatabase()
        }
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
        //TODO
        print("did press Add Attachment")
    }
    
    private func didPressRenameAttachment(at indexPath: IndexPath) {
        guard let entry = entry else { return }
        print("did press Rename Attachment")
    }
    
    private func didPressDeleteAttachment(at indexPath: IndexPath) {
        guard let entry = entry else { return }
        print("did press Delete Attachment")
        // already confirmed by two taps in UI
        entry.attachments.remove(at: indexPath.row)
        isModified = true
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    // MARK: - Database saving routines
    
    var progressOverlay: ProgressOverlay?
    private func applyChangesAndSaveDatabase() {
        guard let entry = entry else { return }
        entry.modified()
        databaseManagerNotifications.startObserving()
        DatabaseManager.shared.startSavingDatabase()
    }
    
    private func showSavingOverlay() {
        //TODO
    }
    
    private func hideSavingOverlay() {
        //TODO
    }
}

extension ViewEntryFilesVC: DatabaseManagerObserver {
    
    func databaseManager(willSaveDatabase urlRef: URLReference) {
        progressOverlay = ProgressOverlay.addTo(
            self.view,
            title: LString.databaseStatusSaving,
            animated: true
        )
    }
    func databaseManager(progressDidChange progress: ProgressEx) {
        //TODO
    }
    func databaseManager(database urlRef: URLReference, isCancelled: Bool) {
        //TODO
    }
    func databaseManager(database urlRef: URLReference, savingError message: String, reason: String?) {
        //TODO
    }
    func databaseManager(didSaveDatabase urlRef: URLReference) {
        //TODO
    }
}

extension ViewEntryFilesVC: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(
        _ controller: UIDocumentInteractionController
        ) -> UIViewController
    {
        return navigationController!
    }
}
