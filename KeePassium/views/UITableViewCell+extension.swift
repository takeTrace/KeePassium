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

extension UITableViewCell {
    
    /// Enables/disables the cell and user interaction on it.
    func setEnabled(_ isEnabled: Bool) {
        let alpha: CGFloat = isEnabled ? 1.0 : 0.43
        textLabel?.alpha = alpha
        detailTextLabel?.alpha = alpha
        isUserInteractionEnabled = isEnabled
    }
}
