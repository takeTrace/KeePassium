//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit

/// General info about file URL: file name, timestamps, etc.
public struct FileInfo {
    public var fileName: String
    public var hasError: Bool { return errorMessage != nil}
    public var errorMessage: String?
    
    public var fileSize: Int64?
    public var creationDate: Date?
    public var modificationDate: Date?
}

/// Represents a URL as a URL bookmark. Useful for handling external (cloud-based) files.
public class URLReference: Equatable, Codable {

    /// Specifies possible storage locations of files.
    public enum Location: Int, Codable, CustomStringConvertible {
        public static let allValues: [Location] =
            [.internalDocuments, .internalBackup, .internalInbox, .external]
        
        public static let allInternal: [Location] =
            [.internalDocuments, .internalBackup, .internalInbox]
        
        /// Files stored in app sandbox/Documents dir.
        case internalDocuments = 0
        /// Files stored in app sandbox/Documents/Backup dir.
        case internalBackup = 1
        /// Files temporarily imported via Documents/Inbox dir.
        case internalInbox = 2
        /// Files stored outside the app sandbox (e.g. in cloud)
        case external = 100
        
        /// True if the location is in app sandbox
        public var isInternal: Bool {
            return self != .external
        }
        
        /// Human-readable description of the location
        public var description: String {
            switch self {
            case .internalDocuments:
                return NSLocalizedString(
                    "[URLReference/Location] Local copy",
                    value: "Local copy",
                    comment: "Human-readable file location: the file is on device, inside the app sandbox. Example: 'File Location: Local copy'")
            case .internalInbox:
                return NSLocalizedString(
                    "[URLReference/Location] Internal inbox",
                    value: "Internal inbox",
                    comment: "Human-readable file location: the file is on device, inside the app sandbox. 'Inbox' is a special directory for files that are being imported. Can be also 'Internal import'. Example: 'File Location: Internal inbox'")
            case .internalBackup:
                return NSLocalizedString(
                    "[URLReference/Location] Internal backup",
                    value: "Internal backup",
                    comment: "Human-readable file location: the file is on device, inside the app sandbox. 'Backup' is a dedicated directory for database backup files. Example: 'File Location: Internal backup'")
            case .external:
                return NSLocalizedString(
                    "[URLReference/Location] Cloud storage / Another app",
                    value: "Cloud storage / Another app",
                    comment: "Human-readable file location. The file is situated either online / in cloud storage, or on the same device, but in some other app. Example: 'File Location: Cloud storage / Another app'")
            }
        }
    }
    
    /// Bookmark data
    private let data: Data
    /// sha256 hash of `data`
    lazy private(set) var hash: ByteArray = CryptoManager.sha256(of: ByteArray(data: data))
    /// Location type of the original URL
    public let location: Location
    
    private enum CodingKeys: String, CodingKey {
        case data = "data"
        case location = "location"
    }
    
    public init(from url: URL, location: Location) throws {
        let resourceKeys = Set<URLResourceKey>(
            [.canonicalPathKey, .nameKey, .fileSizeKey,
            .creationDateKey, .contentModificationDateKey]
        )
        data = try url.bookmarkData(
            options: [], //.minimalBookmark,
            includingResourceValuesForKeys: resourceKeys,
            relativeTo: nil) // throws an internal system error
        self.location = location
    }

    public static func == (lhs: URLReference, rhs: URLReference) -> Bool {
        guard lhs.location == rhs.location else { return false }
        if lhs.location.isInternal {
            // For internal files, URL references are generated dynamically
            // and same URL can have different refs. So we compare by URL.
            guard let leftURL = try? lhs.resolve(),
                let rightURL = try? rhs.resolve() else { return false }
            return leftURL == rightURL
        } else {
            // For external files, URL references are stored, so same refs
            // will have same hash.
            return lhs.hash == rhs.hash
        }
    }
    
    public func serialize() -> Data {
        return try! JSONEncoder().encode(self)
    }
    public static func deserialize(from data: Data) -> URLReference? {
        return try? JSONDecoder().decode(URLReference.self, from: data)
    }
    
    public func resolve() throws -> URL {
        var isStale = false
        let url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
        return url
    }
    
    /// Cached information about resolved URL.
    /// Cached after first call; use `getInfo()` to update.
    /// In case of trouble, only `hasError` and `errorMessage` fields are valid.
    public lazy var info: FileInfo = getInfo()
    
    /// Returns information about resolved URL (also updates the `info` property).
    /// Might be slow, as it needs to resolve the URL.
    /// In case of trouble, only `hasError` and `errorMessage` fields are valid.
    public func getInfo() -> FileInfo {
        refreshInfo()
        return info
    }
    
    /// Re-aquires information about resolved URL and updates the `info` field.
    public func refreshInfo() {
        let result: FileInfo
        do {
            let url = try resolve()
            // without secruity scoping, won't get file attributes
            let isAccessed = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            result = FileInfo(
                fileName: url.lastPathComponent,
                errorMessage: nil,
                fileSize: url.fileSize,
                creationDate: url.fileCreationDate,
                modificationDate: url.fileModificationDate)
        } catch {
            result = FileInfo(
                fileName: "?",
                errorMessage: error.localizedDescription,
                fileSize: nil,
                creationDate: nil,
                modificationDate: nil)
        }
        self.info = result
    }
    
    /// Finds the same reference in the given list.
    /// If no exact match found, and `fallbackToNamesake` is `true`,
    /// looks also for references with the same file name.
    ///
    /// - Parameters:
    ///   - refs: list of references to search in
    ///   - fallbackToNamesake: if `true`, repeat search with relaxed conditions
    ///       (same file name instead of exact match).
    /// - Returns: suitable reference from `refs`, if any.
    public func find(in refs: [URLReference], fallbackToNamesake: Bool=false) -> URLReference? {
        if let exactMatchIndex = refs.firstIndex(of: self) {
            return refs[exactMatchIndex]
        }
        if fallbackToNamesake {
            let fileName = self.info.fileName
            return refs.first(where: { $0.info.fileName == fileName })
        }
        return nil
    }
}
