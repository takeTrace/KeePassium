//
//  ChaCha20.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-26.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

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
        progress?.completedUnitCount = progress!.totalUnitCount
        if progress?.isCancelled ?? false {
            throw ProgressInterruption.cancelledByUser()
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
    
    static func selftest() {
        let c1 = ChaCha20(key: ByteArray(count: 32), iv: ByteArray(count: 12))
        let out = try! c1.encrypt(data: ByteArray(count: 64))
        let refOut = ByteArray.init(hexString:  "76b8e0ada0f13d90405d6ae55386bd28bdd219b8a08ded1aa836efcc8b770dc7da41597c5157488d7724e03fb8d84a376a43b8f41518a11cc387b669b2ee6586")!
        print("out: \(out.asHexString)")
        if out == refOut {
            print("Test ok")
        } else {
            print("Test failed")
        }
    }
}

