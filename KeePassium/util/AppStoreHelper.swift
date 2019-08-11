//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit

class AppStoreHelper {
    // App ID in AppStore
    static private let appStoreID = 1435127111

    /// Opens AppStore page of the app
    static func openInAppStore() {
        guard let url = URL(string: "itms-apps://apps.apple.com/app/id\(appStoreID)") else {
            assertionFailure("Invalid AppStore URL")
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    /// Opens AppStore page for reviewing the app
    static func writeReview() {
        guard let url = URL(string: "itms-apps://apps.apple.com/app/id\(appStoreID)?action=write-review") else {
            assertionFailure("Invalid AppStore URL")
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
