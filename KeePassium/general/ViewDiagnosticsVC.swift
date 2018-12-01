//
//  ViewDiagnosticsVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-08-09.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

class DiagItemCell: UITableViewCell {
    fileprivate static let storyboardID = "DiagItemCell"
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var levelImage: UIImageView!
    
    func fillData(from item: Diag.Item) {
        placeLabel?.text = "\(item.file):\(item.line)\n\(item.function)"
        messageLabel?.text = item.message
        levelImage.image = UIImage(named: item.level.imageName)
    }
}

extension Diag.Level {
    var imageName: String {
        switch self {
        case .verbose:
            return "diag-level-verbose"
        case .debug:
            return "diag-level-debug"
        case .info:
            return "diag-level-info"
        case .warning:
            return "diag-level-warning"
        case .error:
            return "diag-level-error"
        }
    }
}

/// Diagnostic info viewer
class ViewDiagnosticsVC: UITableViewController {
    @IBOutlet private weak var textView: UITextView!
    private var items: [Diag.Item] = []
    
    static func make() -> UIViewController {
        let vc = ViewDiagnosticsVC.instantiateFromStoryboard()
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .formSheet
        return navVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        items = Diag.itemsSnapshot()
        tableView.reloadData()
    }
    
    // MARK: Actions
    @IBAction func didPressCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressCompose(_ sender: Any) {
        SupportEmailComposer.show(includeDiagnostics: true) {
            [weak self] (success) in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: Table data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell
    {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DiagItemCell.storyboardID,
            for: indexPath)
            as! DiagItemCell
        cell.fillData(from: item)
        return cell
    }
}

