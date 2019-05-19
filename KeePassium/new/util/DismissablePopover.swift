//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

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
