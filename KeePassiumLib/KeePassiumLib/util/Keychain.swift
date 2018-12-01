//
//  Keychain.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-08-02.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

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
    private static let service = "KeePassium"
    private static let accessGroup: String? = nil // keychain items can be used only by KeePassium
    public enum Account: String {
        case appPasscode = "appPasscode"
    }
    
    private init() {
        // left empty
    }
    
    private func makeQuery(account: String?) -> [String: AnyObject] {
        var result = [String: AnyObject]()
        result[kSecClass as String] = kSecClassGenericPassword
        result[kSecAttrService as String] = Keychain.service as AnyObject?
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
    public func get(account: Account) throws -> Data? {
        var query = makeQuery(account: account.rawValue)
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
    public func set(account: Account, data: Data) throws {
        if let _ = try get(account: account) { // throws KeychainError
            let query = makeQuery(account: account.rawValue)
            let attrsToUpdate = [kSecValueData as String : data as AnyObject?]
            let status = SecItemUpdate(query as CFDictionary, attrsToUpdate as CFDictionary)
            if status != noErr {
                throw KeychainError.generic(code: Int(status))
            }
        } else {
            var newItem = makeQuery(account: account.rawValue)
            newItem[kSecValueData as String] = data as AnyObject?
            let status = SecItemAdd(newItem as CFDictionary, nil)
            if status != noErr {
                throw KeychainError.generic(code: Int(status))
            }
        }
    }

    /// Deletes an account from keychain.
    /// - Throws: KeychainError
    public func remove(account: Account) throws {
        let query = makeQuery(account: account.rawValue)
        let status = SecItemDelete(query as CFDictionary)
        if status != noErr && status != errSecItemNotFound {
            throw KeychainError.generic(code: Int(status))
        }
    }
}
