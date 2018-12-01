//
//  Entry1.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-04-04.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

/// Entry in a kp1 database.
public class Entry1: Entry {
    private enum FieldID: UInt16 {
        case reserved  = 0x0000
        case uuid      = 0x0001
        case groupID   = 0x0002
        case iconID    = 0x0003
        case title     = 0x0004
        case url       = 0x0005
        case username  = 0x0006
        case password  = 0x0007
        case notes      = 0x0008
        case creationTime      = 0x0009
        case lastModifiedTime  = 0x000A
        case lastAccessTime    = 0x000B
        case expirationTime    = 0x000C
        case binaryDesc        = 0x000D
        case binaryData        = 0x000E
        case end               = 0xFFFF
    }
    
    // predefined field values of meta-stream entries
    private enum MetaStreamID {
        public static let iconID   = IconID(rawValue: 0)!
        public static let title    = "Meta-Info"
        public static let userName = "SYSTEM"
        public static let url      = "$"
        public static let attName  = "bin-stream"
    }
    
    // MARK: Entry1 stuff
    
    //TODO: test if this (get/set) works correctly
    override public var canExpire: Bool {
        get { return expiryTime == Date.kp1Never }
        set {
            let never = Date.kp1Never
            if newValue {
                expiryTime = never
            } else {
                if expiryTime == never {
                    expiryTime = never
                } // else leave the original expiryTime
            }
        }
    }
    internal(set) var groupID: Group1ID
    
    override public var isSupportsExtraFields: Bool { get { return false } }
    
    /// Returns true if this entry is a special KP1 internal meta-stream data.
    var isMetaStream: Bool {
        guard let att = getAttachment() else { return false }
        if notes.isEmpty { return false }
        
        return (iconID == MetaStreamID.iconID) &&
            (att.name == MetaStreamID.attName) &&
            (userName == MetaStreamID.userName) &&
            (url == MetaStreamID.url) &&
            (title == MetaStreamID.title)
    }

    override init(database: Database) {
        groupID = 0
        super.init(database: database)
    }
    deinit {
        erase()
    }
    
    override public func erase() {
        groupID = 0
        super.erase()
    }
    
    /// Returns a new entry instance with the same field values.
    override public func clone() -> Entry {
        let newEntry = Entry1(database: self.database)
        apply(to: newEntry)
        // newEntry.groupID = self.groupID -- to be set when moved to a group

        return newEntry
    }

    /// Copies properties of this entry to the `target`.
    /// Complex properties are cloned.
    /// Does not affect group membership.
    func apply(to target: Entry1) {
        super.apply(to: target)
        // target.groupID is not changed
    }
    
    /// Loads entry fields from the stream.
    /// - Throws: Database1.FormatError
    func load(from stream: ByteArray.InputStream) throws {
        Diag.verbose("Loading entry")
        erase()
        
        var binaryDesc = ""
        var binaryData = ByteArray()
        
        while stream.hasBytesAvailable {
            guard let fieldIDraw = stream.readUInt16() else {
                throw Database1.FormatError.prematureDataEnd
            }
            guard let fieldID = FieldID(rawValue: fieldIDraw) else {
                throw Database1.FormatError.corruptedField(fieldName: "Entry/FieldID")
            }
            guard let _fieldSize = stream.readInt32() else {
                throw Database1.FormatError.prematureDataEnd
            }
            guard _fieldSize >= 0 else {
                throw Database1.FormatError.corruptedField(fieldName: "Entry/FieldSize")
            }

            let fieldSize = Int(_fieldSize)
            
            //TODO: check fieldSize matches the amount of data we are actually reading
            switch fieldID {
            case .reserved:
                // ignored, just skip the content
                guard let _ = stream.read(count: fieldSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
            case .uuid:
                guard let uuid = UUID(data: stream.read(count: fieldSize)) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                self.uuid = uuid
            case .groupID:
                guard let groupID: Group1ID = stream.readInt32() else {
                    throw Database1.FormatError.prematureDataEnd
                }
                self.groupID = groupID
            case .iconID:
                guard let iconIDraw = stream.readUInt32() else {
                    throw Database1.FormatError.prematureDataEnd
                }
                guard let iconID = IconID(rawValue: iconIDraw) else {
                    throw Database1.FormatError.corruptedField(fieldName: "Entry/IconID")
                }
                self.iconID = iconID
            case .title:
                guard let data = stream.read(count: fieldSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                data.trim(toCount: data.count - 1) // drop the zero at the end
                guard let string = data.toString() else {
                    throw Database1.FormatError.corruptedField(fieldName: "Entry/Title")
                }
                self.title = string
            case .url:
                guard let data = stream.read(count: fieldSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                data.trim(toCount: data.count - 1) // drop the zero at the end
                guard let string = data.toString() else {
                    throw Database1.FormatError.corruptedField(fieldName: "Entry/URL")
                }
                self.url = string
            case .username:
                guard let data = stream.read(count: fieldSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                data.trim(toCount: data.count - 1) // drop the zero at the end
                guard let string = data.toString() else {
                    throw Database1.FormatError.corruptedField(fieldName: "Entry/UserName")
                }
                self.userName = string
            case .password:
                guard let data = stream.read(count: fieldSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                data.trim(toCount: data.count - 1) // drop the zero at the end
                guard let string = data.toString() else {
                    throw Database1.FormatError.corruptedField(fieldName: "Entry/Password")
                }
                self.password = string
            case .notes:
                guard let data = stream.read(count: fieldSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                data.trim(toCount: data.count - 1) // drop the zero at the end
                guard let string = data.toString() else {
                    throw Database1.FormatError.corruptedField(fieldName: "Entry/Notes")
                }
                self.notes = string
            case .creationTime:
                guard let rawTimeData = stream.read(count: Date.kp1TimestampSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                guard let date = Date(kp1Bytes: rawTimeData) else {
                    throw Database1.FormatError.corruptedField(fieldName: "Entry/CreationTime")
                }
                self.creationTime = date
            case .lastModifiedTime:
                guard let rawTimeData = stream.read(count: Date.kp1TimestampSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                guard let date = Date(kp1Bytes: rawTimeData) else {
                    throw Database1.FormatError.corruptedField(fieldName: "Entry/LastModifiedTime")
                }
                self.lastModificationTime = date
            case .lastAccessTime:
                guard let rawTimeData = stream.read(count: Date.kp1TimestampSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                guard let date = Date(kp1Bytes: rawTimeData) else {
                    throw Database1.FormatError.corruptedField(fieldName: "Entry/LastAccessTime")
                }
                self.lastAccessTime = date
            case .expirationTime:
                guard let rawTimeData = stream.read(count: Date.kp1TimestampSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                guard let date = Date(kp1Bytes: rawTimeData) else {
                    throw Database1.FormatError.corruptedField(fieldName: "Entry/ExpirationTime")
                }
                self.expiryTime = date
            case .binaryDesc:
                guard let data = stream.read(count: fieldSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                data.trim(toCount: data.count - 1) // drop the zero at the end
                guard let string = data.toString() else {
                    throw Database1.FormatError.corruptedField(fieldName: "Entry/BinaryDesc")
                }
                binaryDesc = string
            case .binaryData:
                guard let data = stream.read(count: fieldSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                binaryData = data
            case .end:
                // entry fields finished
                guard let _ = stream.read(count: fieldSize) else {
                    throw Database1.FormatError.prematureDataEnd
                }
                if binaryDesc.isNotEmpty {
                    let att = Attachment(
                        database: self.database,
                        id: 0,
                        name: binaryDesc,
                        isCompressed: false,
                        data: binaryData)
                    addAttachment(attachment: att)
                }
                return
            } // switch
        } // while
        
        // if we are here, there was no .end field
        Diag.warning("Entry data missing the .end field")
        throw Database1.FormatError.prematureDataEnd
    }
    
    /// Writes entry fields to the stream.
    func write(to stream: ByteArray.OutputStream) {
        func writeField(fieldID: FieldID, data: ByteArray, addTrailingZero: Bool = false) {
            stream.write(value: fieldID.rawValue)
            if addTrailingZero {
                stream.write(value: UInt32(data.count + 1))
                stream.write(data: data)
                stream.write(value: UInt8(0))
            } else {
                stream.write(value: UInt32(data.count))
                stream.write(data: data)
            }
        }
        writeField(fieldID: .uuid, data: uuid.data)
        writeField(fieldID: .groupID, data: groupID.data)
        writeField(fieldID: .iconID, data: iconID.rawValue.data)
        writeField(fieldID: .title, data: ByteArray(utf8String: title)!, addTrailingZero: true)
        writeField(fieldID: .url, data: ByteArray(utf8String: url)!, addTrailingZero: true)
        writeField(fieldID: .username, data: ByteArray(utf8String: userName)!, addTrailingZero: true)
        writeField(fieldID: .password, data: ByteArray(utf8String: password)!, addTrailingZero: true)
        writeField(fieldID: .notes, data: ByteArray(utf8String: notes)!, addTrailingZero: true)
        writeField(fieldID: .creationTime, data: creationTime.asKP1Bytes())
        writeField(fieldID: .lastModifiedTime, data: lastModificationTime.asKP1Bytes())
        writeField(fieldID: .lastAccessTime, data: lastAccessTime.asKP1Bytes())
        writeField(fieldID: .expirationTime, data: expiryTime.asKP1Bytes())
        
        if let att = getAttachment() {
            writeField(fieldID: .binaryDesc, data: ByteArray(utf8String: att.name)!, addTrailingZero: true)
            writeField(fieldID: .binaryData, data: att.data)
        } else {
            //KP1 saves empty fields even if there is no attachment.
            let emptyData = ByteArray()
            writeField(fieldID: .binaryDesc, data: emptyData)
            writeField(fieldID: .binaryData, data: emptyData)
        }
        writeField(fieldID: .end, data: ByteArray())
    }
    
    /// Checks if the entry matches given search `query`.
    /// (That is, each query word is present in at least one of the fields
    /// [title, user name, url, notes, attachment names].)
    override public func matches(query: SearchQuery) -> Bool {
        if super.matches(query: query) {
            return true
        }
        guard let att = getAttachment() else {
            return false
        }
        
        // Check if every query word is in attachment name
        for word in query.textWords {
            if !att.name.contains(word) {
                return false
            }
        }
        return true
    }
    
    /// Makes a backup copy of the current values/state of the entry.
    /// For KP1 means copying the whole entry to the Backup group.
    /// - Returns: true if successful, false otherwise.
    override public func backupState() -> Bool {
        let copy = self.clone()

        // Backup copies must have unique IDs, so make one
        copy.uuid = UUID()
        return copy.moveToBackup()
    }
    
    /// Moves the entry to the Backup group.
    /// - Returns: true if successful, false otherwise.
    override public func moveToBackup() -> Bool {
        guard let backupGroup = database.getBackupGroup(createIfMissing: true) else {
            Diag.warning("Failed to get or create backup group")
            return false
        }
        backupGroup.moveEntry(entry: self)
        self.accessed()
        self.isDeleted = true
        Diag.info("moveToBackup OK");
        return true;
    }

    /// Returns entry's only attachment, if any.
    internal func getAttachment() -> Attachment? {
        return attachments.first
    }
    
    /// Adds the `attachment` to the entry, if there is no attachment yet.
    /// If there is already one, does nothing.
    override public func addAttachment(attachment: Attachment) {
        if self.attachments.isEmpty {
            super.addAttachment(attachment: attachment)
        }
    }
    
    /// Loads the given file and attaches it to the entry.
    /// Makes a backup of the initial entry state.
    /// Replaces the existing attachment, if any.
    /// Returns true if successful, false in case of any error.
    override public func attachFile(filePath: String) -> Bool {
        // Compressed attachments are not supported in V3
        guard let att = Attachment.createFromFile(filePath: filePath, allowCompression: false) else {
            Diag.warning("Failed to create attachment")
            return false
        }
        
        self.modified()
        guard self.backupState() else {
            Diag.warning("Failed to backup state")
            return false
        }
        attachments.removeAll()
        addAttachment(attachment: att)
        return true
    }
}
