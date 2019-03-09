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

/// Swift wrapper for C-code chacha20 cipher.
public final class ChaCha20: StreamCipher {

    public static let nonceSize = 12 // 12 * 8 = 96 bit
    private let blockSize = 64
    private var key: SecureByteArray
    private var iv: SecureByteArray
    private var counter: UInt32
    private var block: [UInt8]
    private var posInBlock: Int
    
    init(key: ByteArray, iv: ByteArray) {
        precondition(key.count == 32, "ChaCha20 expects 32-byte key")
        precondition(iv.count == ChaCha20.nonceSize, "ChaCha20 expects \(ChaCha20.nonceSize)-byte IV")
        
        self.key = SecureByteArray(key)
        self.iv = SecureByteArray(iv)
        block = [UInt8](repeating: 0, count: blockSize)
        counter = 0
        posInBlock = blockSize
    }
    deinit {
        erase()
    }
    
    public func erase() {
        key.erase()
        iv.erase()
        Eraser.erase(array: &block) // does not change size
        counter = 0
    }
    
    private func generateBlock() {
        var counterBytes = counter.bytes
        iv.withBytes { ivBytes in
            key.withBytes { keyBytes in
                chacha20_make_block(keyBytes, ivBytes, &counterBytes, &block)
            }
        }
    }
    
    /// XORs `bytes` with the corresponding number of bytes of ChaCha20 stream.
    /// - Throws: `ProgressInterruption`
    func xor(bytes: inout [UInt8], progress: Progress?) throws {
        let progressBatchSize = blockSize * 1024
        progress?.completedUnitCount = 0
        
        progress?.totalUnitCount = Int64(bytes.count / progressBatchSize) + 1
        // +1 because sometimes the ratio is zero, and progress is never finished
        
        for i in 0..<bytes.count {
            if posInBlock == blockSize {
                generateBlock()
                counter += 1
                posInBlock = 0
                if (i % progressBatchSize == 0) {
                    progress?.completedUnitCount += 1
                    if progress?.isCancelled ?? false { break }
                }
            }
            bytes[i] ^= block[posInBlock]
            posInBlock += 1
        }
        if let progress = progress {
            progress.completedUnitCount = progress.totalUnitCount
            if progress.isCancelled {
                throw ProgressInterruption.cancelledByUser()
            }
        }
    }
    
    /// XORs `data` with ChaCha20 stream and returns the result.
    /// - Throws: `ProgressInterruption`
    func encrypt(data: ByteArray, progress: Progress?=nil) throws -> ByteArray {
        var outBytes = data.bytesCopy()
        try xor(bytes: &outBytes, progress: progress) // throws ProgressInterruption
        return ByteArray(bytes: outBytes)
    }
    
    /// Same as `encrypt`: XORing with ChaCha20 stream.
    /// - Throws: `ProgressInterruption`
    func decrypt(data: ByteArray, progress: Progress?=nil) throws -> ByteArray {
        return try encrypt(data: data, progress: progress) // throws ProgressInterruption
    }
}

