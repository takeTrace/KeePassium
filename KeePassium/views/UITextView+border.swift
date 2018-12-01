//
//  UITextView+border.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-22.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

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
