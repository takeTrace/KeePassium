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
    static let allValues: [InAppProductID] = [.foreverBetaSandbox]
    
    case foreverBetaSandbox = "com.keepassium.ios.iap.foreverBeta.sandbox"
}


/// Manages availability of some features depending on subscription status.
public class PremiumManager: NSObject {
    public static let shared = PremiumManager()

    /// Time since first launch, when premium features are available in free version.
    private let gracePeriodInSeconds: Double = 5 * 60 //5 * 24 * 60 * 60 //TODO: restore after debug
    
    /// Premium is not enforced until this time
    private let launchGracePeriodDeadline = DateComponents(
        calendar: Calendar.autoupdatingCurrent,
        timeZone: TimeZone.autoupdatingCurrent,
        year: 2019, month: 7, day: 1,
        hour: 0, minute: 0, second: 0, nanosecond: 0
        ).date! // ok to force-unwrap

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
    
    private override init() {
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
        let isGracePeriod = (gracePeriodSecondsRemaining > 0) || isLaunchGracePeriod
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
    
    // MARK: - In-app purchase management

    public typealias ProductListAvailableHandler = (([SKProduct]?, Error?) -> Void)

    private var purchasedProductIDs = Set<InAppProductID>()
    private var productsRequest: SKProductsRequest?
    private var productListAvailableHandler: ProductListAvailableHandler?
    
    public func startObservingTransactions() {
        SKPaymentQueue.default().add(self)
    }
    public func finishObservingTransactions() {
        SKPaymentQueue.default().remove(self)
    }
    
    public func requestAvailableProducts(completionHandler: @escaping ProductListAvailableHandler)
    {
        productsRequest?.cancel()
        productListAvailableHandler = completionHandler
        
        let knownProductIDs: Set<String> = Set(InAppProductID.allValues.map { return $0.rawValue} )
        productsRequest = SKProductsRequest(productIdentifiers: knownProductIDs)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
}

// MARK: - SKPaymentTransactionObserver
extension PremiumManager: SKPaymentTransactionObserver {
    public func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction])
    {
        // Called whenever some payment update happens:
        // subscription made/renewed/cancelled; single purchase confirmed.
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // verify authenticity
                verifyReceipt() { isValid in
                    if isValid {
                        // save status
                        queue.finishTransaction(transaction)
                    }
                }
            case .purchasing:
                // nothing to do, wait for further updates
                break
            case .failed:
                // show an error. if cancelled - don't show an error
                break
            case .restored:
                // same as purchased
                break
            case .deferred:
                // nothing to do, wait for further updates
                break
            }
        }
    }
    
    /// Checks AppStore receipt validity, then calls the completion handler
    /// with `isValid` flag.
    private func verifyReceipt(completion: (Bool)->Void) {
        // maybe some day
        completion(true)
    }
}

// MARK: - SKProductsRequestDelegate
extension PremiumManager: SKProductsRequestDelegate {
    public func productsRequest(
        _ request: SKProductsRequest,
        didReceive response: SKProductsResponse)
    {
        Diag.debug("Received list of in-app purchases")
        productListAvailableHandler?(response.products, nil)
        productsRequest = nil
        productListAvailableHandler = nil
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        Diag.warning("Failed to acquire list of in-app purchases [message: \(error.localizedDescription)]")
        productListAvailableHandler?(nil, error)
        productsRequest = nil
        productListAvailableHandler = nil
    }
}
