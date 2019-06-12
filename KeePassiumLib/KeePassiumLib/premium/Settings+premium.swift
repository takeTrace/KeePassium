//
//  Settings+premium.swift
//  KeePassiumLib
//
//  Created by Andrei Popleteev on 2019-06-12.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import Foundation

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
}
