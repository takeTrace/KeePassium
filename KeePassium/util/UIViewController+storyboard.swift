//  KeePassium Password Manager
//  Copyright © 2018 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
