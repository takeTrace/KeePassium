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

public enum DatabaseError: LocalizedError {
    /// Error while loading database
    case loadError(reason: String)
    /// Provided master key is invalid
    case invalidKey
    /// Error while saving database
    case saveError(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .loadError:
            return NSLocalizedString("Cannot open database", comment: "Error message while opening a database")
        case .invalidKey:
            return NSLocalizedString("Invalid password or key file", comment: "Error message - the user provided wrong master key for decryption.")
        case .saveError:
            return NSLocalizedString("Cannot save database", comment: "Error message while saving a database")
        }
    }
    public var failureReason: String? {
        switch self {
        case .loadError(let reason):
            return reason
        case .saveError(let reason):
            return reason
        default:
            return nil
        }
    }
}

public struct SearchQuery {
    public var includeSubgroups: Bool
    public var includeDeleted: Bool
    public var text: String {
        didSet {
            textWords = text.split(separator: " ")
        }
    }
    public var textWords: Array<Substring>
    public init(
        includeSubgroups: Bool, includeDeleted: Bool, text: String, textWords: Array<Substring>)
    {
        self.includeSubgroups = includeSubgroups
        self.includeDeleted = includeDeleted
        self.text = text
        self.textWords = textWords
    }
}

public protocol DatabaseProgressDelegate {
    func databaseProgressChanged(percent: Int)
}

open class Database: Eraseable {
    /// File system path to the database file
    var filePath: String?
    
    /// Root group
    public internal(set) var root: Group?

    /// Progress of load/save operations
    public internal(set) var progress = ProgressEx()

    /// Composite key of the database, before derivation
    internal var compositeKey = SecureByteArray()
    
    /// Returns a fresh instance of progress for load/save operations
    public func initProgress() -> ProgressEx {
        progress = ProgressEx()
        return progress
    }
    
    /// DB version specific helper for key processing.
    /// (Pure virtual, must be overriden)
    public var keyHelper: KeyHelper {
        fatalError("Pure virtual method")
    }
    
    internal init() {
        // left empty
    }
    
    deinit {
        erase()
    }
    
    /// Erases and removes any loaded DB elements.
    public func erase() {
        root?.erase()
        root = nil
        filePath?.erase()
        compositeKey.erase()
    }

    /// Checks if given data starts with compatible KeePass signature.
    /// (Pure virtual method, must be overriden)
    public class func isSignatureMatches(data: ByteArray) -> Bool {
        fatalError("Pure virtual method")
    }
    
    /// Tries to decrypt the given DB with the given composite master key.
    ///
    /// (Pure virtual method, must be overriden)
    ///
    /// - Throws: `DatabaseError`, `ProgressInterruption`
    public func load(dbFileData: ByteArray, compositeKey: SecureByteArray) throws {
        fatalError("Pure virtual method")
    }
    
    /// Encrypts the DB and returns the result as byte array.
    /// Progress, errors and outcomes are reported to status delegate.
    ///
    /// (Pure virtual method, must be overriden)
    ///
    /// - Throws: `DatabaseError.saveError`, `ProgressInterruption`
    /// - Returns: encrypted DB bytes.
    public func save() throws -> ByteArray {
        fatalError("Pure virtual method")
    }
    
    /// Changes DB's composite key to the provided one.
    /// Don't forget to call `deriveMasterKey` before saving.
    ///
    /// (Pure virtual method, must be overriden)
    ///
    /// - Parameter newKey: new composite key.
    public func changeCompositeKey(to newKey: SecureByteArray) {
        fatalError("Pure virtual method")
    }
    
    /// Returns the Backup group of this DB.
    ///
    /// (Pure virtual method, must be overriden)
    ///
    /// - Parameter createIfMissing: create the Backup group if it does not exist.
    ///        This parameter is ignored (assumed false) if backup is disabled at DB level.
    /// - Returns: pre-existing or newly created Backup group
    public func getBackupGroup(createIfMissing: Bool) -> Group? {
        fatalError("Pure virtual method")
    }
    
    /// Returns the number of all groups and/or entries in this DB.
    public func count(includeGroups: Bool = true, includeEntries: Bool = true) -> Int {
        // TODO: can make this more efficient
        var result = 0
        if let root = self.root {
            var groups = Array<Group>()
            var entries = Array<Entry>()
            root.collectAllChildren(groups: &groups, entries: &entries)
            result += includeGroups ? groups.count : 0
            result += includeEntries ? entries.count : 0
        }
        return result
    }
    
    /// Searches for entries that match given search `query`.
    /// - Returns: number of found entries.
    public func search(query: SearchQuery, result: inout Array<Entry>) -> Int {
        result.removeAll()
        root?.filterEntries(query: query, result: &result)
        return result.count
    }
    
    /// Deletes given `group` (to Backup group, when appropriate; otherwise permanently).
    public func delete(group: Group) {
        fatalError("Pure virtual method")
    }
    
    /// Deletes given `entry` (or moves it to the Backup group, when possible).
    public func delete(entry: Entry) {
        fatalError("Pure virtual method")
    }
}

