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
    
    /// Time after which the value must be refreshed
    var refreshInterval: TimeInterval? { return nil }
    
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
}

class VisibleTOTPEntryField: VisibleEntryField {
    public static let internalName = "TOTP"
    let totpSeedField: EntryField
    // the parent's `field` will be "TOTP Settings"
    
    override var refreshInterval: TimeInterval? {
        return 1.0
    }
    override var isProtected: Bool {
        get { return false }
        set {}
    }
    override var isSingleline: Bool {
        get { return true }
        set {}
    }
    override var internalName: String {
        get { return VisibleTOTPEntryField.internalName}
        set {}
    }
    override var visibleName: String {
        return NSLocalizedString("TOTP", comment: "Visible name of the Time-based One-time Password (TOTP) field")
    }
    override var value: String {
        get {
            guard let totpGenerator = TOTPGeneratorFactory.makeGenerator(
                seed: totpSeedField.value,
                settings: field.value) else
            {
                return NSLocalizedString("(Unknown TOTP format)", comment: "Error message shown when unable to parse TOTP parameter values")
            }
//            let time = UInt64.init(Date.now.timeIntervalSince1970)
//            return "%TOTP-\(time)%"
            return totpGenerator.generate()
        }
        set {
            // left empty
        }
    }
    
    init(totpSeedField: EntryField, totpSettingsField: EntryField) {
        self.totpSeedField = totpSeedField
        super.init(field: totpSettingsField, isHidden: false)
    }
}

class VisibleEntryFieldFactory {
    static let totpSeedFieldName = "TOTP Seed"
    static let totpSettingsFieldName = "TOTP Settings"
    
    /// Returns all the fields of a given entry
    ///
    /// - Parameters:
    ///   - entry: the entry to extract from;
    ///   - skipTitle: if `true`, don't include the title field;
    ///   - skipEmptyValues: if `true`, don't include any fields with empty values.
    ///   - includeDynamic: include dynamically generated (virtual) fields (such as TOTP)
    /// - Returns: array of fields matching the given conditions.
    static func extractAll(
        from entry: Entry,
        includeTitle: Bool,
        includeEmptyValues: Bool,
        includeTOTP: Bool
        ) -> [VisibleEntryField]
    {
        let skipTitle = !includeTitle
        let skipEmptyValues = !includeEmptyValues
        
        var result: [VisibleEntryField] = []
        var totpSeedField: EntryField?
        var totpSettingsField: EntryField?
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
            
            switch field.name {
            case totpSeedFieldName:
                totpSeedField = field
            case totpSettingsFieldName:
                totpSettingsField = field
            default:
                break
            }
        }
        
        if includeTOTP,
           let totpSeedField = totpSeedField,
           let totpSettingsField = totpSettingsField
        {
            let totpField = VisibleTOTPEntryField(
                totpSeedField: totpSeedField,
                totpSettingsField: totpSettingsField)
            result.append(totpField)
        }
        return result
    }
}
