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

public class KeyHelper {
    public static let compositeKeyLength = 32
    internal let keyFileKeyLength = 32
    
    /// Builds a composite master key from the password and key file data.
    /// At least one parameter should be non-empty.
    /// (Pure virtual method, must be overriden)
    ///
    /// - Parameter: passwordData - password data (possibly empty)
    /// - Parameter: keyFileData - key file data (possibly empty)
    /// - Returns: composite key
    public func makeCompositeKey(passwordData: ByteArray, keyFileData: ByteArray) -> SecureByteArray {
        fatalError("Pure virtual method")
    }
    
    /// Converts the password string to its raw-bytes representation, according to DB version rules.
    public func getPasswordData(password: String) -> SecureByteArray {
        fatalError("Pure virtual method")
    }
    
    /// Extracts key from a key file
    public func processKeyFile(keyFileData: ByteArray) -> SecureByteArray {
        assert(!keyFileData.isEmpty, "keyFileData cannot be empty here")

        if keyFileData.count == keyFileKeyLength {
            // assume the data is a 32-byte key
            Diag.debug("Key file format is: binary")
            return SecureByteArray(keyFileData)
        } else if keyFileData.count == 2 * keyFileKeyLength {
            // maybe it is a 64-byte hex encoded key?
            let hexString = keyFileData.toString(using: .ascii)
            if let hexString = hexString {
                if let key = ByteArray(hexString: hexString) {
                    Diag.debug("Key file format is: base64")
                    return SecureByteArray(key)
                }
            }
        }
        
        // is it an XML key file?
        if let key = processXmlKeyFile(keyFileData: keyFileData) {
            Diag.debug("Key file format is: XML")
            return key
        }
        
        // it is something else, just hash it
        Diag.debug("Key file format is: other")
        return SecureByteArray(keyFileData.sha256)
    }
    
    /// Tries to extract key from XML key file.
    /// (To be subclassed for format-dependent processing)
    /// - Returns: extracted key, or nil if failed to extract.
    public func processXmlKeyFile(keyFileData: ByteArray) -> SecureByteArray? {
        return nil
    }
}


