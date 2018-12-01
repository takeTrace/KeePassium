//
//  VisibleEntryField.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-17.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

/// Entry field as shown
class VisibleEntryField {
    /// Internal names of the fields that should be displayed in one line.
    /// (Other - custom - fields are always multi-line)
    public static let singlelineFields: [String] =
        [EntryField.title, EntryField.userName, EntryField.password, EntryField.url]
    
    internal var field: EntryField
    var internalName: String {
        get { return field.name }
        set { field.name = newValue }
    }
    var visibleName: String { return VisibleEntryField.visibleName(for: internalName) }
    var value: String {
        get { return field.value }
        set { field.value = newValue }
    }
    var isProtected: Bool {
        get { return field.isProtected }
        set { field.isProtected = newValue }
    }
    var isSingleline: Bool {
        return VisibleEntryField.singlelineFields.contains(internalName)
    }
    var isFixed: Bool {
        return field.isStandardField
    }
    var isHidden: Bool // is protected field's value currently hidden?

    
    init(field: EntryField, isHidden: Bool) {
        self.field = field
        self.isHidden = isHidden
    }
    
    public static func visibleName(for internalName: String) -> String {
        switch internalName {
        case EntryField.title: return LString.fieldTitle
        case EntryField.userName: return LString.fieldUserName
        case EntryField.password: return LString.fieldPassword
        case EntryField.url: return LString.fieldURL
        case EntryField.notes: return LString.fieldNotes
        default:
            return internalName
        }
    }
    
    /// Returns all the fields of a given entry
    ///
    /// - Parameters:
    ///   - entry: the entry to extract from;
    ///   - skipTitle: if `true`, don't include the title field;
    ///   - skipEmptyValues: if `true`, don't include any fields with empty values.
    /// - Returns: array of fields matching the given conditions.
    static func extractAll(
        from entry: Entry,
        skipTitle: Bool,
        skipEmptyValues: Bool
        ) -> [VisibleEntryField]
    {
        var result: [VisibleEntryField] = []
        for field in entry.fields {
            if skipTitle && field.name == EntryField.title {
                continue
            }
            if skipEmptyValues && field.value.isEmpty {
                continue
            }
            
            // in KP1 all fields are not protected, but we still need to hide the password
            let isHidden = field.isProtected || field.name == EntryField.password
            let visibleField = VisibleEntryField(field: field, isHidden: isHidden)
            result.append(visibleField)
        }
        return result
    }
}
