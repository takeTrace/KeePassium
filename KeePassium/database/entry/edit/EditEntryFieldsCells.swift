//
//  EditEntryFieldsCells.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-24.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

//  A number of custom cells for entry editor.

import UIKit
import KeePassiumLib

internal protocol EditEntryFieldDelegate: class {
    func editEntryCell(_ sender: EditEntryTableCell, didPressChangeIcon: Bool)
    func editEntryCell(_ sender: EditEntryTableCell, fieldDidChange field: EditableEntryField)
    func editEntryCell(_ sender: EditEntryTableCell, didPressReturn: Bool)
    func editEntryCell(_ sender: EditEntryTableCell, shouldRandomize field: EditableEntryField)
}

internal protocol EditEntryTableCell: class {
    var delegate: EditEntryFieldDelegate? { get set }
    var field: EditableEntryField! { get set }
    func validate()
}


class EditEntryTitleCell:
    UITableViewCell,
    EditEntryTableCell,
    UITextFieldDelegate,
    ValidatingTextFieldDelegate
{
    public static let storyboardID = "TitleCell"
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleTextField: ValidatingTextField!
    @IBOutlet weak var changeIconButton: UIButton!
    
    var field: EditableEntryField! {
        didSet {
            titleTextField.text = field?.value
        }
    }
    var icon: UIImage? {
        get { return iconView.image }
        set { iconView.image = newValue }
    }
    weak var delegate: EditEntryFieldDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleTextField.validityDelegate = self
        titleTextField.delegate = self
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapIcon))
        iconView.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func didTapIcon(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            didPressChangeIcon(gestureRecognizer)
        }
    }
    
    @IBAction func didPressChangeIcon(_ sender: Any) {
        delegate?.editEntryCell(self, didPressChangeIcon: true)
    }
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        titleTextField.becomeFirstResponder()
        if titleTextField.text == LString.defaultNewEntryName {
            // Regardless of mode, suggest to change the default name
            titleTextField.selectAll(nil)
        }
        return result
    }
    
    func validate() {
        titleTextField.validate()
    }
    
    func validatingTextField(_ sender: ValidatingTextField, textDidChange text: String) {
        field.value = titleTextField.text ?? ""
        field.isValid = field.value.isNotEmpty
        delegate?.editEntryCell(self, fieldDidChange: field)
    }
    
    func validatingTextFieldShouldValidate(_ sender: ValidatingTextField) -> Bool {
        return field.isValid
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.editEntryCell(self, didPressReturn: true)
        return false
    }
}

class EditEntrySingleLineCell:
    UITableViewCell,
    EditEntryTableCell,
    ValidatingTextFieldDelegate,
    UITextFieldDelegate
{
    public static let storyboardID = "SingleLineCell"
    @IBOutlet private weak var textField: ValidatingTextField!
    @IBOutlet private weak var titleLabel: UILabel!
    
    var delegate: EditEntryFieldDelegate?
    var field: EditableEntryField! {
        didSet {
            titleLabel.text = field?.visibleName
            textField.text = field?.value
            textField.isSecureTextEntry = field?.isProtected ?? false
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.validityDelegate = self
        textField.delegate = self
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return textField.becomeFirstResponder()
    }

    func validate() {
        textField.validate()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.editEntryCell(self, didPressReturn: true)
        return false
    }
    
    func validatingTextField(_ sender: ValidatingTextField, textDidChange text: String) {
        field.value = textField.text ?? ""
        delegate?.editEntryCell(self, fieldDidChange: field)
    }
    
    func validatingTextFieldShouldValidate(_ sender: ValidatingTextField) -> Bool {
        return field.isValid
    }
}


class EditEntrySingleLineProtectedCell:
    UITableViewCell,
    EditEntryTableCell,
    ValidatingTextFieldDelegate,
    UITextFieldDelegate
{
    public static let storyboardID = "SingleLineProtectedCell"
    @IBOutlet private weak var textField: ValidatingTextField!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet weak var randomizeButton: UIButton!
    
    var delegate: EditEntryFieldDelegate?
    var field: EditableEntryField! {
        didSet {
            titleLabel.text = field?.visibleName
            textField.text = field?.value
            textField.isSecureTextEntry = field?.isProtected ?? false
            randomizeButton.isHidden = (field?.internalName != EntryField.password)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.validityDelegate = self
        textField.delegate = self
    }
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return textField.becomeFirstResponder()
    }
    
    func validate() {
        textField.validate()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.editEntryCell(self, didPressReturn: true)
        return false
    }
    
    func validatingTextField(_ sender: ValidatingTextField, textDidChange text: String) {
        field.value = textField.text ?? ""
        delegate?.editEntryCell(self, fieldDidChange: field)
    }
    
    func validatingTextFieldShouldValidate(_ sender: ValidatingTextField) -> Bool {
        return field.isValid
    }
    
    @IBAction func didPressRandomizeButton(_ sender: Any) {
        delegate?.editEntryCell(self, shouldRandomize: field)
    }
}

class EditEntryMultiLineCell: UITableViewCell, EditEntryTableCell, ValidatingTextViewDelegate {
    public static let storyboardID = "MultiLineCell"
    @IBOutlet private weak var textView: ValidatingTextView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var delegate: EditEntryFieldDelegate?
    var field: EditableEntryField! {
        didSet {
            titleLabel.text = field?.visibleName
            textView.text = field?.value
            textView.isSecureTextEntry = field?.isProtected ?? false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.validityDelegate = self
        DispatchQueue.main.async {
            self.textView.setupBorder()
        }
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return textView.becomeFirstResponder()
    }

    func validate() {
        textView.validate()
    }

    func validatingTextView(_ sender: ValidatingTextView, textDidChange text: String) {
        field.value = textView.text ?? ""
        delegate?.editEntryCell(self, fieldDidChange: field)
    }
    
    func validatingTextViewShouldValidate(_ sender: ValidatingTextView) -> Bool {
        return field.isValid
    }
}

class EditEntryCustomFieldCell:
    UITableViewCell,
    EditEntryTableCell,
    ValidatingTextFieldDelegate,
    ValidatingTextViewDelegate
{
    public static let storyboardID = "CustomFieldCell"
    @IBOutlet private weak var nameTextField: ValidatingTextField!
    @IBOutlet private weak var valueTextView: ValidatingTextView!
    @IBOutlet private weak var protectionSwitch: UISwitch!

    var delegate: EditEntryFieldDelegate?
    var field: EditableEntryField! {
        didSet {
            nameTextField.text = field?.visibleName
            valueTextView.text = field?.value
            protectionSwitch.isOn = field?.isProtected ?? false
            valueTextView.isSecureTextEntry = protectionSwitch.isOn
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        protectionSwitch.addTarget(self, action: #selector(protectionDidChange), for: .valueChanged)
        nameTextField.validityDelegate = self
        valueTextView.validityDelegate = self
        DispatchQueue.main.async {
            self.valueTextView.setupBorder()
        }
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return nameTextField.becomeFirstResponder()
    }

    func selectNameText() {
        nameTextField.selectAll(nil)
    }
    func validate() {
        nameTextField.validate()
        valueTextView.validate()
    }

    func validatingTextField(_ sender: ValidatingTextField, textDidChange text: String) {
        assert(sender == nameTextField)

        field.internalName = text
        field.isValid = nameTextField.isValid
        delegate?.editEntryCell(self, fieldDidChange: field)
    }
    
    func validatingTextFieldShouldValidate(_ sender: ValidatingTextField) -> Bool {
        assert(sender == nameTextField)
        return field.isValid
    }
    
    func validatingTextView(_ sender: ValidatingTextView, textDidChange text: String) {
        assert(sender == valueTextView)
        field.value = valueTextView.text ?? ""
        delegate?.editEntryCell(self, fieldDidChange: field)
    }
    
    func validatingTextViewShouldValidate(_ sender: ValidatingTextView) -> Bool {
        assert(sender == valueTextView)
        return true // only names are checked, any value is ok
    }

    @objc func protectionDidChange() {
        field.isProtected = protectionSwitch.isOn
        valueTextView.isSecureTextEntry = protectionSwitch.isOn
        delegate?.editEntryCell(self, fieldDidChange: field)
    }
}

