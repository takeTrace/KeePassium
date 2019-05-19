//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

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
