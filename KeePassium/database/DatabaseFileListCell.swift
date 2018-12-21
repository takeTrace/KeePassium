//
//  DatabaseFileListCell.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-12-07.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import KeePassiumLib

/// A cell in the database file list/table.
class DatabaseFileListCell: UITableViewCell {
    /// Reference to the database file
    var urlRef: URLReference! {
        didSet {
            setupCell()
        }
    }
    
    private func setupCell() {
        let fileInfo = urlRef.getInfo()
        textLabel?.text = fileInfo.fileName
        if fileInfo.hasError {
            detailTextLabel?.text = fileInfo.errorMessage
            detailTextLabel?.textColor = UIColor.errorMessage
            imageView?.image = UIImage(asset: .databaseErrorListitem)
        } else {
            imageView?.image = UIImage.databaseIcon(for: urlRef)
            if let modificationDate = fileInfo.modificationDate {
                let dateString = DateFormatter.localizedString(
                    from: modificationDate,
                    dateStyle: .long,
                    timeStyle: .medium)
                detailTextLabel?.text = dateString
            } else {
                detailTextLabel?.text = nil
            }
            detailTextLabel?.textColor = UIColor.auxiliaryText
        }
    }
}
