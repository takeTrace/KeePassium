//
//  Attachment.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-17.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

/// A file attached to an entry
public class Attachment: Eraseable {
    unowned let database: Database
    public internal(set) var id: Int
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
    
    internal init(database: Database, id: Int, name: String, isCompressed: Bool, data: ByteArray) {
        self.database = database
        self.id = id
        self.name = name
        self.isCompressed = isCompressed
        self.data = data.clone()
        self.uncompressedSize = -1
    }
    deinit {
        erase()
    }
    
    /// Creates a clone of the given instance
    /// Pure virtual mehtod, must be overriden.
    internal func clone() -> Attachment {
        fatalError("Pure virtual method")
    }
    
    public func erase() {
        id = 0
        name.erase()
        isCompressed = false
        data.erase()
        uncompressedSize = -1
    }
    
    /// Loads the given file and returns the corresponding `Attachment` instance.
    /// - Parameter filePath: path to the file to attach
    /// - Parameter allowCompression: whether to try to compress the attachment
    /// (KP1 databases must set this to false)
    /// - Returns: true if successful, false otherwise.
    public static func createFromFile(filePath: String, allowCompression: Bool) -> Attachment? {
        //TODO implement this
        assertionFailure("implement this")
        return nil
    }
}
