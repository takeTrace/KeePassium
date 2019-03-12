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
        let editableFields = VisibleEntryFieldFactory.extractAll(
            from: entry,
            includeTitle: true,
            includeEmptyValues: false,
            includeTOTP: false)
        return editableFields.map { EditableEntryField(field: $0.field) }
    }
}
