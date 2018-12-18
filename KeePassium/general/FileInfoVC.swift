//
//  FileInfoVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-11-27.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

class FileInfoCell: UITableViewCell {
    static let storyboardID = "FileInfoCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    var name: String? {
        didSet {
            nameLabel.text = name
        }
    }
    var value: String? {
        didSet {
            valueLabel.text = value
        }
    }
}

class FileInfoVC: UITableViewController {
    private var fields = [(String, String)]()
    
    /// - Parameters:
    ///   - urlRef: reference to the file
    ///   - popoverSource: optional, use `nil` for non-popover presentation
    public static func make(urlRef: URLReference, popoverSource: UIView?) -> FileInfoVC {
        let vc = FileInfoVC.instantiateFromStoryboard()
        vc.setupFields(urlRef: urlRef)
        
        if let popoverSource = popoverSource {
            vc.modalPresentationStyle = .popover
            if let popover = vc.popoverPresentationController {
                popover.sourceView = popoverSource
                popover.sourceRect = popoverSource.bounds
                popover.permittedArrowDirections = [.left]
                popover.delegate = vc
            }
        }
        return vc
    }
    
    private func setupFields(urlRef: URLReference) {
        fields.append((
            NSLocalizedString("File Name", comment: ""),
            urlRef.info.fileName
        ))
        fields.append((
            NSLocalizedString("File Location", comment: ""),
            urlRef.location.description
        ))
        if let errorMessage = urlRef.info.errorMessage {
            fields.append((
                NSLocalizedString("Error", comment: "Title of a field with an error message"),
                errorMessage
            ))
        }
        if let creationDate = urlRef.info.creationDate {
            fields.append((
                NSLocalizedString("Creation Date", comment: ""),
                DateFormatter.localizedString(
                    from: creationDate,
                    dateStyle: .medium,
                    timeStyle: .medium)
            ))
        }
        if let modificationDate = urlRef.info.modificationDate {
            fields.append((
                NSLocalizedString("Last Modification Date", comment: ""),
                DateFormatter.localizedString(
                    from: modificationDate,
                    dateStyle: .medium,
                    timeStyle: .medium)
            ))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // automatic popover height
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        tableView.removeObserver(self, forKeyPath: "contentSize")
        super.viewDidDisappear(animated)
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?)
    {
        // adjust popover height to fit table content
        preferredContentSize = tableView.contentSize
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fields.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: FileInfoCell.storyboardID,
            for: indexPath)
            as! FileInfoCell
        
        let fieldIndex = indexPath.row
        cell.name = fields[fieldIndex].0
        cell.value = fields[fieldIndex].1
        return cell
    }
}

extension FileInfoVC: UIPopoverPresentationControllerDelegate {
    func presentationController(
        _ controller: UIPresentationController,
        viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle
        ) -> UIViewController?
    {
        let navVC = UINavigationController(rootViewController: controller.presentedViewController)
        if style != .popover {
            let doneButton = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(dismissPopover))
            navVC.topViewController?.navigationItem.rightBarButtonItem = doneButton
        }
        return navVC
    }
    
    @objc
    private func dismissPopover() {
        dismiss(animated: true, completion: nil)
    }
}
