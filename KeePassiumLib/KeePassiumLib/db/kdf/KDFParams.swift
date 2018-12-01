//
//  KDFParams.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-26.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

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
