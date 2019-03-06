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

/// A file attached to an entry
public class Attachment: Eraseable {
    public var name: String
    public internal(set) var isCompressed: Bool
    public internal(set) var data: ByteArray {
        didSet {
            uncompressedSize = -1
        }
    }
    public internal(set) var uncompressedSize: Int

    /// Size of _uncompressed_ data
    public var size: Int {
        if uncompressedSize < 0 {
            if isCompressed {
                uncompressedSize = (try? data.gunzipped().count) ?? 0
            } else {
                uncompressedSize = data.count
            }
        }
        return uncompressedSize
    }
    
    public init(name: String, isCompressed: Bool, data: ByteArray) {
        self.name = name
        self.isCompressed = isCompressed
        self.data = data.clone()
        self.uncompressedSize = -1
    }
    deinit {
        erase()
    }
    
    /// Creates a clone of this instance
    public func clone() -> Attachment {
        return Attachment(
            name: self.name,
            isCompressed: self.isCompressed,
            data: self.data
        )
    }
    
    public func erase() {
        name.erase()
        isCompressed = false
        data.erase()
        uncompressedSize = -1
    }
}
