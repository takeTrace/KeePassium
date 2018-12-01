//
//  PlaceholderVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-07-02.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

/// Shown in detail view when there is nothing more useful to show there.
class PlaceholderVC: UIViewController {
    
    static func make() -> UIViewController {
        return PlaceholderVC.instantiateFromStoryboard()
    }
}
