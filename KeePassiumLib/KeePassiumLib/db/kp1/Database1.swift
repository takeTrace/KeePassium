//
//  Database1.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-04-04.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

/// KP1 database
public class Database1: Database {
    /// An issue with database format: chechsum mismatch, etc
    public enum FormatError: LocalizedError {
        /// File is too short
        case prematureDataEnd
        /// Field size or content does not match expected format
        case corruptedField(fieldName: String?)
        /// An entry with non-existent groupID
        case orphanedEntry
        public var errorDescription: String? {
            switch self {
            case .prematureDataEnd:
                return NSLocalizedString("Unexpected end of file. Corrupted DB file?", comment: "Error message")
            case .corruptedField(let fieldName):
                if fieldName != nil {
                    return NSLocalizedString("Error parsing field \(fieldName!). Corrupted DB file?", comment: "Error message, with the name of problematic field")
                } else {
                    return NSLocalizedString("Database file is corrupted.", comment: "Error message")
                }
            case .orphanedEntry:
                return NSLocalizedString("Found an entry outside any group. Corrupted DB file?", comment: "Error message")
            }
        }
    }
    
    private enum ProgressSteps {
        static let all: Int64 = 100
        static let keyDerivation: Int64 = 60
        
        static let decryption: Int64 = 30
        static let parsing: Int64 = 10

        static let encryption: Int64 = 30
        static let packing: Int64 = 10
    }
    
    override public var keyHelper: KeyHelper { return _keyHelper }
    private let _keyHelper = KeyHelper1()
    
    private(set) var header: Header1!
    private(set) var compositeKey = SecureByteArray()
    private(set) var masterKey = SecureByteArray()
    private(set) var backupGroup: Group1?
    private var metaStreamEntries = ContiguousArray<Entry1>()

    override public init() {
        super.init()
        header = Header1(database: self)
    }
    deinit {
        erase()
    }
    override public func erase() {
        header.erase()
        compositeKey.erase()
        masterKey.erase()
        backupGroup?.erase()
        backupGroup = nil
        for metaEntry in metaStreamEntries {
            metaEntry.erase()
        }
        metaStreamEntries.removeAll()
        Diag.debug("Database erased")
    }

    /// Generates a new group ID (guaranteed to be unique in this DB)
    func createNewGroupID() -> Group1ID {
        var groups = Array<Group>()
        var entries = Array<Entry>()
        root!.collectAllChildren(groups: &groups, entries: &entries)
        
        var takenIDs = ContiguousArray<Int32>()
        takenIDs.reserveCapacity(groups.count)
        var maxID: Int32 = 0
        for group in groups {
            let id = (group as! Group1).id
            if id > maxID { maxID = id}
            takenIDs.append(id)
        }
        groups.removeAll()
        entries.removeAll()
        
        var newID = maxID + 1
        while takenIDs.contains(newID) {
            newID = newID &+ 1 // &+ allows for potential Int32 overflow
        }
        return newID
    }
    
    /// Returns the Backup group of this database
    /// (or creates one, if `createIfMissing` is true).
    override public func getBackupGroup(createIfMissing: Bool) -> Group? {
        assert(root != nil)
        if backupGroup == nil && createIfMissing {
            // There's no backup group, let's make one
            backupGroup = (root!.createGroup() as! Group1)
            backupGroup!.name = Group1.backupGroupName
            backupGroup!.iconID = Group1.backupGroupIconID
            backupGroup!.isDeleted = true
        }
        return backupGroup
    }

    /// Checks if given data starts with compatible KP2 signature.
    override public class func isSignatureMatches(data: ByteArray) -> Bool {
        return Header1.isSignatureMatches(data: data)
    }

    /// Changes DB's composite key to the provided one.
    /// Don't forget to call `deriveMasterKey` before saving.
    ///
    /// - Parameter newKey: new composite key.
    override public func changeCompositeKey(to newKey: SecureByteArray) {
        compositeKey = newKey
    }
    
    /// Decrypts DB data using the given compositeKey.
    /// - Throws: `DatabaseError.loadError`, `DatabaseError.invalidKey`, `ProgressInterruption`
    override public func load(dbFileData: ByteArray, compositeKey: SecureByteArray) throws {
        Diag.info("Loading KP1 database")
        progress.completedUnitCount = 0
        progress.totalUnitCount = ProgressSteps.all
        do {
            try header.read(data: dbFileData) // throws Header1.Error
            Diag.debug("Header read OK")
            
            try deriveMasterKey(compositeKey: compositeKey)
                // throws CryptoError, ProgressInterruption
            Diag.debug("Key derivation OK")
            
            // Decrypt data
            let dbWithoutHeader = dbFileData.suffix(from: header.count)
            let decryptedData = try decrypt(data: dbWithoutHeader)
                // throws CryptoError, ProgressInterruption
            Diag.debug("Decryption OK")
            guard decryptedData.sha256 == header.contentHash else {
                Diag.error("Header hash mismatch - invalid master key?")
                throw DatabaseError.invalidKey
            }
            
            /// Reading and parsing data
            try loadContent(data: decryptedData) // throws FormatError, ProgressInterruption
            Diag.debug("Content loaded OK")

            // all good, so remember combinedKey for eventual saving
            self.compositeKey = compositeKey
        } catch let error as Header1.Error {
            Diag.error("Header error [reason: \(error.localizedDescription)]")
            throw DatabaseError.loadError(reason: error.localizedDescription)
        } catch let error as CryptoError {
            Diag.error("Crypto error [reason: \(error.localizedDescription)]")
            throw DatabaseError.loadError(reason: error.localizedDescription)
        } catch let error as FormatError {
            Diag.error("Format error [reason: \(error.localizedDescription)]")
            throw DatabaseError.loadError(reason: error.localizedDescription)
        } // ProgressInterruption is passed further out
    }
    
    /// - Throws: `CryptoError`, `ProgressInterruption`
    func deriveMasterKey(compositeKey: SecureByteArray) throws {
        Diag.debug("Start key derivation")
        let kdf = AESKDF()
        progress.addChild(kdf.initProgress(), withPendingUnitCount: ProgressSteps.keyDerivation)
        let kdfParams = kdf.defaultParams
        kdfParams.setValue(
            key: AESKDF.transformSeedParam,
            value: VarDict.TypedValue(value: header.transformSeed))
        kdfParams.setValue(
            key: AESKDF.transformRoundsParam,
            value: VarDict.TypedValue(value: UInt64(header.transformRounds)))
        
        let transformedKey = try kdf.transform(key: compositeKey, params: kdfParams)
            // throws CryptoError, ProgressInterruption
        masterKey = SecureByteArray(ByteArray.concat(header.masterSeed, transformedKey).sha256)
    }
    
    /// Reads groups and entries from plain-text `data`
    /// and arranges them into a hierarchy.
    /// - Throws: `Database1.FormatError`, `ProgressInterruption`
    private func loadContent(data: ByteArray) throws {
        let stream = data.asInputStream()
        stream.open()
        defer { stream.close() }
        
        let loadProgress = ProgressEx()
        loadProgress.totalUnitCount = Int64(header.groupCount + header.entryCount)
        loadProgress.localizedDescription = NSLocalizedString("Parsing content", comment: "Status message: processing the content of a database")
        self.progress.addChild(loadProgress, withPendingUnitCount: ProgressSteps.parsing)
        
        // load all groups
        Diag.debug("Loading groups")
        var groups = ContiguousArray<Group1>()
        var groupByID = [Group1ID : Group1]() // will need these for restoring the hierarchy
        var maxLevel = 0                      // of groups and entries
        for _ in 0..<header.groupCount {
            loadProgress.completedUnitCount += 1
            let group = Group1(database: self)
            try group.load(from: stream) // throws FormatError
            if group.isDeleted {
                backupGroup = group
            }
            if group.level > maxLevel {
                maxLevel = Int(group.level)
            }
            groupByID[group.id] = group
            groups.append(group)
        }

        // load all entries
        Diag.debug("Loading entries")
        var entries = ContiguousArray<Entry1>()
        for _ in 0..<header.entryCount {
            let entry = Entry1(database: self)
            try entry.load(from: stream) // throws FormatError
            entries.append(entry)
            loadProgress.completedUnitCount += 1
            if loadProgress.isCancelled {
                throw ProgressInterruption.cancelledByUser()
            }
        }
        Diag.info("Loaded \(groups.count) groups and \(entries.count) entries")
        
        // create root group
        let _root = Group1(database: self)
        _root.level = -1 // because its children should have level 0
        _root.iconID = Group.defaultIconID // created subgroups will use this icon
        _root.name = "/" // TODO: give the "virtual" root group a more meaningful name
        self.root = _root
        
        // restore group hierarchy
        var parentGroup = root!
        for level in 0...maxLevel {
            let prevLevel = level - 1
            for group in groups {
                if group.level == level {
                    parentGroup.add(group: group)
                } else if group.level == prevLevel {
                    parentGroup = group
                }
            }
        }
        
        // put entries to their groups
        Diag.debug("Moving entries to their groups")
        for entry in entries {
            if entry.isMetaStream {
                // meta streams are kept in a separate list, invisible for the user
                metaStreamEntries.append(entry);
            } else {
                guard let group = groupByID[entry.groupID] else { throw FormatError.orphanedEntry }
                entry.isDeleted = group.isDeleted
                group.add(entry: entry)
            }
        }
    }
    
    /// Decrypts DB data using current master key.
    /// - Throws: CryptoError, ProgressInterruption
    func decrypt(data: ByteArray) throws -> ByteArray {
        switch header.algorithm {
        case .aes:
            Diag.debug("Decrypting AES cipher")
            let cipher = AESDataCipher()
            progress.addChild(cipher.initProgress(), withPendingUnitCount: ProgressSteps.decryption)
            let decrypted = try cipher.decrypt(cipherText: data, key: masterKey, iv: header.initialVector)
                // throws CryptoError, ProgressInterruption
            return decrypted
        case .twofish:
            Diag.debug("Decrypting Twofish cipher")
            let cipher = TwofishDataCipher()
            progress.addChild(cipher.initProgress(), withPendingUnitCount: ProgressSteps.decryption)
            let decrypted = try cipher.decrypt(cipherText: data, key: masterKey, iv: header.initialVector)
                // throws CryptoError, ProgressInterruption
            return decrypted
        }
    }
    
    /// Encrypts the DB and returns the result as byte array.
    /// Progress, errors and outcomes are reported to status delegate.
    ///
    /// - Throws: `DatabaseError.saveError`, `ProgressInterruption`
    /// - Returns: encrypted DB bytes.
    override public func save() throws -> ByteArray {
        Diag.info("Saving KP1 database")
        let contentStream = ByteArray.makeOutputStream()
        contentStream.open()
        
        progress.completedUnitCount = 0
        progress.totalUnitCount = ProgressSteps.all
        do {
            var groups = Array<Group>()
            var entries = Array<Entry>()
            root!.collectAllChildren(groups: &groups, entries: &entries)
            Diag.info("Saving \(groups.count) groups and \(entries.count)+\(metaStreamEntries.count) entries")
            
            let packingProgress = ProgressEx()
            packingProgress.totalUnitCount = Int64(groups.count + entries.count + metaStreamEntries.count)
            packingProgress.localizedDescription = NSLocalizedString("Packing the content", comment: "Status message: collecting database items into a single package")
            progress.addChild(packingProgress, withPendingUnitCount: ProgressSteps.packing)
            Diag.debug("Packing the content")
            // write groups and entries in a buffer
            for group in groups {
                (group as! Group1).write(to: contentStream)
                packingProgress.completedUnitCount += 1
            }
            for entry in entries {
                (entry as! Entry1).write(to: contentStream)
                packingProgress.completedUnitCount += 1
                if packingProgress.isCancelled {
                    throw ProgressInterruption.cancelledByUser()
                }
            }
            Diag.debug("Writing meta-stream entries")
            // also write the meta-stream entries (which are not included in the above list)
            for metaEntry in metaStreamEntries {
                metaEntry.write(to: contentStream)
                print("Wrote a meta-stream entry: \(metaEntry.notes)")
                packingProgress.completedUnitCount += 1
                if packingProgress.isCancelled {
                    throw ProgressInterruption.cancelledByUser()
                }
            }
            contentStream.close()
            let contentData = contentStream.data!
        
            // update the header
            Diag.debug("Updating the header")
            header.groupCount = groups.count
            header.entryCount = entries.count + metaStreamEntries.count
            header.contentHash = contentData.sha256
        
            // update encryption seeds and transform the keys
            try header.randomizeSeeds() // throws CryptoError
            try deriveMasterKey(compositeKey: self.compositeKey)
                // throws CryptoError, ProgressInterruption
            Diag.debug("Key derivation OK")
            
            // encrypt the content
            let encryptedContent = try encrypt(data: contentData)
                // throws CryptoError, ProgressInterruption
            Diag.debug("Content encryption OK")
            
            // actually write everything out
            let outStream = ByteArray.makeOutputStream()
            outStream.open()
            defer { outStream.close() }
            header.write(to: outStream)
            outStream.write(data: encryptedContent)
            return outStream.data!
        } catch let error as CryptoError {
            throw DatabaseError.saveError(reason: error.localizedDescription)
        } // ProgressInterruption is passed further up
    }
    
    /// Encrypts DB data using current master key.
    /// - Throws: CryptoError, ProgressInterruption
    func encrypt(data: ByteArray) throws -> ByteArray {
        switch header.algorithm {
        case .aes:
            Diag.debug("Encrypting AES")
            let cipher = AESDataCipher()
            progress.addChild(cipher.initProgress(), withPendingUnitCount: ProgressSteps.encryption)
            return try cipher.encrypt(
                plainText: data,
                key: masterKey,
                iv: header.initialVector) // throws CryptoError, ProgressInterruption
        case .twofish:
            Diag.debug("Encrypting Twofish")
            let cipher = TwofishDataCipher()
            progress.addChild(cipher.initProgress(), withPendingUnitCount: ProgressSteps.encryption)
            return try cipher.encrypt(
                plainText: data,
                key: masterKey,
                iv: header.initialVector) // throws CryptoError, ProgressInterruption
        }
    }
}
