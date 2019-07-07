//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation

public class AppGroup {
    /// App Group identifier string.
    public static let id = "group.com.keepassium"
    
    /// Predefined app custom URL scheme
    public static let appURLScheme = "keepassium"
    
    /// Predefined URL to start premium upgrade
    public static let upgradeToPremiumURL = URL(string: appURLScheme + ":upgradeToPremium")! // ok to force-unwrap
    
    // True when running in main app, false for app extensions.
    public static var isMainApp: Bool {
        return applicationShared != nil
    }
    
    // In main app: same as UIApplication.shared (must be manually set on launch)
    // In app extension: nil
    public static weak var applicationShared: UIApplication?
}
