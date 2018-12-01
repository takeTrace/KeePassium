//
//  UITableViewCell+extension.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-08-04.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

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
