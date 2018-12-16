//
//  SearchHelper.swift
//  KeePassium AutoFill
//
//  Created by Andrei Popleteev on 2018-12-15.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import KeePassiumLib
import AuthenticationServices

struct SearchResult {
    var group: Group
    var entries: [Entry]
}

class SearchHelper {
    func find(database: Database, serviceIdentifiers: [ASCredentialServiceIdentifier]) -> [SearchResult] {
        
        var searchResults = [SearchResult]()
        for si in serviceIdentifiers {
            switch si.type {
            case .domain:
                let partialResults = performSearch(in: database, domain: si.identifier)
                searchResults.append(contentsOf: partialResults)
            case .URL:
                let partialResults = performSearch(in: database, url: si.identifier)
                searchResults.append(contentsOf: partialResults)
            }
        }
        return searchResults
    }
    
    func find(database: Database, searchText: String) -> [SearchResult] {
        let words = searchText.split(separator: " " as Character)
        let query = SearchQuery(
            includeSubgroups: true,
            includeDeleted: false,
            text: searchText,
            textWords: words)
        let results = performSearch(in: database, query: query)
        return results
    }
    
    /// Returns results that fit the given query.
    ///
    /// - Parameter query: search query
    /// - Returns: number of found results
    private func performSearch(in database: Database, query: SearchQuery) -> [SearchResult] {
        
        var foundEntries: [Entry] = []
        let foundCount = database.search(query: query, result: &foundEntries)
        Diag.verbose("Found \(foundCount) entries using query")
        
        let searchResults = arrangeByGroups(entries: foundEntries)
        return searchResults
    }
    
    
    private func performSearch(in database: Database, url: String) -> [SearchResult] {
        let query = SearchQuery(
            includeSubgroups: true,
            includeDeleted: false,
            text: url,
            textWords: [Substring(url)])
        var preFoundEntries: [Entry] = []
        let preFoundCount = database.search(query: query, result: &preFoundEntries)
        Diag.verbose("Preliminarily found \(preFoundCount) entries using URL")
        
        // So we have some entries that contain target URL in some of the fields.
        // Now narrow them down by their URL field only.
        let foundEntries = preFoundEntries.filter { (entry) in
            return entry.url.contains(url)
        }
        Diag.verbose("Found \(foundEntries.count) entries using URL")

        let searchResults = arrangeByGroups(entries: foundEntries)
        return searchResults
    }
    
    private func performSearch(in database: Database, domain: String) -> [SearchResult]{
        let query = SearchQuery(
            includeSubgroups: true,
            includeDeleted: false,
            text: domain,
            textWords: [Substring(domain)])
        var preFoundEntries: [Entry] = []
        let preFoundCount = database.search(query: query, result: &preFoundEntries)
        Diag.verbose("Preliminarily found \(preFoundCount) entries using domain")
        
        // So we have some entries that contain target URL in some of the fields.
        // Now narrow them down by their URL field only.
        let foundEntries = preFoundEntries.filter { (entry) in
            return URL(string: entry.url)?.host == domain
        }
        Diag.verbose("Found \(foundEntries.count) entries using domain")
        
        let searchResults = arrangeByGroups(entries: foundEntries)
        return searchResults
    }
    
    private func arrangeByGroups(entries: [Entry]) -> [SearchResult] {
        var searchResults = [SearchResult]()
        searchResults.reserveCapacity(entries.count)
        
        // arrange found entries in group
        for entry in entries {
            guard let parentGroup = entry.parent else { assertionFailure(); return [] }
            var isInserted = false
            for i in 0..<searchResults.count {
                if searchResults[i].group === parentGroup {
                    searchResults[i].entries.append(entry)
                    isInserted = true
                    break
                }
            }
            if !isInserted {
                let newSearchResult = SearchResult(group: parentGroup, entries: [entry])
                searchResults.append(newSearchResult)
            }
        }
        return searchResults
    }
}
