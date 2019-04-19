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
import KeePassiumLib

class AboutVC: UITableViewController {
    @IBOutlet weak var contactSupportCell: UITableViewCell!
    @IBOutlet weak var writeReviewCell: UITableViewCell!
    @IBOutlet weak var debugInfoCell: UITableViewCell!
    
    static func make() -> UIViewController {
        let vc = AboutVC.instantiateFromStoryboard()
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let selectedCell = tableView.cellForRow(at: indexPath) else { return }
        switch selectedCell {
        case contactSupportCell:
            SupportEmailComposer.show(includeDiagnostics: false, completion: nil)
        case writeReviewCell:
            AppStoreReviewHelper.writeReview()
        case debugInfoCell:
            resetAutoFillCleanExitFlag()
        default:
            break
        } 
    }
    
    /// For user-side debug
    /// TODO: remove in release
    private func resetAutoFillCleanExitFlag() {
        Settings.current.isAutoFillFinishedOK = true
        refresh()
    }
    
    // TODO: remove in release
    private func refresh() {
        debugInfoCell.textLabel?.text = "AutoFill finished OK: \(Settings.current.isAutoFillFinishedOK)"
    }
}
