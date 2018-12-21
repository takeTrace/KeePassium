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

fileprivate let _textBorderColor = UIColor(white: 0.76, alpha: 1.0).cgColor

extension UITextView {
    
    /// Sets view's border to that of UITextField (thin light gray, round corners)
    public func setupBorder() {
        layer.cornerRadius = 5.0
        layer.borderWidth = 0.5
        layer.borderColor = _textBorderColor
    }
}
