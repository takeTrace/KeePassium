//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation

/// Convenience helpers to enforce premium features
public extension Settings {
    func isAllowedDatabaseLockTimeoutWhenExpired(_ timeout: Settings.DatabaseLockTimeout) -> Bool {
        switch timeout {
        case .immediately,
             .after5seconds,
             .after15seconds,
             .after30seconds,
             .after1minute,
             .after2minutes,
             .after5minutes,
             .after10minutes,
             .after30minutes,
             .after1hour:
            return true
        case .after2hours,
             .after4hours,
             .after8hours,
             .after24hours,
             .never:
            return false
        }
    }
    
    /// Returns the value of `databaseLockTimeout`, adjusted to the premium subscription status.
    var premiumDatabaseLockTimeout: Settings.DatabaseLockTimeout {
        let actualTimeout = Settings.current.databaseLockTimeout
        if PremiumManager.shared.status != .expired {
            return actualTimeout
        }
        if isAllowedDatabaseLockTimeoutWhenExpired(actualTimeout) {
            return actualTimeout
        } else {
            // limit to 1 hour in free version
            return .after1hour
        }
    }
    
    var premiumIsBiometricAppLockEnabled: Bool {
        if PremiumManager.shared.status == .expired {
            return false
        }
        return isBiometricAppLockEnabled
    }
    
    var premiumIsKeepKeyFileAssociations: Bool {
        if PremiumManager.shared.status == .expired {
            return false
        }
        return isKeepKeyFileAssociations
    }
    
    func premiumGetKeyFileForDatabase(databaseRef: URLReference) -> URLReference? {
        if PremiumManager.shared.status == .expired {
            return nil
        }
        return getKeyFileForDatabase(databaseRef: databaseRef)
    }
}
