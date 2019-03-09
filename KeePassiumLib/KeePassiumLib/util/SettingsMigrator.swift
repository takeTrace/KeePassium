//
//  SettingsMigrator.swift
//  KeePassiumLib
//
//  Created by Andrei Popleteev on 2019-02-19.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import Foundation

/// Keeps track of the current version of app settings,
/// and upgrades them when needed.
open class SettingsMigrator {
    
    /// Upgrades settings format to the current version, if necessary.
    public static func processAppLaunch(with settings: Settings) {
        if settings.isFirstLaunch {
            Diag.info("Processing first launch.")
            settings.settingsVersion = Settings.latestVersion
            
            /// Previous installation might have left some data in the keychain.
            /// To avoid magically opening DBs, we need to cleanup first.
            cleanupKeychain()
        } else {
            // maybe upgrade
            let latestVersion = Settings.latestVersion
            while settings.settingsVersion < latestVersion {
                upgrade(settings)
            }
        }
    }

    
    private static func cleanupKeychain() {
        do {
            try Keychain.shared.removeAll() // throws KeychainError
        } catch {
            // just log and continue, nothing else to do
            Diag.error("Failed to clean up keychain [message: \(error.localizedDescription)]")
        }
    }
    
    /// Upgrades settings format by one version.
    private static func upgrade(_ settings: Settings) {
        let fromVersion = settings.settingsVersion
        switch fromVersion {
        case 0: // no version info stored, probably first run
            assert(settings.isFirstLaunch)
            // assume the version is up to date, and save it so
            settings.settingsVersion = Settings.latestVersion
        case 3:
            // no upgrades yet
            break
        default:
            // nothing to do
            break
        }
    }
    
    
}
