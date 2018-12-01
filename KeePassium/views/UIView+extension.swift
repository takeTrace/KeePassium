//
//  UIView+extension.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-05-29.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

extension UIView {
    @IBInspectable var borderColor: UIColor? {
        set {
            layer.borderColor = newValue?.cgColor
        }
        get {
            guard let cgColor = layer.borderColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    /// Plays shake animation on the view.
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.duration = 0.6
        animation.values = [-15.0, 15.0, -15.0, 15.0, -7.0, 7.0, -3.0, 3.0, 0.0 ]
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        layer.add(animation, forKey: "shake")
    }
}
