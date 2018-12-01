//
//  UIViewController+storyboard.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-10-19.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

extension UIViewController {
    
    /// Returns an instance of the VC from same-named storyboard.
    ///
    /// - Parameter name: storyboard name; if `nil`, defaults to VC's class name.
    /// - Returns: view controller instance.
    internal class func instantiateFromStoryboard(_ name: String? = nil) -> Self {
        return instantiateHelper(storyboardName: name)
    }

    private class func instantiateHelper<T>(storyboardName: String?) -> T {
        let className = String(describing: self)
        let storyboard = UIStoryboard(name: storyboardName ?? className, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: className) as! T
        return vc
    }
}
