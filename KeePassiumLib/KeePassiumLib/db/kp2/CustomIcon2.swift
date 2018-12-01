//
//  CustomIcon2.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-02.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation
//import AEXML

/// Custom icon in a KP2 database
public class CustomIcon2: Eraseable {
    public private(set) var uuid: UUID
    public private(set) var data: ByteArray
    
    public var description: String {
        return "CustomIcon(UUID: \(uuid.uuidString), Data: \(data.count) bytes"
    }
    init() {
        uuid = UUID.ZERO
        data = ByteArray()
    }
    deinit {
        erase()
    }
    
    public func erase() {
        uuid.erase()
        data.erase()
    }
    
    /// - Throws: Xml2.ParsingError
    func load(xml: AEXMLElement) throws {
        assert(xml.name == Xml2.icon)
        Diag.verbose("Loading XML: custom icon")
        
        erase()
        var _uuid: UUID?
        var _data: ByteArray?
        for tag in xml.children {
            switch tag.name {
            case Xml2.uuid:
                _uuid = UUID(base64Encoded: tag.value)
            case Xml2.data:
                _data = ByteArray(base64Encoded: tag.value ?? "")
            default:
                Diag.error("Unexpected XML tag in CustomIcon: \(tag.name)")
                throw Xml2.ParsingError.unexpectedTag(actual: tag.name, expected: "CustomIcon/*")
            }
        }
        guard _uuid != nil else {
            Diag.error("Missing CustomIcon/UUID")
            throw Xml2.ParsingError.malformedValue(tag: "CustomIcon/UUID", value: nil)
        }
        guard _data != nil else {
            Diag.error("Missing CustomIcon/Data")
            throw Xml2.ParsingError.malformedValue(tag: "CustomIcon/Data", value: nil)
        }
        self.uuid = _uuid!
        self.data = _data!
    }
    
    func toXml() -> AEXMLElement {
        Diag.verbose("Generating XML: custom icon")
        let xmlIcon = AEXMLElement(name: Xml2.icon)
        xmlIcon.addChild(name: Xml2.uuid, value: uuid.base64EncodedString())
        xmlIcon.addChild(name: Xml2.data, value: data.base64EncodedString())
        return xmlIcon
    }
}
