//
//  KeyHelper1.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-01.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

class KeyHelper1: KeyHelper {
    override init() {
        super.init()
    }
    
    /// Converts the password string to its raw-bytes representation, according to DB version rules.
    override func getPasswordData(password: String) -> SecureByteArray {
        guard let data = password.data(using: .isoLatin1, allowLossyConversion: true) else {
            fatalError("getPasswordData(KP1): Failed lossy conversion to ISO Latin 1")
        }
        return SecureByteArray(data: data)
    }
    
    
    override func makeCompositeKey(
        passwordData: ByteArray,
        keyFileData: ByteArray
        ) -> SecureByteArray
    {
        precondition(!passwordData.isEmpty || !keyFileData.isEmpty)
        
        if !passwordData.isEmpty && !keyFileData.isEmpty {
            Diag.info("Using password and key file")
            let preKey = ByteArray.concat(
                passwordData.sha256,
                processKeyFile(keyFileData: keyFileData))
            return SecureByteArray(preKey.sha256)
        } else if !passwordData.isEmpty {
            Diag.info("Using password")
            return SecureByteArray(passwordData.sha256)
        } else if !keyFileData.isEmpty {
            Diag.info("Using key file")
            return processKeyFile(keyFileData: keyFileData) // in KP1 returned as is (in KP2 undergoes another sha256)
        } else {
            // should not happen, already checked above
            fatalError("Unexpectedly got both empty password and empty key file.")
        }
    }
    
    override func processXmlKeyFile(keyFileData: ByteArray) -> SecureByteArray? {
        // By design, KP1 does not handle XML key files in any special manner.
        return nil
    }
}
