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

extension UUID {
    public static let ZERO = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    public static let byteWidth = 16
    
    /// Sets this UUID to 00000000-0000-0000-0000-000000000000
    mutating func erase() {
        self = UUID.ZERO
    }
    
    // Returns a byte-array representation of this UUID
    internal var data: ByteArray {
        var bytes = Array<UInt8>(repeating: 0, count: UUID.byteWidth)
        guard let nsuuid = NSUUID(uuidString: self.uuidString) else {
            // should not fail, since uuidString must always be well-formed
            fatalError()
        }
        nsuuid.getBytes(&bytes)
        return ByteArray(bytes: bytes)
    }

    /// Creates a UUID instance from a 16-byte array
    internal init?(data: ByteArray?) {
        guard let data = data else { return nil }
        guard data.count == UUID.byteWidth else { return nil }
        let nsuuid = data.withBytes {
            NSUUID(uuidBytes: $0)
        }
        self.init(uuidString: nsuuid.uuidString)
    }
    
    /// Returns a UUID from a Base-64 encoded string
    internal init?(base64Encoded base64: String?) {
        guard let data = ByteArray(base64Encoded: base64) else { return nil }
        let nsuuid = data.withBytes {
            NSUUID(uuidBytes: $0)
        }
        self.init(uuidString: nsuuid.uuidString)
    }
    
    internal func base64EncodedString() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        (self as NSUUID).getBytes(&bytes)
        return Data(bytes: bytes).base64EncodedString()
    }
}
