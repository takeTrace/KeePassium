//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation
import StoreKit

/// Known predefined products
public enum InAppProduct: String {
    /// General kind of product (single purchase, subscription, ...)
    public enum Kind {
        case oneTime
        case yearly
        case monthly
        case other
    }

    static let allKnownIDs: Set<String> = [
        InAppProduct.foreverBetaSandbox.rawValue,
        InAppProduct.foreverThankYou.rawValue,
        InAppProduct.forever.rawValue,
        InAppProduct.montlySubscription.rawValue,
        InAppProduct.yearlySubscription.rawValue]
    
    case foreverBetaSandbox = "com.keepassium.ios.iap.foreverBeta.sandbox"
    
    case forever = "com.keepassium.ios.iap.forever"
    case foreverThankYou = "com.keepassium.ios.iap.forever.thankYou"
    case montlySubscription = "com.keepassium.ios.iap.subscription.1month"
    case yearlySubscription = "com.keepassium.ios.iap.subscription.1year"
    
    var kind: Kind {
        return InAppProduct.kind(productIdentifier: self.rawValue)
    }

    /// Whether this product should be shown to the user
    var isHidden: Bool {
        return InAppProduct.isHidden(productIdentifier: self.rawValue)
    }

    public static func kind(productIdentifier: String) -> Kind {
        if productIdentifier.contains(".forever") {
            return .oneTime
        } else if productIdentifier.contains(".1year") {
            return .yearly
        } else if productIdentifier.contains(".1month") {
            return .monthly
        } else {
            assertionFailure("Should not be here")
            return .other
        }
    }
    
    
    /// Whether given product should be shown to the user
    public static func isHidden(productIdentifier: String) -> Bool {
        return productIdentifier.contains(".thankYou") ||
            productIdentifier.contains(".hidden") ||
            productIdentifier.contains(".test")
    }
}


// MARK: - PremiumManagerDelegate

public protocol PremiumManagerDelegate: class {
    /// Called once purchase has been started
    func purchaseStarted(in premiumManager: PremiumManager)
    
    /// Called after a successful new or restored purchase
    func purchaseSucceeded(_ product: InAppProduct, in premiumManager: PremiumManager)
    
    /// Purchase is waiting for approval ("Ask to buy" feature)
    func purchaseDeferred(in premiumManager: PremiumManager)
    
    /// Purchase failed (except cancellation)
    func purchaseFailed(with error: Error, in premiumManager: PremiumManager)
    
    /// Purchase cancelled by the user
    func purchaseCancelledByUser(in premiumManager: PremiumManager)
    
    /// Called after all previous transactions have been processed.
    /// If status is still not premium, then "Sorry, no previous purchases could be restored".
    func purchaseRestoringFinished(in premiumManager: PremiumManager)
}

/// Manages availability of some features depending on subscription status.
public class PremiumManager: NSObject {
    public static let shared = PremiumManager()

    public weak var delegate: PremiumManagerDelegate? {
        willSet {
            assert(newValue == nil || delegate == nil, "PremiumManager supports only one delegate")
        }
    }
    
    // MARK: - Subscription status
    
    public enum Status {
        /// The user launched the app but did not use any premium features yet
        case initialGracePeriod
        /// Active premium subscription
        case subscribed
        /// Grace period expired, no premium purchased
        case expired
    }
    
    /// Current subscription status
    public var status: Status = .initialGracePeriod
    
    /// Name of notification broadcasted whenever subscription status might have changed.
    public static let statusUpdateNotification =
        Notification.Name("com.keepassium.premiumManager.statusUpdated")

    /// Sends a notification whenever subscription status might have changed.
    fileprivate func notifyStatusChanged() {
        NotificationCenter.default.post(name: PremiumManager.statusUpdateNotification, object: self)
    }

    private override init() {
        super.init()
        updateStatus()
    }
    
    fileprivate func updateStatus() {
        let previousStatus = status
        if isSubscribed {
            status = .subscribed
        } else {
            if gracePeriodSecondsRemaining > 0 {
                status = .initialGracePeriod
            } else {
                status = .expired
            }
        }
        if status != previousStatus {
            notifyStatusChanged()
        }
    }
    
    /// True iff the user is currently subscribed
    private var isSubscribed: Bool {
        do {
            guard let premiumExpiryDate =
                try Keychain.shared.getPremiumExpiryDate() // throws KeychainError
                else { return false }
            let isPremium = Date.now < premiumExpiryDate
            return isPremium
        } catch {
            Diag.error("Failed to check premium status [message: \(error.localizedDescription)]")
            return false
        }
    }

    
    // MARK: - Grace period management

    /// Time since first launch, when premium features are available in free version.
    private let gracePeriodInSeconds: Double = 1 * 60 //5 * 24 * 60 * 60 //TODO: restore after debug
    
    fileprivate enum UserDefaultsKey {
        static let gracePeriodUpgradeNoticeShownForFeatures =
            "com.keepassium.premium.gracePeriodUpgradeNoticeShownForFeatures"
    }
    
    public var gracePeriodSecondsRemaining: Double {
        let firstLaunchTimestamp = Settings.current.firstLaunchTimestamp
        let secondsFromFirstLaunch = abs(Date.now.timeIntervalSince(firstLaunchTimestamp))
        let secondsLeft = gracePeriodInSeconds - secondsFromFirstLaunch
        Diag.debug(String(format: "Grace period left: %.0f s", secondsLeft))
        return secondsLeft
    }

    /// Remembers that upgrade notice for the given `feature` has been shown.
    /// Use `wasGracePeriodUpgradeNoticeShown` to read remembered value.
    public func setGracePeriodUpgradeNoticeShown(for feature: PremiumFeature) {
        var shownNotices = [Int]()
        if let storedShownNotices = UserDefaults.appGroupShared.array(
            forKey: UserDefaultsKey.gracePeriodUpgradeNoticeShownForFeatures) as? [Int]
        {
            shownNotices = storedShownNotices
        }
        if !shownNotices.contains(feature.rawValue) {
            shownNotices.append(feature.rawValue)
            UserDefaults.appGroupShared.set(
                shownNotices,
                forKey: UserDefaultsKey.gracePeriodUpgradeNoticeShownForFeatures)
            updateStatus()
        }
    }

//    /// True iff the app should offer an upgrade.
//    public var shouldShowUpgradeNotice: Bool {
//        updateStatus()
//        switch status {
//        case .initialGracePeriod:
//            return true
//        case .initialGracePeriodNotified:
//            return false
//        case .subscribed:
//            return false
//        case .expired:
//            return true
//        }
//    }
    
    /// True iff the app should offer an upgrade to premium.
    /// `feature` helps to avoid nagging about the same premium feature.
    public func shouldShowUpgradeNotice(for feature: PremiumFeature) -> Bool {
        switch status {
        case .subscribed:
            return false
        case .expired:
            return true
        case .initialGracePeriod:
            var shownNotices = [Int]()
            if let storedShownNotices = UserDefaults.appGroupShared.array(
                forKey: UserDefaultsKey.gracePeriodUpgradeNoticeShownForFeatures) as? [Int]
            {
                shownNotices = storedShownNotices
            }
            return !shownNotices.contains(feature.rawValue)
        }
    }
    
//    /// Returns true iff the upgrade notice has already been shown.
//    /// Use `setGracePeriodUpgradeNoticeShown` to change returned value.
//    public func wasGracePeriodUpgradeNoticeShown() -> Bool {
//        guard let wasShown = UserDefaults.appGroupShared
//            .object(forKey: UserDefaultsKey.gracePeriodUpgradeNoticeShownForFeatures) as? Bool
//            else { return false }
//        return wasShown
//    }

    // MARK: - Available in-app products
    
    public fileprivate(set) var availableProducts: [SKProduct]?
    private let knownProductIDs = InAppProduct.allKnownIDs
    
    private var productsRequest: SKProductsRequest?

    public typealias ProductsRequestHandler = (([SKProduct]?, Error?) -> Void)
    fileprivate var productsRequestHandler: ProductsRequestHandler?
    
    public func requestAvailableProducts(completionHandler: @escaping ProductsRequestHandler)
    {
        productsRequest?.cancel()
        productsRequestHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: Set<String>(knownProductIDs))
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    // MARK: - In-app purchase transactions
    
    public func startObservingTransactions() {
        SKPaymentQueue.default().add(self)
    }
    
    public func finishObservingTransactions() {
        SKPaymentQueue.default().remove(self)
    }
    
    /// Initiates purchase of the given product.
    public func purchase(_ product: SKProduct) {
        Diag.info("Starting purchase [product: \(product.productIdentifier)]")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    /// Starts restoring completed transactions
    public func restorePurchases() {
        Diag.info("Starting to restore purchases")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}


// MARK: - SKProductsRequestDelegate
extension PremiumManager: SKProductsRequestDelegate {
    public func productsRequest(
        _ request: SKProductsRequest,
        didReceive response: SKProductsResponse)
    {
        Diag.debug("Received list of in-app purchases")
        self.availableProducts = response.products
        productsRequestHandler?(self.availableProducts, nil)
        productsRequest = nil
        productsRequestHandler = nil
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        Diag.warning("Failed to acquire list of in-app purchases [message: \(error.localizedDescription)]")
        self.availableProducts = nil
        productsRequestHandler?(nil, error)
        productsRequest = nil
        productsRequestHandler = nil
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
                didPurchase(with: transaction, in: queue)
            case .purchasing:
                // nothing to do, wait for further updates
                delegate?.purchaseStarted(in: self)
                break
            case .failed:
                // show an error. if cancelled - don't show an error
                didFailToPurchase(with: transaction, in: queue)
                break
            case .restored:
                didRestorePurchase(transaction, in: queue)
                break
            case .deferred:
                // nothing to do, wait for further updates
                delegate?.purchaseDeferred(in: self)
                break
            }
        }
    }
    
    public func paymentQueue(
        _ queue: SKPaymentQueue,
        restoreCompletedTransactionsFailedWithError error: Error)
    {
        Diag.error("Failed to restore purchases [message: \(error.localizedDescription)]")
        delegate?.purchaseFailed(with: error, in: self)
    }

    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        Diag.debug("Finished restoring purchases")
        delegate?.purchaseRestoringFinished(in: self)
    }
    
    // Called when the user purchases some IAP directly from AppStore.
    public func paymentQueue(
        _ queue: SKPaymentQueue,
        shouldAddStorePayment payment: SKPayment,
        for product: SKProduct
        ) -> Bool
    {
        return true // yes, add the purchase to the payment queue.
    }
    
    private func didPurchase(with transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        guard let transactionDate = transaction.transactionDate else {
            // According to docs, this should not happen.
            assertionFailure()
            Diag.warning("IAP transaction date is empty?!")
            // Should not happen, but if it does - keep the transaction around,
            // to be taken into account after bugfix.
            return
        }
        
        let productID = transaction.payment.productIdentifier
        guard let product = InAppProduct(rawValue: productID) else {
            // If we are here, I messed up InAppProduct constants...
            assertionFailure()
            Diag.error("IAP with unrecognized product ID [id: \(productID)]")
            return
        }
        
        Diag.info("IAP purchase update [date: \(transactionDate), product: \(productID)]")
        if applyPurchase(of: product, on: transactionDate) {
            queue.finishTransaction(transaction)
        }
        delegate?.purchaseSucceeded(product, in: self)
    }
    
    private func didRestorePurchase(_ transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        guard let transactionDate = transaction.original?.transactionDate else {
            // According to docs, this should not happen.
            assertionFailure()
            Diag.warning("IAP transaction date is empty?!")
            // there is no point to keep a restored transaction
            queue.finishTransaction(transaction)
            return
        }
        
        let productID = transaction.payment.productIdentifier
        guard let product = InAppProduct(rawValue: productID) else {
            // If we are here, I messed up InAppProduct constants...
            assertionFailure()
            Diag.error("IAP with unrecognized product ID [id: \(productID)]")
            // there is no point to keep a restored transaction
            queue.finishTransaction(transaction)
            return
        }
        Diag.info("Restored purchase [date: \(transactionDate), product: \(productID)]")
        if applyPurchase(of: product, on: transactionDate) {
            queue.finishTransaction(transaction)
        }
        delegate?.purchaseSucceeded(product, in: self)
    }
    
    /// Process new or restored purchase and update internal expiration date.
    ///
    /// - Parameters:
    ///   - product: purchased product
    ///   - transactionDate: purchase transaction date (new/original for new/restored purchase)
    /// - Returns: true if transaction can be finalized
    private func applyPurchase(of product: InAppProduct, on transactionDate: Date) -> Bool {
        let calendar = Calendar.current
        let newExpiryDate: Date
        switch product.kind {
        case .oneTime:
            newExpiryDate = Date.distantFuture
        case .yearly:
            newExpiryDate = calendar.date(byAdding: .year, value: 1, to: transactionDate)!
        case .monthly:
            newExpiryDate = calendar.date(byAdding: .month, value: 1, to: transactionDate)!
        case .other:
            // Ok, being here is dev's fault. A year should be a safe compensation.
            newExpiryDate = calendar.date(byAdding: .year, value: 1, to: transactionDate)!
        }
        
        let keychain = Keychain.shared
        do {
            let oldExpiryDate = try keychain.getPremiumExpiryDate() // throws KeychainError
            if newExpiryDate > (oldExpiryDate ?? Date.distantPast) {
                try keychain.setPremiumExpiryDate(to: newExpiryDate) // throws KeychainError
                updateStatus()
            }
            return true
        } catch {
            // transaction remains unfinished, will be retried on next launch
            Diag.error("Failed to save purchase [message: \(error.localizedDescription)]")
            return false
        }
    }
    
    
    private func didFailToPurchase(
        with transaction: SKPaymentTransaction,
        in queue: SKPaymentQueue)
    {
        guard let _ = transaction.error else {
            assertionFailure()
            Diag.error("In-app purchase failed [message: nil]")
            queue.finishTransaction(transaction)
            return
        }
        guard let error = transaction.error as? SKError else {
            assertionFailure("Not an SKError")
            // DEBUG TIME ONLY - probably should not happen, so leave the transaction hanging
            return
        }

        let productID = transaction.payment.productIdentifier
        guard let _ = InAppProduct(rawValue: productID) else {
            // If we are here, I messed up InAppProduct constants...
            assertionFailure()
            Diag.warning("IAP transaction failed, plus unrecognized product [id: \(productID)]")
            return
        }

        if error.code == .paymentCancelled {
            Diag.info("IAP cancelled by the user [message: \(error.localizedDescription)]")
            delegate?.purchaseCancelledByUser(in: self)
        } else {
            Diag.error("In-app purchase failed [message: \(error.localizedDescription)]")
            delegate?.purchaseFailed(with: error, in: self)
        }
        updateStatus()
        queue.finishTransaction(transaction)
    }
}
