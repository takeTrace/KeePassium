//
//  Binary2.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-02.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation
//import AEXML

/// Binary data stored in DB metadata
public class Binary2: Eraseable {
    private(set) var id: Int
    private(set) var data: ByteArray
    private(set) var isCompressed: Bool
    private(set) var isProtected: Bool
    /// KP2 v4 inner header flags
    public var flags: UInt8 {
        return isProtected ? 1 : 0
    }
    
    init(id: Int, data: ByteArray, isCompressed: Bool, isProtected: Bool=false) {
        self.id = id
        self.data = data.clone()
        self.isCompressed = isCompressed
        self.isProtected = isProtected
    }
    convenience init() {
        self.init(id: -1, data: ByteArray(), isCompressed: false)
    }
    deinit {
        erase()
    }
    
    public func erase() {
        id = -1
        isCompressed = false
        isProtected = false
        data.erase()
    }
    
    /// - Throws: `Xml2.ParsingError`, `ProgressInterruption`
    func load(xml: AEXMLElement, streamCipher: StreamCipher) throws {
        assert(xml.name == Xml2.binary)
        Diag.verbose("Loading XML: binary")
        erase()
        let idString = xml.attributes[Xml2.id]
        guard let id = Int(idString) else {
            Diag.error("Cannot parse Meta/Binary/ID as Int")
            throw Xml2.ParsingError.malformedValue(tag: "Meta/Binary/ID", value: idString)
        }
        let isCompressedString = xml.attributes[Xml2.compressed]
        let isProtectedString = xml.attributes[Xml2.protected]
        let isCompressed: Bool = Bool(string: isCompressedString ?? "")
        let isProtected: Bool = Bool(string: isProtectedString ?? "")
        let base64 = xml.value ?? ""
        guard var data = ByteArray(base64Encoded: base64) else {
            Diag.error("Cannot parse Meta/Binary/Value as Base64 string")
            throw Xml2.ParsingError.malformedValue(tag: "Meta/Binary/ValueBase64", value: String(base64.prefix(16)))
        }
        // Note: data can actually be empty
        
        if isProtected {
            Diag.verbose("Decrypting binary")
            data = try streamCipher.decrypt(data: data, progress: nil) // throws ProgressInterruption
        }
        
        self.id = id
        self.isCompressed = isCompressed
        self.isProtected = isProtected
        self.data = data
    }
    
    /// Throws: `ProgressInterruption`
    func toXml(streamCipher: StreamCipher) throws -> AEXMLElement {
        Diag.verbose("Generating XML: binary")
        var attributes = [
            Xml2.id: String(id),
            Xml2.compressed: isCompressed ? Xml2._true : Xml2._false
        ]
        
        let value: ByteArray
        if isProtected {
            Diag.verbose("Encrypting binary")
            value = try streamCipher.encrypt(data: data, progress: nil) // throws ProgressInterruption
            attributes[Xml2.protected] = Xml2._true
        } else {
            value = data
        }
        return AEXMLElement(
            name: Xml2.binary,
            value: value.base64EncodedString(),
            attributes: attributes)
    }
}
