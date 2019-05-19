//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit

protocol ValidatingTextFieldDelegate {
    /// Called whenever the user changes the text, immediately before validation
    func validatingTextField(_ sender: ValidatingTextField, textDidChange text: String)
    /// Should return `true` if the text is valid, `false` otherwise
    func validatingTextFieldShouldValidate(_ sender: ValidatingTextField) -> Bool
    /// Called after text field validity changes.
    func validatingTextField(_ sender: ValidatingTextField, validityDidChange isValid: Bool)
}

extension ValidatingTextFieldDelegate {
    // Empty method stubs, to make their implementation optional for delegates.
    func validatingTextField(_ sender: ValidatingTextField, textDidChange text: String) {}
    func validatingTextFieldShouldValidate(_ sender: ValidatingTextField) -> Bool { return true }
    func validatingTextField(_ sender: ValidatingTextField, validityDidChange isValid: Bool) {}
}

/// Checks and visualizes the validity of the entered text.
/// If there is `Watchdog` available, can also restart it on every text input event.
class ValidatingTextField: UITextField {
    
    /// Delegate which checks validity and is notified about its changes.
    var validityDelegate: ValidatingTextFieldDelegate?
    
    /// Background color for when the contents is invalid. Use `nil` for no color change.
    
    @IBInspectable var invalidBackgroundColor: UIColor? = UIColor.red.withAlphaComponent(0.2)
    
    /// Background color to use when the contents is valid (by default, clear).
    @IBInspectable var validBackgroundColor: UIColor? = UIColor.clear
    
    /// Defines whether typing resets the watchdog (true by default).
    @IBInspectable var isWatchdogAware = true

    var isValid: Bool {
        get { return validityDelegate?.validatingTextFieldShouldValidate(self) ?? true }
    }

    override var text: String? {
        didSet { validate() }
    }
    
    private var wasValid: Bool?
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        validBackgroundColor = backgroundColor
        addTarget(self, action: #selector(onEditingChanged), for: .editingChanged)
    }
    
    @objc
    private func onEditingChanged(textField: UITextField) {
        if isWatchdogAware {
            Watchdog.shared.restart()
        }
        validityDelegate?.validatingTextField(self, textDidChange: textField.text ?? "")
        validate()
    }
    
    func validate() {
        let isValid = validityDelegate?.validatingTextFieldShouldValidate(self) ?? true
        if isValid {
            backgroundColor = validBackgroundColor
        } else if (wasValid ?? true) { // just became invalid
            backgroundColor = invalidBackgroundColor
        }
        if isValid != wasValid {
            validityDelegate?.validatingTextField(self, validityDidChange: isValid)
        }
        wasValid = isValid
    }
}
