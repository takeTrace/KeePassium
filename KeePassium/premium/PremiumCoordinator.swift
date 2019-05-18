//
//  PremiumCoordinator.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2019-05-17.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

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
    
    private let navigationController: UINavigationController
    private let premiumVC: PremiumVC
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        premiumVC = PremiumVC.create(premiumManager: PremiumManager.shared)
        navigationController = UINavigationController(rootViewController: premiumVC)
        premiumVC.delegate = self
    }
    
    func start() {
        // start fetching prices
        self.presentingViewController.present(navigationController, animated: true, completion: nil)
    }
    
    func finish(animated: Bool, completion: (() -> Void)?) {
        navigationController.dismiss(animated: animated) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didFinish(self)
        }
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
