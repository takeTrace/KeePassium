//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit
import KeePassiumLib

protocol PremiumCoordinatorDelegate: class {
    /// The user has successfully purchased/restored premium
    func didUpgradeToPremium(in premiumCoordinator: PremiumCoordinator)
    
    /// The coordinator has finished work (called regardless the outcome).
    func didFinish(_ premiumCoordinator: PremiumCoordinator)
}

class PremiumCoordinator {
    
    weak var delegate: PremiumCoordinatorDelegate?
    
    /// Parent VC which will present our modal form
    let presentingViewController: UIViewController
    
    private let premiumManager: PremiumManager
    private let navigationController: UINavigationController
    private let premiumVC: PremiumVC
    
    init(presentingViewController: UIViewController) {
        self.premiumManager = PremiumManager.shared
        self.presentingViewController = presentingViewController
        premiumVC = PremiumVC.create(premiumManager: premiumManager)
        navigationController = UINavigationController(rootViewController: premiumVC)
        premiumVC.delegate = self
    }
    
    func start() {
        self.presentingViewController.present(navigationController, animated: true, completion: nil)
        premiumManager.requestAvailableProducts(completionHandler: {
            [weak self] (products, error) in
            if let error = error {
                self?.showStoreError(error.localizedDescription)
                return
            }
            guard let products = products, products.count > 0 else {
                self?.showStoreError("Hmm, there are no available premium upgrades. This should not happen, please contact support.".localized(comment: "Error message: AppStore returned no available in-app purchase options"))
                return
            }
            //TODO: elaborate on this
            for product in products {
                print("\nID: \(product.productIdentifier)")
                print("Title: \(product.localizedTitle)")
                print("Description: \(product.localizedDescription)")
                print("Raw price: \(product.price.floatValue)")
                print("Localized price: \(product.localizedPrice)")
            }
        })
    }
    
    func finish(animated: Bool, completion: (() -> Void)?) {
        navigationController.dismiss(animated: animated) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didFinish(self)
        }
    }
    
    func showStoreError(_ message: String) {
        Diag.error("IAP error [message: \(message)]")
        let alert = UIAlertController(
            title: "Cannot contact AppStore".localized(comment: "Title of error message related to in-app purchase"),
            message: message,
            preferredStyle: .alert)
        let cancelAction = UIAlertAction(
            title: LString.actionCancel,
            style: .cancel,
            handler: { [weak self] _ in
                self?.finish(animated: true, completion: nil)
            }
        )
        alert.addAction(cancelAction)
        navigationController.present(alert, animated: true, completion: nil)
    }
}

// MARK: - PremiumDelegate

extension PremiumCoordinator: PremiumDelegate {
    func didPressCancel(in premiumController: PremiumVC) {
        finish(animated: true, completion: nil)
    }
    
    func didPressRestorePurchases(in premiumController: PremiumVC) {
        //TODO
    }
    
    func didPressBuyForever(in premiumController: PremiumVC) {
        //TODO
    }
}
