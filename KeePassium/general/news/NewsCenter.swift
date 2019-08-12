//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import KeePassiumLib

protocol NewsItem: class {
    /// Internal ID for the news item. Format: "YYYYMM_ShortTitle"
    var key: String { get }
    
    /// News title, should ideally fit into one line
    var title: String { get }
 
    /// True iff this news item was dismissed by the user
    var isHidden: Bool { get set }
    
    /// True iff this news item is appropriate for the current date
    /// (not too early, not too late)
    var isCurrent: Bool { get }
    
    /// Handles action on the news item
    func show(in viewController: UIViewController)
}

extension NewsItem {
    var userDefaultsKey: String { return "com.keepassium.news." + key }

    var isHidden: Bool {
        set {
            UserDefaults.appGroupShared.set(newValue, forKey: userDefaultsKey)
        }
        get {
            return UserDefaults.appGroupShared.bool(forKey: userDefaultsKey)
        }
    }
}

class NewsCenter {
    public static let shared = NewsCenter()
    
    let betaTransitionNews = _201908_BetaTransitionNews()
    let specialPricesNews = _201908_SpecialPricesExpireNews()
    
    public func getTopItem() -> NewsItem? {
        if Settings.current.isTestEnvironment {
            // TestFlight
            if !betaTransitionNews.isHidden {
                return betaTransitionNews
            }
        } else {
            // AppStore
            // nothing special, fallthrough to general
        }
        
        if specialPricesNews.isCurrent
            && !specialPricesNews.isHidden
            && PremiumManager.shared.status != .subscribed
        {
            return specialPricesNews
        }
        return nil
    }
}
