//
//  DeletedObject2.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-08.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation
//import AEXML

/// KP2 databases may maintain a list of deleted object.
/// This class represents items of that list.
public class DeletedObject2: Eraseable {
    private unowned var database: Database2
    private(set) var uuid: UUID
    private(set) var deletionTime: Date
    
    init(database: Database2, uuid: UUID) {
        self.database = database
        self.uuid = uuid
        self.deletionTime = Date.now
    }
    convenience init(database: Database2) {
        self.init(database: database, uuid: UUID.ZERO)
    }
    deinit {
        erase()
    }
    
    public func erase() {
        uuid.erase()
        deletionTime = Date.now
    }
    
    /// - Throws: Xml2.ParsingError
    func load(xml: AEXMLElement) throws {
        assert(xml.name == Xml2.deletedObject)
        Diag.verbose("Loading XML: deleted object")
        erase()
        for tag in xml.children {
            switch tag.name {
            case Xml2.uuid:
                self.uuid = UUID(base64Encoded: tag.value) ?? UUID.ZERO
            case Xml2.deletionTime:
                guard let deletionTime = database.xmlStringToDate(tag.value) else {
                    Diag.error("Cannot parse DeletedObject/DeletionTime as Date")
                    throw Xml2.ParsingError.malformedValue(
                        tag: "DeletedObject/DeletionTime",
                        value: tag.value)
                }
                self.deletionTime = deletionTime
            default:
                Diag.error("Unexpected XML tag in DeletedObject: \(tag.name)")
                throw Xml2.ParsingError.unexpectedTag(
                    actual: tag.name,
                    expected: "DeletedObject/*")
            }
        }
    }
    
    func toXml() -> AEXMLElement {
        Diag.verbose("Generating XML: deleted object")
        let xml = AEXMLElement(name: Xml2.deletedObject)
        xml.addChild(name: Xml2.uuid, value: uuid.base64EncodedString())
        xml.addChild(name: Xml2.deletionTime, value: database.xmlDateToString(deletionTime))
        return xml
    }
}

