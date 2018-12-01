//
//  AppCoverVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-09-29.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

/// Covers the app when it is in background.
open class AppCoverVC: UIViewController {

    static public func make() -> UIViewController {
        let vc = AppCoverVC.instantiateFromStoryboard()
        return vc
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(patternImage: UIImage(asset: .appCoverPattern))
    }
}
