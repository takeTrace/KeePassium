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
import MobileCoreServices
import KeePassiumLib

fileprivate class OpenURLAccessoryButton: UIButton {
    required init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 80))
        setImage(UIImage(asset: .openURLCellAccessory), for: .normal)
        contentMode = .scaleAspectFit
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

fileprivate class ToggleVisibilityAccessoryButton: UIButton {
    required init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 80))
        setImage(UIImage(asset: .unhideListitem), for: .normal)
        setImage(UIImage(asset: .hideListitem), for: .selected)
        contentMode = .scaleAspectFit
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

protocol ViewEntryFieldCellDelegate: class {
    func cellContentDidChange(cell: UITableViewCell)
}

class ViewEntrySimpleFieldCell: UITableViewCell, Refreshable {
    fileprivate static let storyboardID = "SimpleFieldCell"
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var valueLabel: UILabel!
    
    fileprivate weak var delegate: ViewEntryFieldCellDelegate?
    fileprivate var url: URL?
    fileprivate var field: VisibleEntryField! {
        didSet {
            nameLabel.text = field?.visibleName
            valueLabel.text = field?.value
            refresh()
        }
    }
    
    func refresh() {
        if let urlString = field?.value, urlString.isOpenableURL {
            url = URL(string: urlString)
            let openURLButton = OpenURLAccessoryButton()
            openURLButton.addTarget(
                self,
                action: #selector(didPressOpenURLButton),
                for: .touchUpInside)
            accessoryView = openURLButton
            accessoryType = .detailButton
        } else {
            url = nil
            accessoryType = .none
            accessoryView = nil
        }
    }

    @objc func didPressOpenURLButton(_ sender: UIButton) {
        guard let url = url else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}


class ViewEntryProtectedFieldCell: UITableViewCell {
    fileprivate static let storyboardID = "ProtectedFieldCell"

    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var valueLabel: UILabel!

    fileprivate var url: URL?
    fileprivate weak var delegate: ViewEntryFieldCellDelegate?

    private let hiddenValue = "* * * *"
    private var toggleButton: ToggleVisibilityAccessoryButton!
    
    fileprivate var field: VisibleEntryField! {
        didSet {
            nameLabel.text = field?.visibleName
            valueLabel.text = field.isHidden ? hiddenValue : field.value
            toggleButton.isSelected = !(field?.isHidden ?? false)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        toggleButton = ToggleVisibilityAccessoryButton()
        toggleButton.addTarget(self, action: #selector(toggleVisibility), for: .touchUpInside)
        accessoryView = toggleButton
        accessoryType = .detailButton
    }

    @IBAction func toggleVisibility() {
        toggleButton.isSelected = !toggleButton.isSelected

        field.isHidden = !toggleButton.isSelected
        UIView.animate(
            withDuration: 0.1,
            delay: 0.0,
            options: UIView.AnimationOptions.curveLinear,
            animations: {
                [unowned self] in
                self.valueLabel.alpha = 0.0
            },
            completion: {
                [unowned self] _ in
                self.valueLabel.text = self.field.isHidden ? self.hiddenValue : self.field.value
                self.delegate?.cellContentDidChange(cell: self)
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0.0,
                    options: UIView.AnimationOptions.curveLinear,
                    animations: {
                        [unowned self] in
                        self.valueLabel.alpha = 1.0
                    },
                    completion: nil)
            }
        )
    }
}

class ViewEntryFieldsVC: UITableViewController, Refreshable {
    @IBOutlet weak var copiedCellView: UIView!
    
    private let editButton = UIBarButtonItem()

    private weak var entry: Entry?
    private var isHistoryMode = false
    private var sortedFields: [VisibleEntryField] = []
    private var entryChangeNotifications: EntryChangeNotifications!

    static func make(with entry: Entry?, historyMode: Bool) -> ViewEntryFieldsVC {
        let viewEntryFieldsVC = ViewEntryFieldsVC.instantiateFromStoryboard()
        viewEntryFieldsVC.entry = entry
        viewEntryFieldsVC.isHistoryMode = historyMode
        return viewEntryFieldsVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        tableView.dragDelegate = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressGestureRecognizer)
        
        editButton.image = UIImage(asset: .editItemToolbar)
        editButton.target = self
        editButton.action = #selector(onEditAction)
        
        entryChangeNotifications = EntryChangeNotifications(observer: self)
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = isHistoryMode ? nil : editButton
        entryChangeNotifications.startObserving()
        refresh()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        entryChangeNotifications.stopObserving()
        super.viewWillDisappear(animated)
    }

    func refresh() {
        guard let entry = entry else { return }
        
        let category = ItemCategory.get(for: entry)
        let fields = VisibleEntryField.extractAll(
            from: entry, skipTitle: true, skipEmptyValues: true)
        self.sortedFields = fields.sorted {
            return category.compare($0.internalName, $1.internalName)
        }
        tableView.reloadData()
    }
    
    // MARK: - Action handlers
    
    @objc func onEditAction() {
        guard let entry = entry else { return }
        let editEntryFieldsVC = EditEntryVC.make(entry: entry, popoverSource: nil, delegate: nil)
        present(editEntryFieldsVC, animated: true, completion: nil)
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }

        let point = gestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        
        let fieldNumber = indexPath.row
        let field = sortedFields[fieldNumber]
        
        var items: [Any] = [field.value]
        if field.value.isOpenableURL, let url = URL(string: field.value) {
                items = [url]
            }
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: indexPath)
        }
        present(activityVC, animated: true)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedFields.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell
    {
        let fieldNumber = indexPath.row
        let field = sortedFields[fieldNumber]

        if field.isProtected {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ViewEntryProtectedFieldCell.storyboardID,
                for: indexPath)
                as! ViewEntryProtectedFieldCell
            cell.field = field
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ViewEntrySimpleFieldCell.storyboardID,
                for: indexPath)
                as! ViewEntrySimpleFieldCell
            cell.field = field
            cell.delegate = self
            return cell
        }
    }
    
    // MARK: - Cell copying animation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fieldNumber = indexPath.row
        let text: String
        let field = sortedFields[fieldNumber]
        text = field.value

        let timeout = Double(Settings.current.clipboardTimeout.seconds)
        if text.isOpenableURL {
            Clipboard.general.insert(url: URL(string: text)!, timeout: timeout)
        } else {
            Clipboard.general.insert(text: text, timeout: timeout)
        }
        animateCopyToClipboard(indexPath: indexPath)
    }
    
    /// Animates appearing and disappearing of the "Field Copied" notification.
    func animateCopyToClipboard(indexPath: IndexPath) {
        tableView.allowsSelection = false
        guard let cell = tableView.cellForRow(at: indexPath) else { assertionFailure(); return }
        copiedCellView.frame = cell.bounds
        copiedCellView.layoutIfNeeded()
        cell.addSubview(copiedCellView)

        DispatchQueue.main.async { [weak self] in
            guard let _self = self else { return }
            _self.showCopyNotification(indexPath: indexPath, view: _self.copiedCellView)
        }
    }
    
    /// Helper function: Phase 1 of `animateCopyToClipboard`
    private func showCopyNotification(indexPath: IndexPath, view: UIView) {
        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            options: .curveEaseOut ,
            animations: {
                view.backgroundColor = UIColor.actionTint
                view.alpha = 1.0
            },
            completion: {
                [weak self] finished in
                guard let _self = self else { return }
                _self.tableView.deselectRow(at: indexPath, animated: false)
                _self.hideCopyNotification(view: view)
            }
        )
    }
    
    /// Helper function: Phase 2 of `animateCopyToClipboard`
    private func hideCopyNotification(view: UIView) {
        UIView.animate(
            withDuration: 0.5,
            delay: 0.5,
            options: .curveEaseIn,
            animations: {
                view.backgroundColor = UIColor.actionTint
                view.alpha = 0.0
            },
            completion: {
                [weak self] finished in
                guard let _self = self else { return }
                view.removeFromSuperview()
                _self.tableView.allowsSelection = true
            }
        )
    }
}

extension ViewEntryFieldsVC: EntryChangeObserver {
    func entryDidChange(entry: Entry) {
        refresh()
    }
}

extension ViewEntryFieldsVC: UITableViewDragDelegate {
    func tableView(
        _ tableView: UITableView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
        ) -> [UIDragItem]
    {
        let fieldNumber = indexPath.row
        let field = sortedFields[fieldNumber]
        let data = field.value.data(using: .utf8)
        
        let itemProvider = NSItemProvider()
        itemProvider.registerDataRepresentation(
            forTypeIdentifier: kUTTypePlainText as String,
            visibility: .all)
        {
            (completion) in
            completion(data, nil)
            return nil
        }
        return [UIDragItem(itemProvider: itemProvider)]
    }
}

extension ViewEntryFieldsVC: ViewEntryFieldCellDelegate {
    func cellContentDidChange(cell: UITableViewCell) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}
