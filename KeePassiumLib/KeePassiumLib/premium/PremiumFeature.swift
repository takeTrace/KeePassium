//
//  PremiumFeature.swift
//  KeePassiumLib
//
//  Created by Andrei Popleteev on 2019-05-18.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

/// Features reserved for the premium version.
public enum PremiumFeature: Int {
    
    /// Can unlock any added database (otherwise only one, with olders modification date)
    case canUseMultipleDatabases = 0

    /// Can enable biometric AppLock in settings (otherwise passcode-only)
    case canUseBiometricAppLock = 1
    
    /// Can set Database Timeout to values over 2 hours (otherwise only short delays)
    case canUseLongDatabaseTimeouts = 2
    
    /// Can preview attached files by one tap (otherwise, opens a Share sheet)
    case canPreviewAttachments = 3
    
    /// Can edit entries and groups; otherwise read-only mode
    /// (nothing involving DB saving will be allowed)
    case canEditDatabase = 4
}
