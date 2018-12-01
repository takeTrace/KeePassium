//
//  RootSplitVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-05-31.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

class RootSplitVC: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
    }
    
    // Decides whether to show masterVC or detailVC
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
        ) -> Bool
    {
        if secondaryViewController is PlaceholderVC {
            return true // discard secondaryVC
        }
        return false
    }
}
