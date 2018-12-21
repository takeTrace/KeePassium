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

class FirstSetupVC: UIViewController {
    
    private weak var coordinator: MainCoordinator?
    
    static func make(coordinator: MainCoordinator) -> FirstSetupVC {
        let vc = FirstSetupVC.instantiateFromStoryboard()
        vc.coordinator = coordinator
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    @IBAction func didPressCancelButton(_ sender: Any) {
        coordinator?.dismissAndQuit()
    }
    
    @IBAction func didPressAddDatabase(_ sender: Any) {
        coordinator?.addDatabase()
    }
}
