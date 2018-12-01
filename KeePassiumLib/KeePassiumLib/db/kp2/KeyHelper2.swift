//
//  KeyHelper2.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-01.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation
//import AEXML

final class KeyHelper2: KeyHelper {
    
    override init() {
        super.init()
    }
    
    /// Converts the password string to its raw-bytes representation, according to DB version rules.
    override func getPasswordData(password: String) -> SecureByteArray {
        return SecureByteArray(data: Data(password.utf8))
    }
    
    override func makeCompositeKey(passwordData: ByteArray, keyFileData: ByteArray) -> SecureByteArray {
        precondition(!passwordData.isEmpty || !keyFileData.isEmpty)
        
        var preKey: ByteArray
        if !passwordData.isEmpty && !keyFileData.isEmpty {
            Diag.info("Using password and key file")
            preKey = SecureByteArray.concat(
                passwordData.sha256,
                processKeyFile(keyFileData: keyFileData))
        } else if !passwordData.isEmpty {
            Diag.info("Using password only")
            preKey = passwordData.sha256
        } else if keyFileData.isEmpty {
            Diag.info("Using key file only")
            preKey = processKeyFile(keyFileData: keyFileData)
            // in KP2, preKey is kept for another sha256 (in KP1, is returned as is)
        } else {
            // should not happen, already checked above
            preKey = ByteArray() // needed to hush the compiler warning
        }
        return SecureByteArray(preKey.sha256)
    }
    
    /// Tries to extract key data from KeePass v2.xx XML file.
    /// - Returns: key data, or nil in case of any issues.
    internal override func processXmlKeyFile(keyFileData: ByteArray) -> SecureByteArray? {
        do {
            let xml = try AEXMLDocument(xml: keyFileData.asData)
            // version = xml[Xml2.keyFile][Xml2.meta][Xml2.version].value // unused
            let base64 = xml[Xml2.keyFile][Xml2.key][Xml2.data].value
            guard let out = ByteArray(base64Encoded: base64) else {
                return nil
            }
            return SecureByteArray(out)
        } catch {
            return nil
        }
    }
}
