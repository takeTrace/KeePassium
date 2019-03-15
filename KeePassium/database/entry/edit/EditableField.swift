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

class EditableFieldFactory {
    public static func makeAll(from entry: Entry, in database: Database) -> [EditableField] {
        let viewableFields = ViewableEntryFieldFactory.makeAll(
            from: entry,
            in: database,
            excluding: [.emptyValues, .nonEditable]
        )
        return viewableFields
            .filter { $0.field != nil }
            .map { EditableField(field: $0.field!) }
    }
}

class EditableField: BasicViewableField {
    override var internalName: String {
        get { return field?.name ?? "" }
        set {
            if let field = field { field.name = newValue }
        }
    }

    override var value: String? {
        get { return field?.value }
        set {
            if let field = field { field.value = newValue ?? "" }
        }
    }
    
    override var isProtected: Bool {
        get { return field?.isProtected ?? false }
        set {
            if let field = field { field.isProtected = newValue }
        }
    }
    
    /// is field name valid (i.e. non-empty and unique)
    var isValid: Bool

    init(field: EntryField) {
        isValid = true
        super.init(fieldOrNil: field, isValueHidden: field.isProtected)
    }
}
