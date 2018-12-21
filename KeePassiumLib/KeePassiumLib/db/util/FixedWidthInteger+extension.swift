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

/// A convenience shortcut
public func sizeof<T: FixedWidthInteger>(_ value: T) -> Int {
    return MemoryLayout.size(ofValue: value)
}

extension FixedWidthInteger {
    init?(data: ByteArray?) {
        guard let data = data else { return nil }
        guard data.count == MemoryLayout<Self>.size else { return nil }
        
//        self = data.withUnsafeBytes { $0.pointee }
        
        self = data.withBytes { bytes in
            return bytes.withUnsafeBytes{ ptr in
                return ptr.load(as: Self.self)
            }
        }
    }
    
    init?(_ value: String?) {
        guard let value = value else {
            return nil
        }
        self.init(value)
    }
    
    var data: ByteArray {
        return ByteArray(bytes: self.bytes)
    }
    
    var bytes: [UInt8] {
        var value = self
        return withUnsafeBytes(of: &value) { Array($0) }
    }
    var asHexString: String {
        let size = MemoryLayout<Self>.size
        return String(format: "%0\(size*2)x", arguments: [self as! CVarArg])
    }
    var byteWidth: Int {
        return bitWidth / UInt8.bitWidth
    }
}
