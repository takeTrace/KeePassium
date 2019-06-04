//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit
import KeePassiumLib

public class PremiumUpgradeHelper {
    
    /// Checks premium status before permitting access to a premium feature.
    ///
    /// - Parameters:
    ///   - feature: premium feature that the user requests
    ///   - viewController: host controller for eventual modal notifications
    ///   - premiumActionHandler: should perform requested premium action
    ///   - upgradeActionHandler: should prepare and show upgrade UI
    static func performPremiumAction(
        _ feature: PremiumFeature,
        in viewController: UIViewController,
        premiumActionHandler: @escaping ()->Void,
        upgradeActionHandler: @escaping ()->Void)
    {
        let premiumManager = PremiumManager.shared
        if premiumManager.shouldShowUpgradeNotice(for: feature) {
            PremiumUpgradeHelper.showUpgradeNotice(
                in: viewController,
                for: feature,
                premiumActionHandler: premiumActionHandler,
                upgradeActionHandler: upgradeActionHandler
            )
            premiumManager.setGracePeriodUpgradeNoticeShown(for: feature)
        } else {
            premiumActionHandler()
        }
    }
    
    
    /// Displays "Please upgrade" VC.
    ///
    /// - Parameters:
    ///   - viewController: host VC to present the upgrade notice
    ///   - feature: which premium feature was requested by the user
    ///   - premiumActionHandler: called when the user choses "Continue"
    ///   - upgradeActionHandler: called when the user chooses "Upgrade'
    static func showUpgradeNotice(
        in viewController: UIViewController,
        for feature: PremiumFeature,
        premiumActionHandler: @escaping (()->Void),
        upgradeActionHandler: @escaping (()->Void))
    {
        var message = feature.upgradeNoticeText
        let secondsInOneDay = 24 * 60 * 60.0
        let graceTimeLeft = PremiumManager.shared.gracePeriodSecondsRemaining
        if graceTimeLeft > secondsInOneDay {
            // When less than a day left: don't invite to look around, but allow to use the feature.
            let gracePeriodFooter = "No pressure, though. Feel free to look around for a few days.".localized(comment: "Footer added to `Upgrade to Premium` notice during the free trial/grace period.")
            message = message + "\n\n" + gracePeriodFooter
        }
        
        let alertVC = UIAlertController(
            title: feature.titleName,
            message: message,
            preferredStyle: .alert)
        let upgradeAction = UIAlertAction(
            title: "Upgrade to Premium".localized(comment: "Action in `Upgrade to Premium` dialog: show upgrade options"),
            style: .default,
            handler: { _ in upgradeActionHandler() }
        )
        let continueAction = UIAlertAction(
            title: "Continue Free Trial".localized(comment: "Action in `Upgrade to Premium` dialog: continue free trial"),
            style: .cancel,
            handler: { _ in premiumActionHandler() }
        )
        let cancelAction = UIAlertAction(
            title: LString.actionCancel,
            style: .cancel,
            handler: nil
        )
        if graceTimeLeft > 0 {
            alertVC.addAction(upgradeAction)
            alertVC.addAction(continueAction)
        } else {
            alertVC.addAction(upgradeAction)
            alertVC.addAction(cancelAction)
        }
        viewController.present(alertVC, animated: true, completion: nil)
    }
}
