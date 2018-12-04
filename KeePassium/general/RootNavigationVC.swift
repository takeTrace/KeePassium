//
//  RootNavigationVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-05-31.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

class RootNavigationVC: UINavigationController, UINavigationControllerDelegate {

    var databaseManagerNotifications: DatabaseManagerNotifications!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        databaseManagerNotifications = DatabaseManagerNotifications(observer: self)
        databaseManagerNotifications.startObserving()
    }
    
    deinit {
        databaseManagerNotifications.stopObserving()
    }
    
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool)
    {
        //FIXME: controlling bottom toolbar's visibility via storyboard is erratic.
        // This is an ugly hack to ensure it is visible when needed (and only when needed).
        let showBottomToolbar = viewController is ViewGroupVC || viewController is ChooseDatabaseVC
        navigationController.isToolbarHidden = !showBottomToolbar
    }

    
    /// Pops all view controllers with DB content.
    func dismissDatabaseContentControllers() {
        
        // We need to pop back to the first VC before any ViewGroupVC.
        // We might as well be already at that VC (e.g. when popped the root group's VC).
        // Note: in collapsed split view there can be other stuff on top of ViewGroupVC
        //       (for example, ViewEntry or Settings), so we need to dig down to ViewGroupVC first.
        var hasReachedViewGroupVC = false
        var popToVC: UIViewController?
        for vc in viewControllers.reversed() {
            let isViewGroupVC = vc is ViewGroupVC
            if !hasReachedViewGroupVC && isViewGroupVC {
                // phase1: we have reached the ViewGroupVC layer
                hasReachedViewGroupVC = true
            }
            if hasReachedViewGroupVC && !isViewGroupVC {
                // phase 2: we passed through the ViewGroupVC layer
                popToVC = vc
                break
            }
        }

        guard let targetVC = popToVC else { return }
        
        if !(splitViewController!.isCollapsed) {
            // Cover the right pane during the transition.
            splitViewController?.showDetailViewController(PlaceholderVC.make(), sender: self)
        }
        
        // Now that we know what to dismiss and what to pop, do that in sequence.
        if let presentedVC = presentedViewController {
            if presentedVC.isBeingDismissed {
                popToViewController(targetVC, animated: true)
            } else {
                dismiss(animated: false, completion: {
                    self.popToViewController(targetVC, animated: true)
                })
            }
        } else {
            popToViewController(targetVC, animated: true)
        }
    }
}

extension RootNavigationVC: DatabaseManagerObserver {
    func databaseManager(willCloseDatabase urlRef: URLReference) {
        dismissDatabaseContentControllers()
    }
}
