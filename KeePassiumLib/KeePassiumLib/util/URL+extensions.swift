//
//  URL+extensions.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-06.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

public extension URL {
    
    /// Last modiifcation date of a file URL.
    public var fileModificationDate: Date? {
        guard let attr = try? FileManager.default
            .attributesOfItem(atPath: self.path) else { return nil }
        return attr[FileAttributeKey.modificationDate] as? Date
    }

    /// Creation date of a file URL.
    public var fileCreationDate: Date? {
        guard let attr = try? FileManager.default
            .attributesOfItem(atPath: self.path) else { return nil }
        return attr[FileAttributeKey.creationDate] as? Date
    }
    
    /// Size of the file at this URL.
    public var fileSize: Int64? {
        guard let attr = try? FileManager.default
            .attributesOfItem(atPath: self.path) else { return nil}
        return attr[FileAttributeKey.size] as? Int64
    }
    
    /// True for directories.
    public var isDirectory: Bool {
        let res = try? resourceValues(forKeys: [.isDirectoryKey])
        return res?.isDirectory ?? false
    }
    
    /// Same URL with last component name replaced with "_redacted_"
    public var redacted: URL {
        let isDirectory = self.isDirectory
        return self.deletingLastPathComponent().appendingPathComponent("_redacted_", isDirectory: isDirectory)
//        return self //TODO debug stuff, remove in production
    }
}
