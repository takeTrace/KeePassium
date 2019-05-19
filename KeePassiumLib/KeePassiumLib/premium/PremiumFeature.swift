//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

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
