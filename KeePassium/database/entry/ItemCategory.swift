//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

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
            EntryField.totp,
            EntryField.url,
            EntryField.notes]
    }
    var name: String {
        return NSLocalizedString(
            "[ItemCategory] Default (KeePass)",
            value: "Default (KeePass)",
            comment: "Name of an entry/group category (visual style): default one, like in KeePass"
        )
    }
    
    func getFieldRanks() -> [String: Int] {
        // rank 0 is reserved for future
        return [
            EntryField.title: 1,
            EntryField.userName: 2,
            EntryField.password: 3,
            EntryField.totp: 4, // non-standard, but if present -- it goes after the password
            EntryField.url: 5,
            EntryField.notes: 6]
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
