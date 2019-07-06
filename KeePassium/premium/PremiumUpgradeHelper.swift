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
    
    fileprivate var premiumCoordinator: PremiumCoordinator?
    
    init() {
        // left empty
    }
    
    
    /// Checks premium status before permitting access to a premium feature.
    ///
    /// - Parameters:
    ///   - feature: premium feature that the user requests
    ///   - viewController: host controller for eventual modal notifications
    ///   - actionHandler: should perform requested premium action
    public func performActionOrOfferUpgrade(
        _ feature: PremiumFeature,
        in viewController: UIViewController,
        actionHandler: @escaping ()->Void)
    {
        if feature.isAvailable(in: PremiumManager.shared.status) {
            actionHandler()
        } else {
            offerUpgrade(feature, in: viewController)
        }
    }
        
    public func offerUpgrade(_ feature: PremiumFeature, in viewController: UIViewController) {
        let alertVC = UIAlertController(
            title: feature.titleName,
            message: feature.upgradeNoticeText,
            preferredStyle: .alert)
        let upgradeAction = UIAlertAction(
            title: "Upgrade to Premium".localized(comment: "Action in `Upgrade to Premium` dialog, opens the upgrade options screen"),
            style: .default,
            handler: { [weak self] _ in
                guard let self = self else { return }
                self.premiumCoordinator = PremiumCoordinator(
                    presentingViewController: viewController
                )
                self.premiumCoordinator?.delegate = self
                self.premiumCoordinator?.start()
            }
        )
        let cancelAction = UIAlertAction(
            title: LString.actionCancel,
            style: .cancel,
            handler: nil
        )
        alertVC.addAction(upgradeAction)
        alertVC.addAction(cancelAction)
        
        viewController.present(alertVC, animated: true, completion: nil)
    }
}

// MARK: - PremiumCoordinatorDelegate
extension PremiumUpgradeHelper: PremiumCoordinatorDelegate {
    func didFinish(_ premiumCoordinator: PremiumCoordinator) {
        self.premiumCoordinator = nil
    }
}
