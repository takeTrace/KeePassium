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
        let hasPassword = !passwordData.isEmpty
        let hasKeyFile = !keyFileData.isEmpty
        
        precondition(hasPassword || hasKeyFile)
        
        if hasPassword && hasKeyFile {
            Diag.info("Using password and key file")
            let preKey = ByteArray.concat(
                passwordData.sha256,
                processKeyFile(keyFileData: keyFileData))
            return SecureByteArray(preKey.sha256)
        } else if hasPassword {
            Diag.info("Using password")
            return SecureByteArray(passwordData.sha256)
        } else if hasKeyFile {
            Diag.info("Using key file")
            return processKeyFile(keyFileData: keyFileData) // in KP1 returned as is (in KP2 undergoes another sha256)
        } else {
            // should not happen, already checked above
            fatalError("Both password and key file are empty after being checked.")
        }
    }
    
    override func processXmlKeyFile(keyFileData: ByteArray) -> SecureByteArray? {
        // By design, KP1 does not handle XML key files in any special manner.
        return nil
    }
}
