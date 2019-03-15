//
//  ViewEntryFieldCellFactory.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2019-03-14.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib


class ViewableFieldCellFactory {
    public static func dequeueAndConfigureCell(
        from tableView: UITableView,
        for indexPath: IndexPath,
        field: ViewableField
    ) -> ViewableFieldCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ViewableFieldCell.storyboardID,
            for: indexPath)
            as! ViewableFieldCell
        cell.field = field
        
        if field is TOTPViewableField {
            cell.decorator = TOTPFieldCellDecorator(cell: cell)
        } else if field.isProtected {
            cell.decorator = ProtectedFieldCellDecorator(cell: cell)
        } else {
            cell.decorator = URLFieldCellDecorator(cell: cell)
        }
        cell.setupCell()
        return cell
    }
}

class OpenURLAccessoryButton: UIButton {
    required init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 80))
        setImage(UIImage(asset: .openURLCellAccessory), for: .normal)
        contentMode = .scaleAspectFit
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

class ToggleVisibilityAccessoryButton: UIButton {
    required init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 80))
        setImage(UIImage(asset: .unhideListitem), for: .normal)
        setImage(UIImage(asset: .hideListitem), for: .selected)
        setImage(UIImage(asset: .hideListitem), for: .highlighted)
        contentMode = .scaleAspectFit
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

protocol ViewableFieldCellDecorator: class {
    func setupCell(_ cell: ViewableFieldCell)
    func getValue() -> String?
    init(cell: ViewableFieldCell)
}

class ViewableFieldCell: UITableViewCell {
    public static let storyboardID = "ViewableFieldCell"
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var valueLabel: UILabel!
    @IBOutlet fileprivate weak var progressView: UIProgressView!
    
    var decorator: ViewableFieldCellDecorator?
    weak var field: ViewableField?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    func setupCell() {
        nameLabel.text = field?.visibleName
        valueLabel.text = decorator?.getValue()
        decorator?.setupCell(self)
    }
}

/// Adds an "Open URL" button to `ViewableFieldCell`
class URLFieldCellDecorator: ViewableFieldCellDecorator {
    weak var cell: ViewableFieldCell?
    private var url: URL?

    required init(cell: ViewableFieldCell) {
        self.cell = cell
    }
    
    func setupCell(_ cell: ViewableFieldCell) {
        cell.progressView.isHidden = true
        guard let urlString = cell.field?.value, urlString.isOpenableURL else {
            url = nil
            cell.accessoryType = .none
            cell.accessoryView = nil
            return
        }
        
        url = URL(string: urlString)
        let openURLButton = OpenURLAccessoryButton()
        openURLButton.addTarget(
            self,
            action: #selector(didPressOpenURLButton),
            for: .touchUpInside)
        cell.accessoryView = openURLButton
        cell.accessoryType = .detailButton
    }
    
    func getValue() -> String? {
        return cell?.field?.value
    }

    @objc
    private func didPressOpenURLButton(_ sender: UIButton) {
        guard let url = url else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

class ProtectedFieldCellDecorator: ViewableFieldCellDecorator {
    weak var cell: ViewableFieldCell?
    private let hiddenValueMask = "* * * *"
    private var toggleButton: ToggleVisibilityAccessoryButton? // strong ref
    
    required init(cell: ViewableFieldCell) {
        self.cell = cell
    }
    
    func setupCell(_ cell: ViewableFieldCell) {
        cell.progressView.isHidden = true
        
        let theButton = ToggleVisibilityAccessoryButton()
        theButton.addTarget(self, action: #selector(toggleValueHidden), for: .touchUpInside)
        theButton.isSelected = !(cell.field?.isValueHidden ?? true)
        cell.accessoryView = theButton
        cell.accessoryType = .detailButton
        self.toggleButton = theButton
    }
    
    func getValue() -> String? {
        guard let field = cell?.field else { return nil }
        return field.isValueHidden ? hiddenValueMask : field.value
    }
    
    @objc func toggleValueHidden() {
        guard let toggleButton = toggleButton,
              let cell = cell,
              let field = cell.field else { return }
        
        toggleButton.isSelected = !toggleButton.isSelected
        field.isValueHidden = !toggleButton.isSelected
        UIView.animate(
            withDuration: 0.1,
            delay: 0.0,
            options: UIView.AnimationOptions.curveLinear,
            animations: {
                cell.valueLabel.alpha = 0.0
            },
            completion: {
                [weak self] _ in
                guard let _self = self else { return }
                cell.valueLabel.text = _self.getValue()
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0.0,
                    options: UIView.AnimationOptions.curveLinear,
                    animations: {
                        cell.valueLabel.alpha = 1.0
                    },
                    completion: nil)
            }
        )
    }
}

class TOTPFieldCellDecorator: ViewableFieldCellDecorator {
    private let refreshInterval = 1.0
    weak var cell: ViewableFieldCell?

    required init(cell: ViewableFieldCell) {
        self.cell = cell
    }

    func getValue() -> String? {
        return cell?.field?.value
    }
    
    func setupCell(_ cell: ViewableFieldCell) {
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.progressView.isHidden = false
        refreshProgress()
        scheduleRefresh()
    }
    
    private func scheduleRefresh() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + refreshInterval) {
            [weak self] in
            guard let cell = self?.cell else { return }
            cell.valueLabel.text = self?.getValue()
            self?.refreshProgress()
            self?.scheduleRefresh()
        }
    }
    
    private func refreshProgress() {
        guard let cell = cell else { return }
        guard let totpViewableField = cell.field as? TOTPViewableField else {
            assertionFailure()
            return
        }
        let progress = 1 - (totpViewableField.elapsedTimeFraction ?? 0.0)
        cell.progressView.setProgress(progress, animated: true)
    }
}


