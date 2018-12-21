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

final class ChaCha20DataCipher: DataCipher {
    private let _uuid = UUID(uuid:
        (0xD6,0x03,0x8A,0x2B,0x8B,0x6F,0x4C,0xB5,0xA5,0x24,0x33,0x9A,0x31,0xDB,0xB5,0x9A))
    var uuid: UUID { return _uuid }
    var name: String { return "ChaCha20" }
    
    var initialVectorSize: Int { return 12 } // 96 bits
    var keySize: Int { return 32 }
    private var progress = ProgressEx()

    init() {
        // left empty
    }
    
    func initProgress() -> Progress {
        progress = ProgressEx()
        return progress
    }
    
    /// - Throws: `ProgressInterruption`
    func encrypt(plainText: ByteArray, key: ByteArray, iv: ByteArray) throws -> ByteArray {
        progress.localizedDescription = NSLocalizedString("Encrypting", comment: "Status message")
        let chacha20 = ChaCha20(key: key, iv: iv)
        return try chacha20.encrypt(data: plainText, progress: progress) // throws ProgressInterruption
    }
    
    /// - Throws: `ProgressInterruption`
    func decrypt(cipherText: ByteArray, key: ByteArray, iv: ByteArray) throws -> ByteArray {
        progress.localizedDescription = NSLocalizedString("Decrypting", comment: "Status message")
        let chacha20 = ChaCha20(key: key, iv: iv)
        return try chacha20.decrypt(data: cipherText, progress: progress) // throws ProgressInterruption
    }
}
