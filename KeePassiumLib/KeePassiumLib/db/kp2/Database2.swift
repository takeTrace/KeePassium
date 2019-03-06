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
//import Gzip
//import AEXML

public class Database2: Database {
    
    /// Format version for KP2 (kdbx) files
    public enum FormatVersion {
        case v3
        case v4
    }
    
    /// An issue with database format: chechsum mismatch, etc
    public enum FormatError: LocalizedError {
        /// File is too short
        case prematureDataEnd
        /// block size is negative -> file corrupted
        case negativeBlockSize(blockIndex: Int)
        /// Problem with internal(decrypted) data structure
        case parsingError(reason: String)
        /// A binary attachment that is never referenced or is missing.
        case attachmentError(reason: String)
        /// Problem while reading hashed blocks stream
        case blockIDMismatch
        case blockHashMismatch(blockIndex: Int) // for v3
        case blockHMACMismatch(blockIndex: Int) // for v4
        /// Gzip/unzip error
        case compressionError(reason: String)
        public var errorDescription: String? {
            switch self {
            case .prematureDataEnd:
                return NSLocalizedString("Unexpected end of file. Corrupted file?", comment: "Error message")
            case .negativeBlockSize(let blockIndex):
                return NSLocalizedString("Corrupted database file (negative block #\(blockIndex) size)", comment: "Error message")
            case .parsingError(let reason):
                return NSLocalizedString("Cannot parse database. \(reason)", comment: "An error message. Parsing refers to the analysis/understanding of file content (do not confuse with reading it).")
            case .attachmentError(let reason):
                return NSLocalizedString("Cannot process one of the attachments. \(reason)", comment: "Error message: problem with a file attached to an entry.")
            case .blockIDMismatch:
                return NSLocalizedString("Unexpected block ID.", comment: "Error message: wrong ID of a data block")
            case .blockHashMismatch(let blockIndex):
                return NSLocalizedString("Block #\(blockIndex) hash mismatch.", comment: "Error message: hash(checksum) of a data block is wrong")
            case .blockHMACMismatch(let blockIndex):
                return NSLocalizedString("Block #\(blockIndex) HMAC mismatch.", comment: "Error message: HMAC value (kind of checksum) of a data block is wrong")
            case .compressionError(let reason):
                return NSLocalizedString("Gzip error: \(reason)", comment: "Generic error message about Gzip compression algorithm")
            }
        }
    }
    
    private enum ProgressSteps {
        // common
        static let all: Int64 = 100
        static let keyDerivation: Int64 = 60

        // loading
        static let decryption: Int64 = 20
        static let readingBlocks: Int64 = 5
        static let gzipUnpack: Int64 = 5
        static let parsing: Int64 = 10
        
        // writing
        static let packing: Int64 = 10
        static let gzipPack: Int64 = 5
        static let encryption: Int64 = 20
        static let writingBlocks: Int64 = 5
    }
    
    private(set) var header: Header2!
    private(set) var meta: Meta2!
    public var binaries: [Binary2.ID: Binary2] = [:]
    public var customIcons: [UUID: CustomIcon2] { return meta.customIcons }
    private var cipherKey = SecureByteArray()
    private var hmacKey = ByteArray()
    private var deletedObjects: ContiguousArray<DeletedObject2> = []
    
    override public var keyHelper: KeyHelper { return _keyHelper }
    private let _keyHelper = KeyHelper2()
    
    override public init() {
        super.init()
        header = Header2(database: self)
        meta = Meta2(database: self)
    }
    
    deinit {
        erase()
    }
    
    override public func erase() {
        header.erase()
        meta.erase()
        binaries.removeAll()
        cipherKey.erase()
        hmacKey.erase()
        deletedObjects.removeAll()
        super.erase()
    }
    
    /// Checks if given data starts with compatible KP2 signature.
    override public class func isSignatureMatches(data: ByteArray) -> Bool {
        return Header2.isSignatureMatches(data: data)
    }
    
    internal func addDeletedObject(uuid: UUID) {
        let deletedObject = DeletedObject2(database: self, uuid: uuid)
        deletedObjects.append(deletedObject)
    }
    
    /// Decrypts DB data using the given compositeKey.
    /// - Throws: DatabaseError.loadError, DatabaseError.invalidKey, ProgressInterruption
    override public func load(dbFileData: ByteArray, compositeKey: SecureByteArray) throws {
        Diag.info("Loading KP2 database")
        progress.completedUnitCount = 0
        progress.totalUnitCount = ProgressSteps.all
        progress.localizedAdditionalDescription = NSLocalizedString("Loading database", comment: "Progress bar status")
        do {
            // read header
            try header.read(data: dbFileData) // throws HeaderError
            Diag.debug("Header read OK [format: \(header.formatVersion)]")
            Diag.verbose("== DB2 progress CP1: \(progress.completedUnitCount)")
            
            // calculate cypher key
            try deriveMasterKey(compositeKey: compositeKey, cipher: header.dataCipher)
                // throws CryptoError, ProgressInterruption
            Diag.debug("Key derivation OK")
            Diag.verbose("== DB2 progress CP2: \(progress.completedUnitCount)")
            
            // read & decrypt (v4) / decrypt & read (v3) data blocks
            var decryptedData: ByteArray
            let dbWithoutHeader: ByteArray = dbFileData.suffix(from: header.size)

            switch header.formatVersion {
            case .v3:
                decryptedData = try decryptBlocksV3(
                    data: dbWithoutHeader,
                    cipher: header.dataCipher)
                    // throws DatabaseError.invalidKey, FormatError, CryptoError, ProgressInterruption
            case .v4:
                decryptedData = try decryptBlocksV4(
                    data: dbWithoutHeader,
                    cipher: header.dataCipher)
                    // throws DatabaseError.invalidKey, HeaderError, FormatError,
                    //      CryptoError, ProgressInterruption
            }
            Diag.debug("Block decryption OK")
            Diag.verbose("== DB2 progress CP3: \(progress.completedUnitCount)")
            
            if header.isCompressed {
                // inflate compressed GZip data to XML
                Diag.debug("Inflating Gzip data")
                decryptedData = try decryptedData.gunzipped() // throws GzipError
            } else {
                Diag.debug("Data not compressed")
            }
            progress.completedUnitCount += ProgressSteps.gzipUnpack
            Diag.verbose("== DB2 progress CP4: \(progress.completedUnitCount)")
            
            var xmlData: ByteArray
            switch header.formatVersion {
            case .v3:
                xmlData = decryptedData
            case .v4:
                let innerHeaderSize = try header.readInner(data: decryptedData) // throws HeaderError
                xmlData = decryptedData.suffix(from: innerHeaderSize)
                Diag.debug("Inner header read OK")
            }
            
            // parse XML
            try load(xmlData: xmlData) // throws FormatError.parsingError, ProgressInterruption
            
            propagateDeletedStatus()
            
            // ensure there are no missing or redundant (unreferenced) binaries
            try checkAttachmentsIntegrity() // throws FormatError.attachmentError
            
            Diag.debug("Content loaded OK")
            Diag.verbose("== DB2 progress CP5: \(progress.completedUnitCount)")
        } catch let error as Header2.HeaderError {
            Diag.error("Header error [reason: \(error.localizedDescription)]")
            throw DatabaseError.loadError(reason: error.localizedDescription)
        } catch let error as CryptoError {
            Diag.error("Crypto error [reason: \(error.localizedDescription)]")
            throw DatabaseError.loadError(reason: error.localizedDescription)
        } catch let error as FormatError {
            Diag.error("Format error [reason: \(error.localizedDescription)]")
            throw DatabaseError.loadError(reason: error.localizedDescription)
        } catch let error as GzipError {
            Diag.error("Gzip error [kind: \(error.kind), message: \(error.message)]")
            throw DatabaseError.loadError(reason: NSLocalizedString("Error unpacking database (\(error.message))", comment: "Error message. Unpacking is decompression of compressed data."))
        }
        // ProgressInterruption is passed up the call stack.
        // Catch-all for any missed cases is also there.
        
        // all good, so remember combinedKey for eventual saving
        self.compositeKey = compositeKey
    }
    
    /// Interprets given string as a date, depending on format version:
    /// .v3 - string is an ISO8601 representation
    /// .v4 - string is a base64-encoded number of seconds since 0001-01-01 00:00:00.000
    func xmlStringToDate(_ string: String?) -> Date? {
        switch header.formatVersion {
        case .v3:
            return Date(iso8601string: string)
        case .v4:
            return Date(base64Encoded: string)
        }
    }
    
    /// Returns string representation of the given date, depending on DB format version:
    /// .v3 - an ISO8601-formatted string
    /// .v4 - a base64-encoded number of seconds since 0001-01-01 00:00:00.000
    func xmlDateToString(_ date: Date) -> String {
        switch header.formatVersion {
        case .v3:
            return date.iso8601String()
        case .v4:
            return date.base64EncodedString()
        }
    }
    
    /// Reads and decrypts KP2 v4 hashed blocks, verifying their integrity.
    /// - Parameter: data - DB file content without the header
    /// - Parameter: cipher - cipher to use for decryption
    /// - Returns: plain text data
    /// - Throws: CryptoError, DatabaseError.invalidKey, FormatError, HeaderError, ProgressInterruption
    func decryptBlocksV4(data: ByteArray, cipher: DataCipher) throws -> ByteArray {
        Diag.debug("Decrypting V4 blocks")
        let inStream = data.asInputStream()
        inStream.open()
        defer { inStream.close() }
        
        guard let storedHash = inStream.read(count: SHA256_SIZE) else {
            throw FormatError.prematureDataEnd
        }
        guard header.hash == storedHash else {
            // header hash is independent from master key,
            // so a mismatch means only data corruption.
            Diag.error("Header hash mismatch. Database corrupted?")
            throw Header2.HeaderError.hashMismatch
        }
        
        let headerHMAC = header.getHMAC(key: self.hmacKey)
        guard let storedHMAC = inStream.read(count: SHA256_SIZE) else {
            throw FormatError.prematureDataEnd
        }
        guard headerHMAC == storedHMAC else {
            // header HMAC depends on master key, so a mismatch
            // means either data corruption (unlikely, since the hash already matched)
            // or invalid master key.
            Diag.error("Header HMAC mismatch. Invalid master key?")
            throw DatabaseError.invalidKey
        }
        
        // read HMAC blocks
        Diag.verbose("Reading blocks")
        let blockBytesCount = data.count - storedHash.count - storedHMAC.count
        let allBlocksData = ByteArray(capacity: blockBytesCount)
        let readingProgress = ProgressEx()
        readingProgress.totalUnitCount = Int64(blockBytesCount)
        readingProgress.localizedAdditionalDescription = NSLocalizedString("Reading database content", comment: "Status message")
        progress.addChild(readingProgress, withPendingUnitCount: ProgressSteps.readingBlocks)
        var blockIndex: UInt64 = 0
        while true {
            guard let storedBlockHMAC = inStream.read(count: SHA256_SIZE) else {
                throw FormatError.prematureDataEnd
            }
            guard let blockSize = inStream.readInt32() else {
                throw FormatError.prematureDataEnd
            }
            guard blockSize >= 0 else {
                throw FormatError.negativeBlockSize(blockIndex: Int(blockIndex))
            }
            
            guard let blockData = inStream.read(count: Int(blockSize)) else {
                throw FormatError.prematureDataEnd
            }
            let blockKey = CryptoManager.getHMACKey64(key: hmacKey, blockIndex: blockIndex)
            let dataForHMAC = ByteArray.concat(blockIndex.data, blockSize.data, blockData)
            let blockHMAC = CryptoManager.hmacSHA256(data: dataForHMAC, key: blockKey)
            guard blockHMAC == storedBlockHMAC else {
                Diag.error("Block HMAC mismatch")
                throw FormatError.blockHMACMismatch(blockIndex: Int(blockIndex))
            }

            let bytesReadNow = storedBlockHMAC.count + blockSize.byteWidth + blockData.count
            readingProgress.completedUnitCount += Int64(bytesReadNow)
            
            // zero block size might be due to data corruption,
            // so this check occurs only after HMAC verification.
            if blockSize == 0 { break }

            allBlocksData.append(blockData)
            blockIndex += 1
        }
        
        // decrypt
        Diag.verbose("Will decrypt \(allBlocksData.count) bytes")
        progress.addChild(cipher.initProgress(), withPendingUnitCount: ProgressSteps.decryption)
        let decryptedData = try cipher.decrypt(
            cipherText: allBlocksData,
            key: cipherKey,
            iv: header.initialVector) // throws CryptoError, ProgressInterruption
        Diag.verbose("Decrypted \(decryptedData.count) bytes")

        return decryptedData
    }
    
    /// Decrypts and reads KP2 v3 hashed blocks, verifying their integrity.
    /// - Parameter: data - DB file content without the header
    /// - Parameter: cipher - cipher to use for decryption
    /// - Returns: plain text data
    /// - Throws: `CryptoError`, `DatabaseError.invalidKey`, `FormatError`, `ProgressInterruption`
    func decryptBlocksV3(data: ByteArray, cipher: DataCipher) throws -> ByteArray {
        Diag.debug("Decrypting V3 blocks")
        progress.addChild(cipher.initProgress(), withPendingUnitCount: ProgressSteps.decryption)
        var decryptedData = try cipher.decrypt(
            cipherText: data,
            key: cipherKey,
            iv: header.initialVector) // throws CryptoError, ProgressInterruption
        Diag.verbose("Decrypted \(decryptedData.count) bytes")
        
        let decryptedStream = decryptedData.asInputStream()
        decryptedStream.open()
        defer { decryptedStream.close() }
        
        // verify first bytes
        guard let startData = decryptedStream.read(count: SHA256_SIZE) else {
            throw FormatError.prematureDataEnd
        }
        guard startData == header.fields[.streamStartBytes] else {
            Diag.error("First bytes do not match. Invalid master key?")
            throw DatabaseError.invalidKey
        }
        
        // read data blocks
        let blocksData = ByteArray(capacity: decryptedData.count - startData.count)
        var blockID: UInt32 = 0
        let readingProgress = ProgressEx()
        readingProgress.totalUnitCount = Int64(decryptedData.count - startData.count)
        readingProgress.localizedAdditionalDescription = NSLocalizedString("Reading database content", comment: "Status message")
        progress.addChild(readingProgress, withPendingUnitCount: ProgressSteps.readingBlocks)
        while(true) {
            guard let inBlockID: UInt32 = decryptedStream.readUInt32() else {
                throw FormatError.prematureDataEnd
            }
            guard inBlockID == blockID else {
                Diag.error("Block ID mismatch")
                throw FormatError.blockIDMismatch
            }
            blockID += 1
            
            guard let storedBlockHash = decryptedStream.read(count: SHA256_SIZE) else {
                throw FormatError.prematureDataEnd
            }
            guard let blockSize: UInt32 = decryptedStream.readUInt32() else {
                throw FormatError.prematureDataEnd
            }
            if blockSize == 0 {
                if storedBlockHash.containsOnly(0) {
                    break
                } else {
                    Diag.error("Empty block with non-zero hash. Database corrupted?")
                    throw FormatError.blockHashMismatch(blockIndex: Int(blockID))
                }
            }
            guard let blockData = decryptedStream.read(count: Int(blockSize)) else {
                throw FormatError.prematureDataEnd
            }
            let computedBlockHash = blockData.sha256
            guard computedBlockHash == storedBlockHash else {
                Diag.error("Block hash mismatch")
                throw FormatError.blockHashMismatch(blockIndex: Int(blockID))
            }
            blocksData.append(blockData)
            readingProgress.completedUnitCount +=
                Int64(sizeof(blockID) + SHA256_SIZE + sizeof(blockSize) + Int(blockSize))
            blockData.erase()
        }
        readingProgress.completedUnitCount = readingProgress.totalUnitCount
        return blocksData
    }

    /// Parses kp2 database XML content.
    /// - Throws: FormatError.parsingError, ProgressInterruption
    func load(xmlData: ByteArray) throws {
        var parsingOptions = AEXMLOptions()
        parsingOptions.documentHeader.standalone = "yes"
        parsingOptions.parserSettings.shouldTrimWhitespace = false
        do {
            Diag.debug("Parsing XML")
            let xmlDoc = try AEXMLDocument(xml: xmlData.asData, options: parsingOptions)
            if let xmlError = xmlDoc.error {
                Diag.error("Cannot parse XML: \(xmlError.localizedDescription)")
                throw Xml2.ParsingError.xmlError(details: xmlError.localizedDescription)
            }
            guard xmlDoc.root.name == Xml2.keePassFile else {
                Diag.error("Not a KeePass XML document [xmlRoot: \(xmlDoc.root.name)]")
                throw Xml2.ParsingError.notKeePassDocument
            }
            
            let rootGroup = Group2(database: self)
            rootGroup.parent = nil
            
            for tag in xmlDoc.root.children {
                switch tag.name {
                case Xml2.meta:
                    try meta.load(xml: tag, streamCipher: header.streamCipher)
                        // throws Xml2.ParsingError, ProgressInterruption
                    
                    // In v3, meta contains a ground-truth copy of header hash, make sure they match.
                    if meta.headerHash != nil && (header.hash != meta.headerHash!) {
                        Diag.error("KP2v3 meta meta hash mismatch")
                        throw Header2.HeaderError.hashMismatch
                    }
                    Diag.verbose("Meta loaded OK")
                case Xml2.root:
                    try loadRoot(xml: tag, root: rootGroup)
                        // throws Xml2.ParsingError, ProgressInterruption
                    Diag.verbose("XML root loaded OK")
                default:
                    throw Xml2.ParsingError.unexpectedTag(actual: tag.name, expected: "KeePassFile/*")
                }
            }
            
            // AEXML parsing does not report progress, so make it one-step for now
            progress.completedUnitCount += ProgressSteps.parsing
            
            self.root = rootGroup
            Diag.debug("XML content loaded OK")
        } catch let error as Header2.HeaderError {
            Diag.error("Header error [reason: \(error.localizedDescription)]")
            throw FormatError.parsingError(reason: error.localizedDescription)
        } catch let error as Xml2.ParsingError {
            Diag.error("XML parsing error [reason: \(error.localizedDescription)]")
            throw FormatError.parsingError(reason: error.localizedDescription)
        } catch let error as AEXMLError {
            Diag.error("Raw XML parsing error [reason: \(error.localizedDescription)]")
            throw FormatError.parsingError(reason: error.localizedDescription)
        }
    }
    
    /// - Throws: `Xml2.ParsingError`, `ProgressInterruption`
    internal func loadRoot(xml: AEXMLElement, root: Group2) throws {
        assert(xml.name == Xml2.root)
        Diag.debug("Loading XML root")
        for tag in xml.children {
            switch tag.name {
            case Xml2.group:
                try root.load(xml: tag, streamCipher: header.streamCipher) // throws ProgressInterruption
            case Xml2.deletedObjects:
                try loadDeletedObjects(xml: tag)
            default:
                throw Xml2.ParsingError.unexpectedTag(actual: tag.name, expected: "Root/*")
            }
        }
    }
    
    /// - Throws: Xml2.ParsingError
    private func loadDeletedObjects(xml: AEXMLElement) throws {
        assert(xml.name == Xml2.deletedObjects)
        for tag in xml.children {
            switch tag.name {
            case Xml2.deletedObject:
                let deletedObject = DeletedObject2(database: self)
                try deletedObject.load(xml: tag)
                deletedObjects.append(deletedObject)
            default:
                throw Xml2.ParsingError.unexpectedTag(actual: tag.name, expected: "DeletedObjects/*")
            }
        }
    }
    
    /// Sets `isDeleted` property on all siblings of Backup group, if any.
    private func propagateDeletedStatus() {
        if let backupGroup = getBackupGroup(createIfMissing: false) {
            var deletedGroups = [Group2]() as [Group]
            var deletedEntries = [Entry2]() as [Entry]
            backupGroup.collectAllChildren(groups: &deletedGroups, entries: &deletedEntries)
            deletedGroups.forEach { $0.isDeleted = true }
            deletedEntries.forEach { $0.isDeleted = true }
        }
    }
    
    /// Checks if any entries refer to non-existent binaries,
    /// or any binaries not referenced from entries.
    ///
    /// - Throws: `FormatError.attachmentError`
    func checkAttachmentsIntegrity() throws {
        let knownIDs = Set(binaries.keys) // BinaryID of items in binary pool
        
        var usedIDs = Set<Binary2.ID>() // BinaryID referenced by entries
        var allGroups = [Group]()
        var allEntries = [Entry]()
        root?.collectAllChildren(groups: &allGroups, entries: &allEntries)
        allEntries.forEach { (entry) in
            let entry2 = entry as! Entry2
            usedIDs.formUnion(entry2.getAllAttachmentIDs(includeHistory: true))
        }
        
        if knownIDs == usedIDs {
            Diag.debug("Attachments integrity OK")
            return
        }
        
        if usedIDs.isStrictSubset(of: knownIDs) {
            // some binaries are not referenced
            Diag.warning("Some binary attachments are not referenced from any entry")
            throw FormatError.attachmentError(reason:
                NSLocalizedString(
                    "Some attachments are not referenced from any entry",
                    comment: "Error message: there is an orphaned file in database's binary pool"))
        }
        if knownIDs.isStrictSubset(of: usedIDs) {
            // there are references to non-existent binaries
            Diag.warning("Some entries refer to non-existent attachments")
            throw FormatError.attachmentError(reason:
                NSLocalizedString(
                    "Some entries refer to non-existent attachments",
                    comment: "Error message: entry's attachment does not exist in database's binary pool"))
        }
    }
    
    /// Updates `cipherKey` field by transforming the given `compositeKey`.
    /// - Throws: CryptoError, ProgressInterruption
    func deriveMasterKey(compositeKey: SecureByteArray, cipher: DataCipher) throws {
        Diag.debug("Start key derivation")
        progress.addChild(header.kdf.initProgress(), withPendingUnitCount: ProgressSteps.keyDerivation)
        let transformedKey = try header.kdf.transform(key: compositeKey, params: header.kdfParams)
            // throws CryptoError, ProgressInterruption
        let joinedKey = ByteArray.concat(header.masterSeed, transformedKey)
        self.cipherKey = cipher.resizeKey(key: joinedKey)
        let one = ByteArray(bytes: [1])
        self.hmacKey = ByteArray.concat(joinedKey, one).sha512
    }
    
    /// Changes DB's composite key to the provided one.
    /// Don't forget to call `deriveMasterKey` before saving.
    ///
    /// - Parameter newKey: new composite key.
    override public func changeCompositeKey(to newKey: SecureByteArray) {
        compositeKey = newKey
    }
    
    override public func getBackupGroup(createIfMissing: Bool) -> Group? {
        assert(root != nil)
        if !meta.isRecycleBinEnabled {
            Diag.verbose("RecycleBin disabled in Meta")
            return nil
        }

        if meta.recycleBinGroupUUID != UUID.ZERO {
            if let backupGroup = root!.findGroup(byUUID: meta.recycleBinGroupUUID) {
                Diag.verbose("RecycleBin group found")
                return backupGroup
            }
        }
        if createIfMissing {
            // no such group - create one
            let backupGroup = meta.createRecycleBinGroup()
            root!.add(group: backupGroup)
            Diag.verbose("RecycleBin group created")
            return backupGroup
        }
        Diag.verbose("RecycleBin group not found nor created.")
        return nil
    }
    
    
    /// Rebuilds the binary pool from attachments of individual entries (including their histories).
    private func updateBinaries(root: Group2) {
        Diag.verbose("Updating all binaries")
        var allGroups = [Group2]() as [Group]
        var allEntries = [Entry2]() as [Entry]
        root.collectAllChildren(groups: &allGroups, entries: &allEntries)

        // Make a content-keyed lookup dict for faster search
        var oldBinaryPoolInverse = [ByteArray : Binary2]()
        binaries.values.forEach { oldBinaryPoolInverse[$0.data] = $0 }
        
        var newBinaryPoolInverse = [ByteArray: Binary2]()
        for entry in allEntries {
            updateBinaries(
                entry: entry as! Entry2,
                oldPoolInverse: oldBinaryPoolInverse,
                newPoolInverse: &newBinaryPoolInverse)
        }
        // Rebuild the normal [ID: Binary2] dict
        binaries.removeAll()
        newBinaryPoolInverse.values.forEach { binaries[$0.id] = $0 }
    }

    /// Adds entry's attachments to the binary pool and updates attachment refs accordingly.
    /// Also looks into entry's history.
    private func updateBinaries(
        entry: Entry2,
        oldPoolInverse: [ByteArray: Binary2],
        newPoolInverse: inout [ByteArray: Binary2])
    {
        // Process previous versions of the entry, if any
        for histEntry in entry.history {
            updateBinaries(
                entry: histEntry,
                oldPoolInverse: oldPoolInverse,
                newPoolInverse: &newPoolInverse
            )
        }
        
        // Process the entry itself
        for att in entry.attachments {
            let att2 = att as! Attachment2
            if let binaryInNewPool = newPoolInverse[att.data] {
                // the attachment is already in new binary pool, just update the ID
                att2.id = binaryInNewPool.id
                continue
            }
            
            let newID = newPoolInverse.count
            let newBinary: Binary2
            if let binaryInOldPool = oldPoolInverse[att.data] {
                // this is an old attachment, to be inserted under a new ID
                newBinary = Binary2(
                    id: newID,
                    data: binaryInOldPool.data,
                    isCompressed: binaryInOldPool.isCompressed,
                    isProtected: binaryInOldPool.isProtected
                )
            } else {
                // newly added attachment, was not in any pools
                newBinary = Binary2(
                    id: newID,
                    data: att.data,
                    isCompressed: att.isCompressed,
                    isProtected: true
                )
            }
            newPoolInverse[newBinary.data] = newBinary
            att2.id = newID
        }
    }
    
    /// Encrypts the DB and returns the resulting Data.
    ///
    /// - Throws: `DatabaseError.saveError`, `ProgressInterruption`
    /// - Returns: encrypted DB Data
    override public func save() throws -> ByteArray {
        Diag.info("Saving KP2 database")
        assert(root != nil, "Load or create a DB before saving.")
        
        progress.totalUnitCount = ProgressSteps.all
        progress.completedUnitCount = 0
        header.maybeUpdateFormatVersion()
        let formatVersion = header.formatVersion
        Diag.debug("Format version: \(formatVersion)")
        do {
            try header.randomizeSeeds() // throws CryptoError.rngError
            Diag.debug("Seeds randomized OK")
            try deriveMasterKey(compositeKey: compositeKey, cipher: header.dataCipher)
                // throws CryptoError, ProgressInterruption
            Diag.debug("Key derivation OK")
        } catch let error as CryptoError {
            Diag.error("Crypto error [reason: \(error.localizedDescription)]")
            throw DatabaseError.saveError(reason: error.localizedDescription)
        }

        // Prepare DB content
        
        // rebuild binary pool from attachments, in case anything was added/removed
        updateBinaries(root: root! as! Group2)
        Diag.verbose("Binaries updated OK")
        
        let outStream = ByteArray.makeOutputStream()
        outStream.open()
        defer { outStream.close() }
        progress.completedUnitCount += ProgressSteps.packing
        
        header.write(to: outStream) // also implicitly updates header's hash

        // prepare XML content
        meta.headerHash = header.hash
        // (NB: Preserve formatting, use .xml! xmlCompact corrupts multi-line Notes)
        let xmlString = try self.toXml().xml // throws ProgressInterruption
        let xmlData = ByteArray(utf8String: xmlString)
        Diag.debug("XML generation OK")

        switch formatVersion {
        case .v3:
            try encryptBlocksV3(to: outStream, xmlData: xmlData) // throws ProgressInterruption
        case .v4:
            try encryptBlocksV4(to: outStream, xmlData: xmlData) // throws ProgressInterruption
        }
        Diag.debug("Content encryption OK")
        
        progress.completedUnitCount = progress.totalUnitCount
        return outStream.data!
    }
    
    /// (KP2v4) Prepares the main DB content (sans header) and writes it to the `to` stream.
    /// - Throws: `DatabaseError.saveError`, `ProgressInterruption`
    internal func encryptBlocksV4(to outStream: ByteArray.OutputStream, xmlData: ByteArray) throws {
        Diag.debug("Encrypting KP2v4 blocks")
        // First, write header hash & HMAC
        outStream.write(data: header.hash)
        outStream.write(data: header.getHMAC(key: hmacKey))

        // Then, prepare main content, compress it, encrypt it,
        // and finally split to blocks and output them.
        
        // prepend XML data with inner header
        let contentStream = ByteArray.makeOutputStream()
        contentStream.open()
        defer { contentStream.close() }
        
        try header.writeInner(to: contentStream) // throws ProgressInterruption
        Diag.verbose("Header written OK")
        contentStream.write(data: xmlData)
        let contentData = contentStream.data!

        do {
            // compress
            var dataToEncrypt = contentData
            if header.isCompressed {
                dataToEncrypt = try contentData.gzipped()
                Diag.verbose("Gzip compression OK")
            } else {
                Diag.verbose("No compression required")
            }
            progress.completedUnitCount += ProgressSteps.gzipPack
            
            // encrypt
            Diag.verbose("Encrypting \(dataToEncrypt.count) bytes")
            progress.addChild(
                header.dataCipher.initProgress(),
                withPendingUnitCount: ProgressSteps.encryption)
            let encData = try header.dataCipher.encrypt(
                plainText: dataToEncrypt,
                key: cipherKey,
                iv: header.initialVector) // throws CryptoError, ProgressInterruption
            Diag.verbose("Encrypted \(encData.count) bytes")
            
            // split to blocks and write them
            try writeAsBlocksV4(to: outStream, data: encData) // throws ProgressInterruption
            Diag.verbose("Blocks written OK")
        } catch let error as GzipError {
            Diag.error("Gzip error [kind: \(error.kind), message: \(error.message)]")
            let errMsg = NSLocalizedString("Data compression error: \(error.localizedDescription)", comment: "Error message")
            throw DatabaseError.saveError(reason: errMsg)
        } catch let error as CryptoError {
            Diag.error("Crypto error [reason: \(error.localizedDescription)]")
            let errMsg = NSLocalizedString("Encryption error: \(error.localizedDescription)", comment: "Error message")
            throw DatabaseError.saveError(reason: errMsg)
        }
    }
    
    /// (KP2v4) Writes `data` to `to` stream as blocks with HMAC
    /// - Throws: `ProgressInterruption`
    internal func writeAsBlocksV4(to blockStream: ByteArray.OutputStream, data: ByteArray) throws {
        Diag.debug("Writing KP2v4 blocks")
        let defaultBlockSize  = 1024 * 1024 // KP2 default block size
        var blockStart: Int = 0
        var blockIndex: UInt64 = 0
        
        let writeProgress = ProgressEx()
        writeProgress.totalUnitCount = Int64(data.count)
        writeProgress.localizedAdditionalDescription = NSLocalizedString("Writing encrypted blocks", comment: "Status message")
        progress.addChild(writeProgress, withPendingUnitCount: ProgressSteps.writingBlocks)
        
        Diag.verbose("\(data.count) bytes to write")
        while blockStart != data.count {
            // write sequence: hmac (32 bytes), blockSize: Int32, blockData
            // end of data => zero size blockData.
            let blockSize = min(defaultBlockSize, data.count - blockStart)
            let blockData = data[blockStart..<blockStart+blockSize]

            let blockKey = CryptoManager.getHMACKey64(key: hmacKey, blockIndex: blockIndex)
            let dataForHMAC = ByteArray.concat(blockIndex.data, Int32(blockSize).data, blockData)
            let blockHMAC = CryptoManager.hmacSHA256(data: dataForHMAC, key: blockKey)
            blockStream.write(data: blockHMAC)
            blockStream.write(value: Int32(blockSize))
            blockStream.write(data: blockData)
            blockStart += blockSize
            blockIndex += 1
            writeProgress.completedUnitCount += Int64(blockSize)
            if writeProgress.isCancelled {
                throw ProgressInterruption.cancelledByUser()
            }
        }
        // finally, write the terminating block
        let endBlockSize: Int32 = 0
        let endBlockKey = CryptoManager.getHMACKey64(key: hmacKey, blockIndex: blockIndex)
        let endBlockHMAC = CryptoManager.hmacSHA256(
            data: ByteArray.concat(blockIndex.data, endBlockSize.data),
            key: endBlockKey)
        blockStream.write(data: endBlockHMAC)
        blockStream.write(value: endBlockSize) // block size
        
        writeProgress.completedUnitCount = writeProgress.totalUnitCount
    }
    
    /// (KP2v3) Encrypts main DB content (sans header) and writes it to the `to` stream.
    /// - Throws: `DatabaseError.saveError`, `ProgressInterruption`
    internal func encryptBlocksV3(to outStream: ByteArray.OutputStream, xmlData: ByteArray) throws {
        Diag.debug("Encrypting KP2v3 blocks")
        let dataToSplit: ByteArray
        // compress the data if necessary
        if header.isCompressed {
            do {
                dataToSplit = try xmlData.gzipped()
                Diag.verbose("Gzip compression OK")
            } catch let error as GzipError {
                Diag.error("Gzip error [kind: \(error.kind), message: \(error.message)]")
                let errMsg = NSLocalizedString("Data compression error: \(error.localizedDescription)", comment: "Error message")
                throw DatabaseError.saveError(reason: errMsg)
            }
        } else {
            dataToSplit = xmlData
            Diag.verbose("No compression required")
        }
        progress.completedUnitCount += ProgressSteps.gzipPack
        
        // split data to hashed blocks
        let blockStream = ByteArray.makeOutputStream()
        blockStream.open()
        defer { blockStream.close() }
        blockStream.write(data: header.streamStartBytes!) // random stream start bytes go before any blocks
        try splitToBlocksV3(to: blockStream, data: dataToSplit) // throws ProgressInterruption
        let blocksData = blockStream.data!
        Diag.verbose("Blocks split OK")
        
        // encrypt everything
        do {
            progress.addChild(
                header.dataCipher.initProgress(),
                withPendingUnitCount: ProgressSteps.encryption)
            let encryptedData = try header.dataCipher.encrypt(
                plainText: blocksData,
                key: cipherKey,
                iv: header.initialVector) // throws CryptoError, ProgressInterruption
            outStream.write(data: encryptedData)
            Diag.verbose("Encryption OK")
        } catch let error as CryptoError {
            Diag.error("Crypto error [message: \(error.localizedDescription)]")
            let errMsg = NSLocalizedString("Encryption error: \(error.localizedDescription)", comment: "Error message")
            throw DatabaseError.saveError(reason: errMsg)
        }
    }
    
    /// (KP2v3) Writes `data` to `stream` as hashed blocks
    /// - Throws: `ProgressInterruption`
    internal func splitToBlocksV3(to stream: ByteArray.OutputStream, data inData: ByteArray) throws {
        Diag.verbose("Will split to KP2v3 blocks")
        let defaultBlockSize = 1024 * 1024 // KP2 default block size
        var blockStart: Int = 0
        var blockID: UInt32 = 0
        let writingProgress = ProgressEx()
        writingProgress.localizedAdditionalDescription = NSLocalizedString("Writing encrypted blocks", comment: "Status message")
        writingProgress.totalUnitCount = Int64(inData.count)
        progress.addChild(writingProgress, withPendingUnitCount: ProgressSteps.writingBlocks)
        while blockStart != inData.count {
            // write sequence: blockID, hash, size, block data.
            // end of data => zero size & all-zero hash.
            let blockSize = min(defaultBlockSize, inData.count - blockStart)
            let blockData = inData[blockStart..<blockStart+blockSize]
            
            stream.write(value: UInt32(blockID))
            stream.write(data: blockData.sha256)
            stream.write(value: UInt32(blockData.count))
            stream.write(data: blockData)
            blockStart += blockSize
            blockID += 1
            writingProgress.completedUnitCount += Int64(blockSize)
            if writingProgress.isCancelled {
                throw ProgressInterruption.cancelledByUser()
            }
        }
        // finally, write the terminating block
        stream.write(value: UInt32(blockID))
        stream.write(data: ByteArray(count: SHA256_SIZE))
        stream.write(value: UInt32(0))
        stream.write(data: ByteArray(count: 0))
        writingProgress.completedUnitCount = writingProgress.totalUnitCount
    }
    
    /// - Throws: `ProgressInterruption`
    func toXml() throws -> AEXMLDocument {
        Diag.debug("Will generate XML")
        // KP2 uses pretty-printed XML in DBs, so shall we.
        var options = AEXMLOptions()
        options.documentHeader.encoding = "utf-8"
        options.documentHeader.standalone = "yes"
        options.documentHeader.version = 1.0
        
        let xmlMain = AEXMLElement(name: Xml2.keePassFile)
        let xmlDoc = AEXMLDocument(root: xmlMain, options: options)
        xmlMain.addChild(try meta.toXml(streamCipher: header.streamCipher))
            // throws ProgressInterruption
        Diag.verbose("XML generation: Meta OK")
        
        let xmlRoot = xmlMain.addChild(name: Xml2.root)
        let root2 = root! as! Group2
        xmlRoot.addChild(try root2.toXml(streamCipher: header.streamCipher))
            // throws ProgressInterruption
        Diag.verbose("XML generation: Root group OK")
        
        let xmlDeletedObjects = xmlRoot.addChild(name: Xml2.deletedObjects)
        for deletedObject in deletedObjects {
            xmlDeletedObjects.addChild(deletedObject.toXml())
        }
        return xmlDoc
    }
    
    /// Sets all database timestamps (meta, groups, entries) to given time.
    /// Use for initialization of a newly created database.
    func setAllTimestamps(to time: Date) {
        meta.setAllTimestamps(to: time)
        
        guard let root = root else { return }
        var groups: [Group] = [root]
        var entries: [Entry] = []
        root.collectAllChildren(groups: &groups, entries: &entries)
        for group in groups {
            group.creationTime = time
            // group.expiryTime = time // nope, expiration remains original
            group.lastAccessTime = time
            group.lastModificationTime = time
        }
        for entry in entries {
            entry.creationTime = time
            // entry.expiryTime = time // nope, expiration remains original
            entry.lastModificationTime = time
            entry.lastAccessTime = time
        }
    }
    
    // MARK: - Group/entry management routines
    
    /// Deletes the given `group` with its whole branch.
    /// If possible, moves `group` to RecycleBin, otherwise removes permanently.
    ///
    /// - Parameters:
    ///   - group: the group to move
    /// - Returns: true iff successful.
    override public func delete(group: Group) {
        guard let group = group as? Group2 else { fatalError() }
        guard let parentGroup = group.parent else {
            Diag.warning("Cannot delete group: no parent group")
            return
        }
        
        var subGroups = [Group]()
        var subEntries = [Entry]()
        group.collectAllChildren(groups: &subGroups, entries: &subEntries)
        
        let moveOnly = !group.isDeleted && meta.isRecycleBinEnabled
        if moveOnly, let backupGroup = getBackupGroup(createIfMissing: meta.isRecycleBinEnabled) {
            Diag.debug("Moving group to RecycleBin")
            parentGroup.remove(group: group)
            backupGroup.add(group: group)
            group.accessed()
            group.locationChangedTime = Date.now
            
            // Flag the group and all its siblings deleted (siblings' timestamps remain unchanged).
            group.isDeleted = true
            subGroups.forEach { $0.isDeleted = true }
            subEntries.forEach { $0.isDeleted = true }
        } else {
            // Delete the group and all its children permanently,
            // but mention them in the DeletedObjects list to facilitate synchronization.
            Diag.debug("Removing the group permanently.")
            addDeletedObject(uuid: group.uuid)
            subGroups.forEach { addDeletedObject(uuid: $0.uuid) }
            subEntries.forEach { addDeletedObject(uuid: $0.uuid) }
            parentGroup.remove(group: group)
        }
        Diag.debug("Delete group OK")
    }
    
    /// Deletes given `entry` (or moves it to the Backup group, when possible).
    override public func delete(entry: Entry) {
        guard let parentGroup = entry.parent else {
            Diag.warning("Cannot delete entry: no parent group")
            return
        }
        
        if entry.isDeleted {
            // already in Backup, so delete permanently
            addDeletedObject(uuid: entry.uuid)
            parentGroup.remove(entry: entry)
            return
        }
        
        if meta.isRecycleBinEnabled,
            let backupGroup = getBackupGroup(createIfMissing: meta.isRecycleBinEnabled)
        {
            entry.accessed()
            backupGroup.moveEntry(entry: entry)
        } else {
            // Backup is disabled, so we delete the entry permanently
            // and mention it in DeletedObjects to facilitate synchronization.
            Diag.debug("Backup disabled, removing permanently.")
            addDeletedObject(uuid: entry.uuid)
            parentGroup.remove(entry: entry)
        }
        Diag.debug("Delete entry OK")
    }
    
    /// Creates an attachment suitable for this database's entries.
    ///
    /// - Parameters:
    ///   - name: attachment name (name of the original file)
    ///   - data: uncompressed content
    /// - Returns: version-appropriate instance of `Attachment`, possibly with compressed data.
    override public func makeAttachment(name: String, data: ByteArray) -> Attachment {
        let attemptCompression = header.isCompressed
        
        if attemptCompression {
            do {
                let compressedData = try data.gzipped()
                return Attachment2(name: name, isCompressed: true, data: compressedData)
            } catch {
                Diag.warning("Failed to compress attachment data [message: \(error.localizedDescription)]")
                //just log and fallback uncompressed attachment
            }
        }

        return Attachment2(name: name, isCompressed: false, data: data)
    }
}
