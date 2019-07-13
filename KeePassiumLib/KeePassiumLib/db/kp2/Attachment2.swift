//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation
//import AEXML

/// Attachment of a KP2 entry
public class Attachment2: Attachment {
    /// Reference to binary pool, is updated externally before saving.
    public var id: Int

    public convenience override init(name: String, isCompressed: Bool, data: ByteArray) {
        self.init(id: -1, name: name, isCompressed: isCompressed, data: data)
    }

    public init(id: Int, name: String, isCompressed: Bool, data: ByteArray) {
        self.id = id
        super.init(name: name, isCompressed: isCompressed, data: data)
    }
    
    /// Creates a clone of the given instance
    override public func clone() -> Attachment {
        return Attachment2(
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

                if let binaryInDatabasePool = database.binaries[binaryID] {
                    binary = binaryInDatabasePool
                } else {
                    // It is possible that `database.binaries` does not have anything for `binaryID`,
                    // due to a database corruption (https://github.com/mmcguill/Strongbox/issues/74).
                    //
                    // This will be checked and handled in `Database2.checkAttachmentIntegrity()`.
                    // To reach the integrity check, we just ignore the issue,
                    // plug the hole with a fake zero-size binary, and continue XML parsing,
                    binary = Binary2(
                        id: binaryID,
                        data: ByteArray(),
                        isCompressed: false,
                        isProtected: false
                    )
                }
            default:
                Diag.error("Unexpected XML tag in Entry/Binary: \(tag.name)")
                throw Xml2.ParsingError.unexpectedTag(actual: tag.name, expected: "Entry/Binary/*")
            }
        }
        let _name = name ?? ""
        if _name.isEmpty {
            // This was reported to happen on old DBs and after KeePass Touch.
            // We'll stub the name with an empty string, just to reach the integrity check
            // which will finally handle this as a user-visible warning.
            Diag.error("Missing Entry/Binary/Name, ignoring")
        }
        guard let _binary = binary else {
            Diag.error("Missing Entry/Binary/Value")
            throw Xml2.ParsingError.malformedValue(tag: "Entry/Binary/Value/Ref", value: nil)
        }
        return Attachment2(
            id: _binary.id,
            name: _name,
            isCompressed: _binary.isCompressed,
            data: _binary.data)
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
