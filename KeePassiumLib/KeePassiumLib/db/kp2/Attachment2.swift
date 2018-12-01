//
//  Attachment2.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-17.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation
//import AEXML

/// Attachment of a KP2 entry
public class Attachment2: Attachment {
    
    override init(database: Database, id: Int, name: String, isCompressed: Bool, data: ByteArray) {
        super.init(database: database, id: id, name: name, isCompressed: isCompressed, data: data)
    }
    
    /// Creates a clone of the given instance
    override func clone() -> Attachment {
        return Attachment2(
            database: self.database,
            id: self.id,
            name: self.name,
            isCompressed: self.isCompressed,
            data: self.data)
    }
    
    /// Loads a binary attachment of the entry.
    /// - Throws: Xml2.ParsingError
    static func load(
        xml: AEXMLElement,
        database: Database2,
        streamCipher: StreamCipher
        ) throws -> Attachment2
    {
        assert(xml.name == Xml2.binary)
        
        Diag.verbose("Loading XML: entry attachment")
        var name: String?
        var binary: Binary2?
        for tag in xml.children {
            switch tag.name {
            case Xml2.key:
                name = tag.value
            case Xml2.value:
                let refString = tag.attributes[Xml2.ref]
                guard let binaryID = Int(refString) else {
                    Diag.error("Cannot parse Entry/Binary/Value/Ref as Int")
                    throw Xml2.ParsingError.malformedValue(
                        tag: "Entry/Binary/Value/Ref",
                        value: refString)
                }
                if binaryID >= database.binaries.count {
                    Diag.error("BinaryID value is out of range [value: \(binaryID), max: \(database.binaries.count)]")
                    throw Xml2.ParsingError.malformedValue(
                        tag: "Entry/Binary/Value/Ref/Pool",
                        value: nil)
                }
                binary = database.binaries[binaryID]
            default:
                Diag.error("Unexpected XML tag in Entry/Binary: \(tag.name)")
                throw Xml2.ParsingError.unexpectedTag(actual: tag.name, expected: "Entry/Binary/*")
            }
        }
        guard name != nil else {
            Diag.error("Missing Entry/Binary/Name")
            throw Xml2.ParsingError.malformedValue(tag: "Entry/Binary/Name", value: nil)
        }
        guard binary != nil else {
            Diag.error("Missing Entry/Binary/Value")
            throw Xml2.ParsingError.malformedValue(tag: "Entry/Binary/Value", value: nil)
        }
        return Attachment2(
            database: database,
            id: binary!.id,
            name: name!,
            isCompressed: binary!.isCompressed,
            data: binary!.data)
    }
    
    internal func toXml() -> AEXMLElement {
        Diag.verbose("Generating XML: entry attachment")
        let xmlAtt = AEXMLElement(name: Xml2.binary)
        xmlAtt.addChild(name: Xml2.key, value: self.name)
        // No actual data is stored, only a ref to a binary in Meta
        xmlAtt.addChild(name: Xml2.value, value: nil, attributes: [Xml2.ref: String(self.id)])
        return xmlAtt
    }
}
