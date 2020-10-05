//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

public enum PremiumFeature: Int {
    public static let all: [PremiumFeature] = [
        .canUseMultipleDatabases, 
        .canUseLongDatabaseTimeouts, 
        .canPreviewAttachments, 
        .canUseHardwareKeys,    
        .canKeepMasterKeyOnDatabaseTimeout, 
        .canChangeAppIcon,
    ]
    
    case canUseMultipleDatabases = 0

    case canUseLongDatabaseTimeouts = 2
    
    case canPreviewAttachments = 3
    
    case canUseHardwareKeys = 4
    
    case canKeepMasterKeyOnDatabaseTimeout = 5
    
    case canChangeAppIcon = 6
    
    case canUseExpressUnlock = 7
    
    public func isAvailable(in status: PremiumManager.Status, fallbackDate: Date?) -> Bool {
        let isEntitled = status == .subscribed ||
            status == .lapsed ||
            wasAvailable(before: fallbackDate)
        
        switch self {
        case .canUseMultipleDatabases,
             .canUseLongDatabaseTimeouts,
             .canUseHardwareKeys,
             .canKeepMasterKeyOnDatabaseTimeout,
             .canChangeAppIcon:
            return isEntitled
        case .canPreviewAttachments:
            return isEntitled || (status != .freeHeavyUse)
        case .canUseExpressUnlock:
            return true 
        }
    }
    
    private func wasAvailable(before fallbackDate: Date?) -> Bool {
        guard let date = fallbackDate else {
            return false
        }
        switch self {
        case .canUseMultipleDatabases:
            return date > Date(iso8601string: "2019-07-31T00:00:00Z")!
        case .canUseLongDatabaseTimeouts:
            return date > Date(iso8601string: "2019-07-31T00:00:00Z")!
        case .canPreviewAttachments:
            return date > Date(iso8601string: "2019-07-31T00:00:00Z")!
        case .canUseHardwareKeys:
            return date > Date(iso8601string: "2020-01-14T00:00:00Z")!
        case .canKeepMasterKeyOnDatabaseTimeout:
            return date > Date(iso8601string: "2020-07-14T00:00:00Z")!
        case .canChangeAppIcon:
            return date > Date(iso8601string: "2020-08-04T00:00:00Z")!
        case .canUseExpressUnlock:
            return date > Date(iso8601string: "2020-10-01T00:00:00Z")!
        }
    }
}
