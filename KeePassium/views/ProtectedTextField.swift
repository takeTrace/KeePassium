//
//  ProtectedTextField.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-11-29.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

class ProtectedTextField: ValidatingTextField {
    private let horizontalInsets = CGFloat(8.0)
    private let verticalInsets = CGFloat(2.0)
    
    private var toggleButton: UIButton!
    override var isSecureTextEntry: Bool {
        didSet {
            toggleButton?.isSelected = !isSecureTextEntry
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let unhideImage = UIImage(asset: .unhideAccessory)
        let hideImage = UIImage(asset: .hideAccessory)

        toggleButton = UIButton(type: .custom)
        toggleButton.tintColor = UIColor.actionTint // UIColor.secondaryText
        toggleButton.addTarget(self, action: #selector(toggleVisibility), for: .touchUpInside)
        toggleButton.setImage(unhideImage, for: .normal)
        toggleButton.setImage(hideImage, for: .selected)
        toggleButton.imageEdgeInsets = UIEdgeInsets(
            top: verticalInsets,
            left: horizontalInsets,
            bottom: verticalInsets,
            right: horizontalInsets)
        toggleButton.frame = CGRect(
            x: 0.0,
            y: 0.0,
            width: hideImage.size.width + 2 * horizontalInsets,
            height: hideImage.size.height + 2 * verticalInsets)
        toggleButton.isSelected = !isSecureTextEntry
        self.rightView = toggleButton
        self.rightViewMode = .always
    }

    @objc
    func toggleVisibility(_ sender: Any) {
        isSecureTextEntry = !isSecureTextEntry
    }
}
