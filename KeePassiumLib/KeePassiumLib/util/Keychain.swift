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

public enum KeychainError: LocalizedError {
    case generic(code: Int)
    case unexpectedFormat
    public var errorDescription: String? {
        switch self {
        case .generic(let code):
            return NSLocalizedString("Keychain error (code \(code)) ", comment: "Generic error message about system keychain, with an error code.")
        case .unexpectedFormat:
            return NSLocalizedString("Keychain error: unexpected data format", comment: "Error message about system keychain.")
        }
    }
}

/// Helper class to simplify access to the system keychain.
public class Keychain {
    public static let shared = Keychain()
    private static let accessGroup: String? = nil
    private enum Service: String {
        case general = "KeePassium"
        case databaseKeys = "KeePassium.dbKeys"
    }
    private let appPasscodeAccount = "appPasscode"
    
    private init() {
        // left empty
    }
    
    // MARK: - Low-level keychain access helpers
    
    private func makeQuery(service: Service, account: String?) -> [String: AnyObject] {
        var result = [String: AnyObject]()
        result[kSecClass as String] = kSecClassGenericPassword
        result[kSecAttrService as String] = service.rawValue as AnyObject?
        if let account = account {
            result[kSecAttrAccount as String] = account as AnyObject?
        }
        if let accessGroup = Keychain.accessGroup {
            result[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }
        return result
    }
    
    /// - Returns: keychain data for the given account, or `nil` if nothing found.
    /// - Throws: KeychainError
    private func get(service: Service, account: String) throws -> Data? {
        var query = makeQuery(service: service, account: account)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) { ptr in
            return SecItemCopyMatching(query as CFDictionary, ptr)
        }
        if status == errSecItemNotFound {
            return nil
        }
        guard status == noErr else { throw KeychainError.generic(code: Int(status)) }
        
        guard let item = queryResult as? [String: AnyObject],
            let data = item[kSecValueData as String] as? Data else {
                throw KeychainError.unexpectedFormat
        }
        return data
    }
    
    /// Saves data for the given `account` in the keychain.
    /// - Throws: KeychainError
    private func set(service: Service, account: String, data: Data) throws {
        if let _ = try get(service: service, account: account) { // throws KeychainError
            let query = makeQuery(service: service, account: account)
            let attrsToUpdate = [kSecValueData as String : data as AnyObject?]
            let status = SecItemUpdate(query as CFDictionary, attrsToUpdate as CFDictionary)
            if status != noErr {
                throw KeychainError.generic(code: Int(status))
            }
        } else {
            var newItem = makeQuery(service: service, account: account)
            newItem[kSecValueData as String] = data as AnyObject?
            let status = SecItemAdd(newItem as CFDictionary, nil)
            if status != noErr {
                throw KeychainError.generic(code: Int(status))
            }
        }
    }
    
    /// Deletes an account from keychain.
    /// If `account` is `nil`, removes all accounts of the given `service`.
    /// - Throws: KeychainError
    private func remove(service: Service, account: String?) throws {
        let query = makeQuery(service: service, account: account)
        let status = SecItemDelete(query as CFDictionary)
        if status != noErr && status != errSecItemNotFound {
            throw KeychainError.generic(code: Int(status))
        }
    }
    
    // MARK: - App Lock passcode routines
    
    /// Saves the given app passcode in keychain.
    /// - Throws: KeychainError
    public func setAppPasscode(_ passcode: String) throws {
        let passcodeData = passcode.data(using: .utf8)!
        // hashing is redundant, but is kept here for compatibility.
        // (To avoid locking out early beta users.)
        let dataHash = ByteArray(data: passcodeData).sha256.asData
        try set(service: .general, account: appPasscodeAccount, data: dataHash) // throws KeychainError
    }

    /// Checks if the keychain contains an App Lock passcode.
    /// - Throws: KeychainError
    public func isAppPasscodeSet() throws -> Bool {
        let storedHash = try get(service: .general, account: appPasscodeAccount) // throws KeychainError
        return storedHash != nil
    }
    
    /// Checks if the given passcode matches the previously saved one.
    /// - Throws: KeychainError
    public func isAppPasscodeMatch(_ passcode: String) throws -> Bool {
        guard let storedHash =
            try get(service: .general, account: appPasscodeAccount) else
            // throws KeychainError
        {
            // no passcode saved in keychain
            return false
        }
        let passcodeData = passcode.data(using: .utf8)!
        let passcodeHash = ByteArray(data: passcodeData).sha256.asData
        return passcodeHash == storedHash
    }

    /// Removes app passcode hash from keychain.
    /// - Throws: KeychainError
    public func removeAppPasscode() throws {
        try remove(service: .general, account: appPasscodeAccount) // throws KeychainError
    }
    
    // MARK: - Database-key association routines

    /// Stores DB's key in keychain.
    ///
    /// - Parameters:
    ///   - databaseRef: reference to identify the database
    ///   - key: key for the database
    /// - Throws: KeychainError
    public func setDatabaseKey(databaseRef: URLReference, key: SecureByteArray) throws {
        guard !databaseRef.info.hasError else { return }
        
        // let account = databaseRef.hash.asHexString
        let account = databaseRef.info.fileName
        try set(service: .databaseKeys, account: account, data: key.asData) // throws KeychainError
    }

    /// Returns stored key for the given `databaseRef`.
    ///
    /// - Returns: stored key, or `nil` if none found.
    /// - Throws: KeychainError
    public func getDatabaseKey(databaseRef: URLReference) throws -> SecureByteArray? {
        guard !databaseRef.info.hasError else { return nil }
        
        // let account = databaseRef.hash.asHexString
        let account = databaseRef.info.fileName
        guard let data = try get(service: .databaseKeys, account: account) else {
            // nothing found
            return nil
        }
        return SecureByteArray(data: data)
    }

    /// Removes associated keys for the given database
    /// (or all the associations if `databaseRef` is `nil`).
    /// - Throws: KeychainError
    public func removeDatabaseKey(databaseRef: URLReference?) throws {
        if let databaseRef = databaseRef {
            guard !databaseRef.info.hasError else { return }
            // let account = databaseRef.hash.asHexString
            let account = databaseRef.info.fileName
            try remove(service: .databaseKeys, account: account)
        } else {
            try remove(service: .databaseKeys, account: nil)
        }
    }
}
