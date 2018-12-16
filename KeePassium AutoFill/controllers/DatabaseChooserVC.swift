//
//  DatabaseChooserVC.swift
//  KeePassium AutoFill
//
//  Created by Andrei Popleteev on 2018-12-07.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import KeePassiumLib

class DatabaseChooserVC: UITableViewController, Refreshable {
    private enum CellID {
        static let fileItem = "FileItemCell"
        static let noFiles = "NoFilesCell"
    }
    
    weak var coordinator: MainCoordinator?
    
    private var databaseRefs: [URLReference] = []
    
    static func make(coordinator: MainCoordinator) -> DatabaseChooserVC {
        let vc = DatabaseChooserVC.instantiateFromStoryboard()
        vc.coordinator = coordinator
        return vc
    }
    
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
        coordinator?.dismissAndQuit()
    }
    
    @IBAction func didPressAddDatabase(_ sender: Any) {
        coordinator?.addDatabase()
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
        coordinator?.showDatabaseUnlocker(database: dbRef, animated: true)
    }
    
    override func tableView(
        _ tableView: UITableView,
        accessoryButtonTappedForRowWith indexPath: IndexPath)
    {
        let urlRef = databaseRefs[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)!
        let databaseInfoVC = FileInfoVC.make(urlRef: urlRef, popoverSource: cell)
        present(databaseInfoVC, animated: true, completion: nil)
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
            [unowned self] (_,_) in
            self.setEditing(false, animated: true)
            let urlRef = self.databaseRefs[indexPath.row]
            self.coordinator?.removeDatabase(urlRef)
        }
        deleteAction.backgroundColor = UIColor.destructiveTint
        
        return [deleteAction]
    }
}
