//
//  EditableEntryField.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-07-01.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation
import KeePassiumLib

class EditableEntryField: VisibleEntryField {
    weak var cell: EditEntryTableCell?
    var isValid: Bool // is field name valid (i.e. non-empty and unique)

    init(field: EntryField) {
        isValid = true
        cell = nil
        super.init(field: field, isHidden: field.isProtected)
    }
    
    static func extractAll(from entry: Entry) -> [EditableEntryField] {
        let viewableFields = VisibleEntryField.extractAll(
            from: entry, skipTitle: false, skipEmptyValues: false)
        var result: [EditableEntryField] = []
        for vField in viewableFields {
            result.append(EditableEntryField(field: vField.field))
        }
        return result
    }
}
