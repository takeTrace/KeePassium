//
//  TwofishDataCipher.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-04-10.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

final class TwofishDataCipher: DataCipher {
    private let _uuid = UUID(uuid:
        (0xad,0x68,0xf2,0x9f,0x57,0x6f,0x4b,0xb9,0xa3,0x6a,0xd4,0x7a,0xf9,0x65,0x34,0x6c))
    var uuid: UUID { return _uuid }
    var name: String { return "Twofish" }
    
    var initialVectorSize: Int { return Twofish.blockSize }
    var keySize: Int { return 32 }
    
    private var progress = ProgressEx()
    
    init() {
        // left empty
    }

    func initProgress() -> Progress {
        progress = ProgressEx()
        return progress
    }

    /// Encrypts `plainText` using Twofish (automatically adding PKCS7 padding).
    /// - Parameter: data - plain text data
    /// - Parameter: key - encryption key
    /// - Parameter: iv - initial vector
    /// - Throws: `CryptoError.twofishError`, `ProgressInterruption`
    /// - Returns: encrypted data
    func encrypt(plainText data: ByteArray, key: ByteArray, iv: ByteArray) throws -> ByteArray {
        assert(key.count == self.keySize)
        assert(iv.count == self.initialVectorSize)
        
        progress.localizedDescription = NSLocalizedString("Encrypting", comment: "Status message")
        let twofish = Twofish(key: key, iv: iv)
        var dataClone = data.clone() //FIXME: cmon, making a copy is just ridiculous
        try twofish.encrypt(data: dataClone, progress: progress)
            // throws CryptoError.twofishError, ProgressInterruption
        return dataClone
    }
    
    /// Decrypts data with Twofish, also removing PKCS7 padding.
    /// - Parameter: key - encryption key
    /// - Parameter: iv - initial vector
    /// - Parameter: encData - encrypted data
    /// - Throws: `CryptoError.twofishError`, `ProgressInterruption`
    /// - Returns: decrypted data
    func decrypt(cipherText encData: ByteArray, key: ByteArray, iv: ByteArray) throws -> ByteArray {
        assert(key.count == self.keySize)
        assert(iv.count == self.initialVectorSize)
        progress.localizedDescription = NSLocalizedString("Decrypting", comment: "Status message")
        
        let twofish = Twofish(key: key, iv: iv) 
        var dataClone = encData.clone() //FIXME: cmon, making a copy is just ridiculous
        try twofish.decrypt(data: dataClone, progress: progress)
            // throws CryptoError.twofishError, ProgressInterruption
        return dataClone
    }
}
