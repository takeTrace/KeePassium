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

internal enum ProtectedStreamAlgorithm: UInt32 {
    case Null      = 0
    // case Arc4Variant = 1 // obsolete, not implemented
    case Salsa20   = 2
    case ChaCha20  = 3
    var name: String {
        switch self {
        case .Null: return "NULL"
        case .Salsa20: return "Salsa20"
        case .ChaCha20: return "ChaCha20"
        }
    }
}

/// Stream cipher stub which simply returns original data.
/// (Implementation of `ProtectedStreamAlgorithm.Null`)
final internal class UselessStreamCipher: StreamCipher {
    func encrypt(data: ByteArray, progress: Progress?) throws -> ByteArray {
        return data
    }
    func decrypt(data: ByteArray, progress: Progress?) throws -> ByteArray {
        return data
    }
    func erase() {
        // nothing to do
    }
}

final class StreamCipherFactory {
    static func create(algorithm: ProtectedStreamAlgorithm, key: ByteArray) -> StreamCipher {
        switch algorithm {
        case .Null:
            Diag.verbose("Creating Null stream cipher")
            return UselessStreamCipher()
        case .Salsa20:
            Diag.verbose("Creating Salsa20 stream cipher")
            // predefined IV
            let salsa20InitialVector = ByteArray(bytes: [0xE8,0x30,0x09,0x4B,0x97,0x20,0x5D,0x2A])
            return Salsa20(key: key.sha256, iv: salsa20InitialVector)
        case .ChaCha20:
            Diag.verbose("Creating ChaCha20 stream cipher")
            let sha512 = key.sha512
            let chachaKey = sha512.prefix(32)
            let iv = sha512[32..<(32+12)]
            return ChaCha20(key: chachaKey, iv: iv)
        }
    }
}

