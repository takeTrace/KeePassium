//
//  DismissableNavigationController.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2019-02-16.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import UIKit

/// A convenience subclass of `UINavigationController`,
/// with adds a right button that dismisses the controller.
class DismissableNavigationController: UINavigationController {
    init(
        rootViewController: UIViewController,
        barButtonSystemItem: UIBarButtonItem.SystemItem = .done)
    {
        super.init(rootViewController: rootViewController)
        
        let theButton = UIBarButtonItem(
            barButtonSystemItem: barButtonSystemItem,
            target: self,
            action: #selector(didPressButton))
        rootViewController.navigationItem.rightBarButtonItem = theButton
    }
    
    // Mandatory designated initializer
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    // Mandatory designated initializer
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func didPressButton() {
        self.dismiss(animated: true, completion: nil)
    }
}
