//
//  DiagnosticsViewerVC.swift
//  KeePassium AutoFill
//
//  Created by Andrei Popleteev on 2018-12-18.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import KeePassiumLib

class DiagnosticsViewerCell: UITableViewCell {
    static let storyboardID = "DiagnosticsViewerCell"
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var levelImage: UIImageView!
    
    func setDiagItem(_ item: Diag.Item) {
        placeLabel?.text = "\(item.file):\(item.line)\n\(item.function)"
        messageLabel?.text = item.message
        levelImage.image = imageForLevel(item.level)
    }
    
    func imageForLevel(_ level: Diag.Level) -> UIImage? {
        switch level {
        case .verbose:
            return UIImage(named: "diag-level-verbose")
        case .debug:
            return UIImage(named: "diag-level-debug")
        case .info:
            return UIImage(named: "diag-level-info")
        case .warning:
            return UIImage(named: "diag-level-warning")
        case .error:
            return UIImage(named: "diag-level-error")
        }
    }
}

protocol DiagnosticsViewerDelegate: class {
    func diagnosticsViewer(_ sender: DiagnosticsViewerVC, didCopyContents text: String)
}

class DiagnosticsViewerVC: UITableViewController {
    private var items: [Diag.Item] = []

    @IBOutlet weak var composeButton: UIBarButtonItem!
    @IBOutlet weak var copyButton: UIBarButtonItem!
    
    weak var delegate: DiagnosticsViewerDelegate?
    
    override func viewDidLoad() {
        tableView.rowHeight = UITableView.automaticDimension
        items = Diag.itemsSnapshot()
        super.viewDidLoad()
    }
    
    // MARK: - Actions
    
    @IBAction func didPressCopy(_ sender: Any) {
        let logText = Diag.toString()
        delegate?.diagnosticsViewer(self, didCopyContents: logText)
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
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DiagnosticsViewerCell.storyboardID,
            for: indexPath)
            as! DiagnosticsViewerCell
        cell.setDiagItem(items[indexPath.row])
        return cell
    }
}
