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

/// A collection of parameters for key derivation functions.
final class KDFParams: VarDict {
    public static let uuidParam = "$UUID"
    public var kdfUUID: UUID {
        let uuidBytes = getValue(key: KDFParams.uuidParam)?.asByteArray()
        return UUID(data: uuidBytes) ?? UUID.ZERO
    }
    
    override func erase() {
        super.erase()
    }
    
    override func read(data: ByteArray) -> Bool {
        Diag.debug("Parsing KDF params")
        guard super.read(data: data) else { return false }
        
        // now making sure uuidParam is actually a valid UUID
        guard let value = getValue(key: KDFParams.uuidParam) else {
            Diag.warning("KDF UUID is missing")
            return false
        }
        guard let uuidData = value.asByteArray(),
            let _ = UUID(data: uuidData) else {
                Diag.warning("KDF UUID is malformed")
                return false
        }
        return true
    }
}
