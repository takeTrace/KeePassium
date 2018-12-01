//
//  DataCipher.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-21.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

protocol DataCipher {
    var uuid: UUID { get }
    var initialVectorSize: Int { get }
    var keySize: Int { get }
    var name: String { get }
    
    func initProgress() -> Progress
    
    /// - Throws: `CryptoError`, `ProgressInterruption`
    func encrypt(plainText: ByteArray, key: ByteArray, iv: ByteArray) throws -> ByteArray
    /// - Throws: `CryptoError`, `ProgressInterruption`
    func decrypt(cipherText: ByteArray, key: ByteArray, iv: ByteArray) throws -> ByteArray
    
    /// Create a compatibly-sized cipher key from the given key
    func resizeKey(key: ByteArray) -> SecureByteArray
}

extension DataCipher {
    
    /// Create a compatibly-sized cipher key from the given key
    func resizeKey(key: ByteArray) -> SecureByteArray {
        assert(key.count > 0)
        assert(keySize >= 0)
        
        if keySize == 0 {
            return SecureByteArray(ByteArray(count: 0))
        }
        
        let hash = (keySize <= 32) ? key.sha256 : key.sha512
        if hash.count == keySize {
            return SecureByteArray(hash)
        }
        
        if keySize < hash.count {
            return SecureByteArray(hash.prefix(keySize))
        } else {
            //TODO: not needed for current ciphers (AES, ChaCha20), but implement this for future
            fatalError("Not implemented")
        }
    }
}
