//
//  FileType.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-08-28.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

public enum FileType {
    public static let databaseUTIs = [
        "com.keepassium.kdb", "com.keepassium.kdbx",
        "com.jflan.MiniKeePass.kdb", "com.jflan.MiniKeePass.kdbx",
        "com.kptouch.kdb", "com.kptouch.kdbx",
        "be.kyuran.kypass.kdb"]
    
    public static let keyFileUTIs =
        ["com.keepassium.keyfile", "public.data"]
    
    public static let databaseExtensions = ["kdb", "kdbx"]
    //public static let keyFileExtensions = anything except database
    
    case database
    case keyFile

    init(for url: URL) {
        if FileType.databaseExtensions.contains(url.pathExtension) {
            self = .database
        } else {
            self = .keyFile
        }
    }

    /// `true` if the `url` has a KeePass database extension
    public static func isDatabaseFile(url: URL) -> Bool {
        return databaseExtensions.contains(url.pathExtension)
    }
}
