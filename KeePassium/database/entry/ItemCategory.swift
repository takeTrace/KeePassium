//
//  ItemCategory.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-17.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation
import KeePassiumLib

/// Defines the visualisation style of an item (group/entry),
/// that is which fields are main, which are auxiliary, and how to show them.
enum ItemCategory: String {
    public static let all: [ItemCategory] = [.default]
    
    /// Standard KeePass style (fixed: title, username, password, URL, notes)
    case `default` = "keepass"

    /// Internal names of fixed fields for thi s category
    var fixedFields: [String] {
        return [
            EntryField.title,
            EntryField.userName,
            EntryField.password,
            EntryField.url,
            EntryField.notes]
    }
    var name: String {
        return LString.itemCategoryDefault
    }
    
    func getFieldRanks() -> [String: Int] {
        // rank 0 is reserved for future
        return [
            EntryField.title: 1,
            EntryField.userName: 2,
            EntryField.password: 3,
            EntryField.url: 4,
            EntryField.notes: 5]
    }
    
    /// Returns `ItemCategory` for the given entry.
    public static func get(for entry: Entry) -> ItemCategory {
        return .default
    }
    
    /// Returns `ItemCategory` for the given group.
    public static func get(for group: Group) -> ItemCategory {
        return .default
    }
    
    /// Returns `ItemCategory` by its rawValue, or `ItemCategory.default` if no match found.
    public static func fromString(_ categoryString: String) -> ItemCategory {
        return ItemCategory(rawValue: categoryString) ?? .default
    }
    
    public func compare(_ fieldName1: String, _ fieldName2: String) -> Bool {
        let ranks = getFieldRanks()
        // Fixed fields are ranked by importance.
        // Higher-ranked field go first, unranked fields go last.
        let rank1 = ranks[fieldName1] ?? Int.max
        let rank2 = ranks[fieldName2] ?? Int.max
        if rank1 != rank2 {
            return rank1 < rank2
        } else {
            // not ranked fields, no sorting
            return false //fieldName1.localizedStandardCompare(fieldName2) == .orderedAscending
        }
    }
}
