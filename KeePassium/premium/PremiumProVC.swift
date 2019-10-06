//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit

protocol PremiumProDelegate: class {
    func didPressOpenInAppStore(_ sender: PremiumProVC)
}

class PremiumProVC: UIViewController {
    
    weak var delegate: PremiumProDelegate?
    
    public static func create(delegate: PremiumProDelegate?=nil) -> PremiumProVC {
        let vc = PremiumProVC.instantiateFromStoryboard()
        vc.delegate = delegate
        return vc
    }
    
    @IBAction func didPressOpenInAppStore(_ sender: UIButton) {
        delegate?.didPressOpenInAppStore(self)
    }
}
