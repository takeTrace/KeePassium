//
//  PremiumFeature+extension.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2019-05-18.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import KeePassiumLib

extension PremiumFeature {
    
    public var titleName: String {
        switch self {
        case .canUseMultipleDatabases:
            return "Multiple Databases".localized(comment: "Title of a premium feature: ability to use multiple databases (In Title Case)")
        case .canUseBiometricAppLock:
            return "Biometric Unlock".localized(comment: "Title of a premium feature: ability to use Touch ID / Face ID in AppLock settings (In Title Case)")
        case .canUseLongDatabaseTimeouts:
            return "Long Database Timeouts".localized(comment: "Title of a premium feature: ability to set long delays in Database Lock Timeout settings (In Title Case)")
        case .canEditDatabase:
            return "Edit Database".localized(comment: "Title of a premium feature: ability to edit database: add/edit/delete new groups and entries (In Title Case)")
        case .canPreviewAttachments:
            return "Preview Attachments".localized(comment: "Title of a premium feature: ability to preview some attached files directly in the app (In Title Case)")
        }
    }
    
    public var upgradeNoticeText: String {
        switch self {
        case .canUseMultipleDatabases:
            return "Easily switch between databases in the premium version.".localized(comment: "Description/advertisement for the `Multiple Databases` premium feature")
        case .canUseBiometricAppLock:
            return "Quickly access your passwords using Face ID/Touch ID in the premium version.".localized(comment: "Description/advertisement for the `Biometric Unlock` premium feature")
        case .canUseLongDatabaseTimeouts:
            return "Save time entering your complex master passwords — keep your database open longer in the premium version.".localized(comment: "Description/advertisement for the `Long Database Timeouts` premium feature")
        case .canEditDatabase:
            return "Edit your database, generate new passwords, add new entries and attachments in the premium version.".localized(comment: "Description/advertisement for the `Edit Database` premium feature")
        case .canPreviewAttachments:
            return "Preview images and documents directly in the app, in the premium version.".localized(comment: "Description/advertisement for the `Preview Attachments` premium feature")
        }
    }
}
