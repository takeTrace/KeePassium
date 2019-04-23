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

public extension URL {
    
    /// Second-level domain name, if any.
    /// (For example, for "auth.private.example.com" returns "example")
    /// Will not work with IP addresses (e.g. "127.0.0.1" -> "0")
    var domain2: String? {
        guard let names = host?.split(separator: ".") else { return nil }
        let nameCount = names.count
        if nameCount >= 2 {
            return String(names[nameCount - 2])
        }
        return nil
    }
    
    /// Last modiifcation date of a file URL.
    var fileModificationDate: Date? {
        guard let attr = try? FileManager.default
            .attributesOfItem(atPath: self.path) else { return nil }
        return attr[FileAttributeKey.modificationDate] as? Date
    }

    /// Creation date of a file URL.
    var fileCreationDate: Date? {
        guard let attr = try? FileManager.default
            .attributesOfItem(atPath: self.path) else { return nil }
        return attr[FileAttributeKey.creationDate] as? Date
    }
    
    /// Size of the file at this URL.
    var fileSize: Int64? {
        guard let attr = try? FileManager.default
            .attributesOfItem(atPath: self.path) else { return nil}
        return attr[FileAttributeKey.size] as? Int64
    }
    
    /// True for directories.
    var isDirectory: Bool {
        let res = try? resourceValues(forKeys: [.isDirectoryKey])
        return res?.isDirectory ?? false
    }
    
    /// Same URL with last component name replaced with "_redacted_"
    var redacted: URL {
        let isDirectory = self.isDirectory
        return self.deletingLastPathComponent().appendingPathComponent("_redacted_", isDirectory: isDirectory)
//        return self //TODO debug stuff, remove in production
    }
}
