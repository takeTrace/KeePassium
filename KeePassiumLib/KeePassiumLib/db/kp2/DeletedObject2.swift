//  KeePassium Password Manager
//  Copyright © 2018 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

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

