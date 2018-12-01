//
//  StreamCipher.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-26.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

/// Generic stream cipher
protocol StreamCipher: Eraseable {
    /// Throws: ProgressInterruption
    func encrypt(data: ByteArray, progress: Progress?) throws -> ByteArray
    /// Throws: ProgressInterruption
    func decrypt(data: ByteArray, progress: Progress?) throws -> ByteArray
}
