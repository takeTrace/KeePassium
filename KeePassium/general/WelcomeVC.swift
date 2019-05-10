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
import KeePassiumLib

protocol WelcomeDelegate: class {
    func didPressCreateDatabase(in welcomeVC: WelcomeVC)
    func didPressAddExistingDatabase(in welcomeVC: WelcomeVC)
}

/// Shown on first run of the app, provides user onboarding.
class WelcomeVC: UIViewController {
    private weak var delegate: WelcomeDelegate?

    static func make(delegate: WelcomeDelegate) -> WelcomeVC {
        let vc = WelcomeVC.instantiateFromStoryboard()
        vc.delegate = delegate
        return vc
    }
    
    @IBAction func didPressCreateDatabase(_ sender: Any) {
        delegate?.didPressCreateDatabase(in: self)
    }
    
    @IBAction func didPressOpenDatabase(_ sender: Any) {
        delegate?.didPressAddExistingDatabase(in: self)
    }
}
