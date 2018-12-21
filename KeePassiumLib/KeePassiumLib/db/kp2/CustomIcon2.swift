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
