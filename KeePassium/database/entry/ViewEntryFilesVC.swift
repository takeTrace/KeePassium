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
    }
    
    private weak var entry: Entry?
    private var editButton: UIBarButtonItem!
    private var isHistoryMode = false
    
    static func make(with entry: Entry?, historyMode: Bool) -> ViewEntryFilesVC {
        let viewEntryFilesVC = ViewEntryFilesVC.instantiateFromStoryboard()
        viewEntryFilesVC.entry = entry
        viewEntryFilesVC.isHistoryMode = historyMode
        return viewEntryFilesVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editButton = UIBarButtonItem(
            image: UIImage(asset: .editItemToolbar),
            style: .plain,
            target: self,
            action: #selector(onEditAction))
        
        // Early instantiation reduces the lag when the user selects a file.
        exportController = UIDocumentInteractionController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // navigationItem.rightBarButtonItem = isHistoryMode ? nil : editButton
        refresh()
    }
    
    @objc func onEditAction() {
        print("onEditAction - files")
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
        return max(1, entry.attachments.count)
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell
    {
        guard let entry = entry else { fatalError() }
        let cell: UITableViewCell
        if entry.attachments.isEmpty {
            cell = tableView.dequeueReusableCell(withIdentifier: CellID.noFiles, for: indexPath)
        } else {
            let att = entry.attachments[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: CellID.fileItem, for: indexPath)
            cell.textLabel?.text = att.name
            cell.detailTextLabel?.text =
                ByteCountFormatter.string(fromByteCount: Int64(att.size), countStyle: .file)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let attachments = entry?.attachments else { return }
        guard !attachments.isEmpty else { return }
        guard let sourceCell = tableView.cellForRow(at: indexPath) else { return }
        
        let att = attachments[indexPath.row]
        exportAttachment(att, sourceCell: sourceCell)
    }
    
    // MARK: - Attachment export

    fileprivate var exportController: UIDocumentInteractionController!
    fileprivate var exportFileURL: TemporaryFileURL?

    private func exportAttachment(_ att: Attachment, sourceCell: UITableViewCell) {
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
            try att.data.asData.write(to: exportFileURL!.url, options: [.completeFileProtection])
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
}

extension ViewEntryFilesVC: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(
        _ controller: UIDocumentInteractionController
        ) -> UIViewController
    {
        return navigationController!
    }
}
