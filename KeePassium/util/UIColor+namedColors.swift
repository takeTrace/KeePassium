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

/// Adds named colors from the assets, as well as system colors as defined at
/// https://developer.apple.com/ios/human-interface-guidelines/visual-design/color/
extension UIColor {
    
    static var actionTint: UIColor {
        return UIColor(named: "ActionTint") ?? UIColor.systemBlue
    }
    static var actionText: UIColor {
        return UIColor(named: "ActionText") ?? .white
    }
    static var destructiveTint: UIColor {
        return UIColor(named: "DestructiveTint") ?? UIColor.systemRed
    }
    static var destructiveText: UIColor {
        return UIColor(named: "DestructiveText") ?? .white
    }
    static var errorMessage: UIColor {
        return UIColor.systemRed
    }
    static var primaryText: UIColor {
        return UIColor(named: "PrimaryText") ?? .black
    }
    static var auxiliaryText: UIColor {
        return UIColor(named: "AuxiliaryText") ?? .darkGray
    }

//    static var navBarTint: UIColor {
//        return UIColor(named: "NavBarTint") ?? UIColor.systemBlue
//    }
    
    static let systemRed = UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1)
    static let systemOrange = UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1)
    static let systemYellow = UIColor(red: 255/255, green: 204/255, blue: 0/255, alpha: 1)
    static let systemGreen = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
    static let systemTealBlue = UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 1)
    static let systemBlue = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
    static let systemPurple = UIColor(red: 88/255, green: 86/255, blue: 214/255, alpha: 1)
    static let systemPink = UIColor(red: 255/255, green: 45/255, blue: 85/255, alpha: 1)
}
