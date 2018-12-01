//
//  ValidatingTextField.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-13.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

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

class ValidatingTextField: WatchdogAwareTextField {

    /// Delegate which checks validity and is notified about its changes.
    var validityDelegate: ValidatingTextFieldDelegate?
    
    /// Background color for when the contents is invalid. Use `nil` for no color change.
    var invalidBackgroundColor: UIColor? = UIColor.red.withAlphaComponent(0.2)
    
    var isValid: Bool {
        get { return validityDelegate?.validatingTextFieldShouldValidate(self) ?? true }
    }

    override var text: String? {
        didSet { validate() }
    }
    
    private var wasValid: Bool?
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addTarget(self, action: #selector(onEditingChanged), for: .editingChanged)
    }
    
    @objc
    override func onEditingChanged(textField: UITextField) {
        super.onEditingChanged(textField: textField)
        validityDelegate?.validatingTextField(self, textDidChange: textField.text ?? "")
        validate()
    }
    
    func validate() {
        let isValid = validityDelegate?.validatingTextFieldShouldValidate(self) ?? true
        if isValid {
            backgroundColor = UIColor.clear
        } else if (wasValid ?? true) { // just became invalid
            backgroundColor = invalidBackgroundColor
        }
        if isValid != wasValid {
            validityDelegate?.validatingTextField(self, validityDidChange: isValid)
        }
        wasValid = isValid
    }
}
