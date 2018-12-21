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
