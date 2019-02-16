//
//  DismissablePopover.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2019-02-16.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import UIKit


/// An implementation of `UIPopoverPresentationControllerDelegate`
/// that adds a navigation bar with a dismiss button
/// when the controller is presented in a popup.
class DismissablePopover: NSObject, UIPopoverPresentationControllerDelegate {
    private let barButtonSystemItem: UIBarButtonItem.SystemItem
    
    init(barButtonSystemItem: UIBarButtonItem.SystemItem) {
        self.barButtonSystemItem = barButtonSystemItem
    }
    
    func presentationController(
        _ controller: UIPresentationController,
        viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle
        ) -> UIViewController?
    {
        let dismissableVC = DismissableNavigationController(
            rootViewController: controller.presentedViewController,
            barButtonSystemItem: barButtonSystemItem)
        return dismissableVC
    }
    
}
