//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation

/// Protocol for receivers of `DatabaseManager` notifications. To be used together with `DatabaseManagerNotifications`.
public protocol DatabaseManagerObserver: class {
    /// Database loading/saving was cancelled by user
    func databaseManager(database urlRef: URLReference, isCancelled: Bool)
    
    func databaseManager(progressDidChange progress: ProgressEx)
    
    /// Called before DB unlocking begins.
    func databaseManager(willLoadDatabase urlRef: URLReference)
    /// Called once the DB has been successfully loaded.
    /// `warnings` may contain some important notifications
    /// related to non-blocking issues with the database
    /// (such as orphaned attachments).
    func databaseManager(didLoadDatabase urlRef: URLReference, warnings: DatabaseLoadingWarnings)
    /// Error while loading or decrypting the DB.
    func databaseManager(database urlRef: URLReference, loadingError message: String, reason: String?)
    /// Password/key are invalid (something missing or decrypted checksum mismatch).
    func databaseManager(database urlRef: URLReference, invalidMasterKey message: String)
    
    /// Called before DB saving starts.
    func databaseManager(willSaveDatabase urlRef: URLReference)
    /// Called after the DB has been successfully saved.
    func databaseManager(didSaveDatabase urlRef: URLReference)
    /// Error while encrypting or saving the DB.
    func databaseManager(database urlRef: URLReference, savingError message: String, reason: String?)

    /// Called before DB creation starts, and is followed by saving-related updates.
    func databaseManager(willCreateDatabase urlRef: URLReference)

    func databaseManager(willCloseDatabase urlRef: URLReference)
    func databaseManager(didCloseDatabase urlRef: URLReference)
}

public extension DatabaseManagerObserver {
    // Adding empty methods, so that they become optional to implement
    /// Database loading/saving was cancelled by user
    
    func databaseManager(database urlRef: URLReference, isCancelled: Bool) {}
    func databaseManager(progressDidChange progress: ProgressEx) {}
    func databaseManager(willLoadDatabase urlRef: URLReference) {}
    func databaseManager(didLoadDatabase urlRef: URLReference, warnings: DatabaseLoadingWarnings) {}
    func databaseManager(database urlRef: URLReference, loadingError message: String, reason: String?) {}
    func databaseManager(database urlRef: URLReference, invalidMasterKey message: String) {}
    func databaseManager(willSaveDatabase urlRef: URLReference) {}
    func databaseManager(didSaveDatabase urlRef: URLReference) {}
    func databaseManager(database urlRef: URLReference, savingError message: String, reason: String?) {}
    func databaseManager(willCreateDatabase urlRef: URLReference) {}
    func databaseManager(willCloseDatabase urlRef: URLReference) {}
    func databaseManager(didCloseDatabase urlRef: URLReference) {}
}

