//
//  UIImage+extensions.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-05-30.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

/// Provides images from assets, as well as standard and custom icons for KP1/KP2 items.
enum ImageAsset: String {
    /// names of app image assets
    case lockCover = "app-cover"
    case appCoverPattern = "app-cover-pattern"
    case backgroundPattern = "background-pattern"
    case createItemToolbar = "create-item-toolbar"
    case editItemToolbar = "edit-item-toolbar"
    case lockDatabaseToolbar = "lock-database-toolbar"
    case openURLCellAccessory = "open-url-cellaccessory"
    case deleteItemListitem = "delete-item-listitem"
    case editItemListitem = "rename-item-listitem"
    case databaseCloudListitem = "database-cloud-listitem"
    case databaseLocalListitem = "database-local-listitem"
    case databaseBackupListitem = "database-backup-listitem"
    case databaseErrorListitem = "database-error-listitem"
    case hideAccessory = "hide-accessory"
    case unhideAccessory = "unhide-accessory"
    case hideListitem = "hide-listitem"
    case unhideListitem = "unhide-listitem"
    case copyToClipboardAccessory = "copy-to-clipboard-accessory"
}

extension UIImage {
    convenience init(asset: ImageAsset) {
        self.init(named: asset.rawValue)!
    }
    
    /// Returns standard icon image by its ID.
    static func kpIcon(forID iconID: IconID) -> UIImage? {
        return UIImage(named: String(format: "db-icons/kpbIcon%02d", iconID.rawValue))
    }
    
    /// Returns custom (if any) or standard icon for `entry`.
    static func kpIcon(forEntry entry: Entry) -> UIImage? {
        if entry.isExpired {
            return UIImage(named: "db-icons/kpbIconExpired")
        }
        // KP1 does not support custom icons.
        if let entry2 = entry as? Entry2,
            let db2 = entry2.database as? Database2,
            let customIcon2 = db2.customIcons[entry2.customIconUUID],
            let image = UIImage(data: customIcon2.data.asData) {
            return image
        }
        return kpIcon(forID: entry.iconID)
    }
    
    /// Returns custom (if any) or standard icon for `group`.
    static func kpIcon(forGroup group: Group) -> UIImage? {
        if group.isExpired {
            return UIImage(named: "db-icons/kpbIconExpired")
        }
        // KP1 does not support custom icons.
        if let group2 = group as? Group2,
            let db2 = group2.database as? Database2,
            let customIcon2 = db2.customIcons[group2.customIconUUID],
            let image = UIImage(data: customIcon2.data.asData) {
            return image
        }
        return kpIcon(forID: group.iconID)
    }
    
    /// Icon for database with the given reference (depends on location and error state).
    static func databaseIcon(for urlRef: URLReference) -> UIImage {
        guard !urlRef.info.hasError else {
            return UIImage(asset: .databaseErrorListitem)
        }
        switch urlRef.location {
        case .external:
            return UIImage(asset: .databaseCloudListitem)
        case .internalDocuments, .internalInbox:
            return UIImage(asset: .databaseLocalListitem)
        case .internalBackup:
            return UIImage(asset: .databaseBackupListitem)
        }
    }
}
