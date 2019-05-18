//
//  PremiumManager.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2019-05-16.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import Foundation
import StoreKit



public enum InAppProductID: String {

    case foreverBetaSandbox = "com.keepassium.ios.iap.foreverBeta.sandbox"

    /// Lifetime for those who helped with major issues
    case thankYouPremium = "comp.keepassium.iap.thankYou-201905"
    
    /// Lifetime all-you-can-eat
    case foreverPremium = "com.keepassium.iap.forever-201905"
    
}


/// Manages availability of some features depending on subscription status.
public class PremiumManager: NSObject {
    public static let shared = PremiumManager()

    /// Time since first launch, when premium features are available in free version.
    private let gracePeriodInSeconds: Double = 5 * 24 * 60 * 60
    
    /// Premium is not enforced until this time
    private let launchGracePeriodDeadline = DateComponents(
        calendar: Calendar.autoupdatingCurrent,
        timeZone: TimeZone.autoupdatingCurrent,
        year: 2019, month: 7, day: 1,
        hour: 0, minute: 0, second: 0, nanosecond: 0
        ).date! // ok to force-unwrap
    
    private var purchasedProductIDs = Set<InAppProductID>()
    private var productRequest: SKProductsRequest?
    
    public var isGracePeriod: Bool {
        //TODO: if premium, return false
        return (gracePeriodSecondsRemaining > 0) || isLaunchGracePeriod
    }

    public var gracePeriodSecondsRemaining: Double {
        let firstLaunchTimestamp = Settings.current.firstLaunchTimestamp
        let secondsFromFirstLaunch = abs(Date.now.timeIntervalSince(firstLaunchTimestamp))
        let secondsLeft = gracePeriodInSeconds - secondsFromFirstLaunch
        Diag.debug(String(format: "Grace period left: %.0f s", secondsLeft))
        return secondsLeft
    }
    
    public var isLaunchGracePeriod: Bool {
        return Date.now < launchGracePeriodDeadline
    }

    
    fileprivate enum UserDefaultsKey {
        static let shownUpgradeNotices = "com.keepassium.premium.shownUpgradeNotice"
    }
    
    
    
    override init() {
        super.init()
    }
    
    /// True for premium users only.
    public func isFeaturePurchased(_ feature: PremiumFeature) -> Bool {
        return true //TODO
    }
    
    /// Whether to show "Please upgrade" notice for the given feature.
    public func shouldShowUpgradeNotice(for feature: PremiumFeature) -> Bool {
        if isFeaturePurchased(feature) {
            return false // premium user, no further questions
        }
        if isGracePeriod && wasGracePeriodUpgradeNoticeShown(for: feature) {
            return false
        }
        return true
    }
    
    /// Remember that upgrade notice for the given `feature` has been shown.
    /// Use `wasGracePeriodUpgradeNoticeShown` to read remembered value.
    public func setGracePeriodUpgradeNoticeShown(for feature: PremiumFeature) {
        var shownNotices = [Int]()
        if let storedShownNotices = UserDefaults.appGroupShared.array(
            forKey: UserDefaultsKey.shownUpgradeNotices) as? [Int]
        {
            shownNotices = storedShownNotices
        }
        if !shownNotices.contains(feature.rawValue) {
            shownNotices.append(feature.rawValue)
        }
        UserDefaults.appGroupShared.set(shownNotices, forKey: UserDefaultsKey.shownUpgradeNotices)
    }
    
    /// Check if upgrade notice has been previously shown for the given `feature`.
    /// Use `setGracePeriodUpgradeNoticeShown` to change returned value.
    public func wasGracePeriodUpgradeNoticeShown(for feature: PremiumFeature) -> Bool {
        guard let shownNotices = UserDefaults.appGroupShared.array(
            forKey: UserDefaultsKey.shownUpgradeNotices) as? [Int]
            else { return false }
        return shownNotices.contains(feature.rawValue)
    }
}
