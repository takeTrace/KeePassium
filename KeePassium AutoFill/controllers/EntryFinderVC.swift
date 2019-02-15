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
import AuthenticationServices

protocol EntryFinderDelegate: class {
    func entryFinder(_ sender: EntryFinderVC, didSelectEntry entry: Entry)
    func entryFinderShouldLockDatabase(_ sender: EntryFinderVC)
}

class EntryFinderCell: UITableViewCell {
    fileprivate static let storyboardID = "EntryFinderCell"
    fileprivate var entry: Entry? {
        didSet {
            guard let entry = entry else {
                textLabel?.text = ""
                detailTextLabel?.text = ""
                imageView?.image = nil
                return
            }
            textLabel?.text = entry.title
            detailTextLabel?.text = entry.userName
            imageView?.image = UIImage.kpIcon(forEntry: entry)
        }
    }
}

class EntryFinderVC: UITableViewController {
    private enum CellID {
        static let entry = EntryFinderCell.storyboardID
        static let nothingFound = "NothingFoundCell"
    }

    weak var database: Database?
    weak var delegate: EntryFinderDelegate?
    weak var coordinator: MainCoordinator?
    var databaseName: String? {
        didSet{ refreshDatabaseName() }
    }
    var serviceIdentifiers = [ASCredentialServiceIdentifier]() {
        didSet{ updateSearchCriteria() }
    }
    
    private var searchHelper = SearchHelper()
    private var searchResults = [SearchResult]()
    private var searchController: UISearchController!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        setupSearch()
        refreshDatabaseName()
        updateSearchCriteria()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    private func setupSearch() {
        searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        searchController.searchBar.searchBarStyle = .default
        searchController.searchBar.returnKeyType = .search
        searchController.searchBar.barStyle = .default
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
    }
    
    private func updateSearchCriteria() {
        guard isViewLoaded, let database = database else { return }
        
        // If we have serviceIdentifiers - use them. Otherwise, activate manual search.
        let automaticResults = searchHelper.find(database: database, serviceIdentifiers: serviceIdentifiers)
        if automaticResults.count > 0 {
            searchResults = automaticResults
            tableView.reloadData()
            return
        }
    
        // No automatical results, so fallback to manual search
        updateSearchResults(for: searchController)
        DispatchQueue.main.async {
            self.searchController.isActive = true
            self.searchController.searchBar.becomeFirstResponder()
        }
        
    }
    
    func refreshDatabaseName() {
        guard isViewLoaded else { return }
        navigationItem.title = databaseName
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if searchResults.isEmpty {
            return 1 // for "Nothing found"
        } else {
            return searchResults.count
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchResults.isEmpty {
            return 1 // for "Nothing found"
        } else {
            return searchResults[section].entries.count
        }
    }
    
    override open func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
        ) -> String?
    {
        if searchResults.isEmpty{
            return nil
        } else {
            return searchResults[section].group.name
        }
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell
    {
        guard searchResults.count > 0 else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CellID.nothingFound,
                for: indexPath)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CellID.entry,
            for: indexPath)
            as! EntryFinderCell
        
        cell.entry = searchResults[indexPath.section].entries[indexPath.row]
        return cell
    }
    
    // MARK: - Actions
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Watchdog.shared.restart()
        guard searchResults.count > 0 else { return }
        let selectedEntry = searchResults[indexPath.section].entries[indexPath.row]
        delegate?.entryFinder(self, didSelectEntry: selectedEntry)
    }
    
    @IBAction func didPressLockDatabase(_ sender: Any) {
        Watchdog.shared.restart()
        delegate?.entryFinderShouldLockDatabase(self)
    }
}

extension EntryFinderVC: UISearchResultsUpdating {
    // Called to update results of manual search
    public func updateSearchResults(for searchController: UISearchController) {
        Watchdog.shared.restart()
        guard let searchText = searchController.searchBar.text,
            let database = database else { return }
        searchResults = searchHelper.find(database: database, searchText: searchText)
        sortSearchResults()
        tableView.reloadData()
    }

    private func sortSearchResults() {
        let groupSortOrder = Settings.current.groupSortOrder
        searchResults.sort { return groupSortOrder.compare($0.group, $1.group) }
    }
}
