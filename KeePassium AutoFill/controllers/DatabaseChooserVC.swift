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

import KeePassiumLib

protocol DatabaseChooserDelegate: class {
    /// Called when the user presses "Cancel"
    func databaseChooserShouldCancel(_ sender: DatabaseChooserVC)
    /// Called when the user presses "Add database"
    func databaseChooserShouldAddDatabase(_ sender: DatabaseChooserVC)
    /// Called when the user selects a database from the list
    func databaseChooser(_ sender: DatabaseChooserVC, didSelectDatabase urlRef: URLReference)
    /// Called when the user wants to remove a database from the list
    func databaseChooser(_ sender: DatabaseChooserVC, shouldRemoveDatabase urlRef: URLReference)
    /// Called when the user requests additional info about a database file
    func databaseChooser(_ sender: DatabaseChooserVC, shouldShowInfoForDatabase urlRef: URLReference)
}

class DatabaseChooserVC: UITableViewController, Refreshable {
    private enum CellID {
        static let fileItem = "FileItemCell"
        static let noFiles = "NoFilesCell"
    }
    
    weak var coordinator: MainCoordinator?
    weak var delegate: DatabaseChooserDelegate?
    
    private var databaseRefs: [URLReference] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl

        refresh()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
        refresh()
    }
    
    @objc func refresh() {
        databaseRefs = FileKeeper.shared.getAllReferences(
            fileType: .database,
            includeBackup: Settings.current.isBackupFilesVisible)
        sortFileList()
        if refreshControl?.isRefreshing ?? false {
            refreshControl?.endRefreshing()
        }
    }
    
    func sortFileList() {
        let fileSortOrder = Settings.current.filesSortOrder
        databaseRefs.sort { return fileSortOrder.compare($0, $1) }
        tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @IBAction func didPressCancel(_ sender: Any) {
        delegate?.databaseChooserShouldCancel(self)
    }
    
    @IBAction func didPressAddDatabase(_ sender: Any) {
        delegate?.databaseChooserShouldAddDatabase(self)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if databaseRefs.isEmpty {
            return 1 // for "nothing here" cell
        } else {
            return databaseRefs.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard databaseRefs.count > 0 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.noFiles, for: indexPath)
            return cell
        }
        
        let cell = tableView
            .dequeueReusableCell(withIdentifier: CellID.fileItem, for: indexPath)
            as! DatabaseFileListCell
        cell.urlRef = databaseRefs[indexPath.row]
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard databaseRefs.count > 0 else { return }
        let dbRef = databaseRefs[indexPath.row]
        delegate?.databaseChooser(self, didSelectDatabase: dbRef)
    }
    
    override func tableView(
        _ tableView: UITableView,
        accessoryButtonTappedForRowWith indexPath: IndexPath)
    {
        let urlRef = databaseRefs[indexPath.row]
        delegate?.databaseChooser(self, shouldShowInfoForDatabase: urlRef)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return databaseRefs.count > 0
    }
    
    override func tableView(
        _ tableView: UITableView,
        editActionsForRowAt indexPath: IndexPath
        ) -> [UITableViewRowAction]?
    {
        guard databaseRefs.count > 0 else { return nil }
        
        let deleteAction = UITableViewRowAction(
            style: .destructive,
            title: LString.actionRemoveFile)
        {
            [weak self] (_,_) in
            guard let _self = self else { return }
            _self.setEditing(false, animated: true)
            let urlRef = _self.databaseRefs[indexPath.row]
            _self.delegate?.databaseChooser(_self, shouldRemoveDatabase: urlRef)
        }
        deleteAction.backgroundColor = UIColor.destructiveTint
        
        return [deleteAction]
    }
}
