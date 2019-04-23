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

/// Swift wrapper for C-code salsa20 cipher.
public final class Salsa20: StreamCipher {
    private let blockSize = 64
    private static let sigma: [UInt8] =
        [0x65,0x78,0x70,0x61,0x6e,0x64,0x20,0x33,0x32,0x2d,0x62,0x79,0x74,0x65,0x20,0x6b]
    private var key: SecureByteArray
    private var iv: SecureByteArray
    private var counter: UInt64
    private var block: [UInt8]
    private var posInBlock: Int

    init(key: ByteArray, iv: ByteArray) {
        assert(key.count == 32)
        assert(iv.count == 8)
        
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
        Eraser.erase(array: &block) // preserves the size
        counter = 0
    }

    private func generateBlock() {
        var sigma = Salsa20.sigma
        var counterBytes: [UInt8] = counter.bytes
        iv.withBytes { ivBytes in
            key.withBytes { keyBytes in
                salsa20_core(&block, ivBytes, &counterBytes, keyBytes, &sigma)
            }
        }
    }

    /// XORs `data` with the corresponding number of bytes of Salsa20 stream.
    /// - Throws: `ProgressInterruption`
    func xor(bytes: inout [UInt8], progress: Progress?) throws {
        let progressBatchSize = blockSize * 1024
        progress?.completedUnitCount = 0
        progress?.totalUnitCount = Int64(bytes.count / progressBatchSize) + 1 // +1 because sometimes the ratio is zero, and progress is never finished
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
                throw ProgressInterruption.cancelledByUser
            }
        }
    }
    
    /// XORs `data` with Salsa20 stream and returns the result.
    /// - Throws: `ProgressInterruption`
    func encrypt(data: ByteArray, progress: Progress?=nil) throws -> ByteArray {
        var outBytes = data.bytesCopy()
        try xor(bytes: &outBytes, progress: progress) // throws ProgressInterruption
        return ByteArray(bytes: outBytes)
    }
    
    /// Same as `encrypt`, same XORing with Salsa20 stream.
    /// - Throws: `ProgressInterruption`
    func decrypt(data: ByteArray, progress: Progress?=nil) throws -> ByteArray {
        return try encrypt(data: data, progress: progress) // throws ProgressInterruption
    }
}
