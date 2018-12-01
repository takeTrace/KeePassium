//
//  AppStoreReviewHelper.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-09-20.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

class AppStoreReviewHelper {
    // App ID in AppStore
    static private let appStoreID = 1435127111
    
    /// Opens AppStore page for reviewing the app
    static func writeReview() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appStoreID)&action=write-review") else {
            assertionFailure("Invalid AppStore URL")
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
