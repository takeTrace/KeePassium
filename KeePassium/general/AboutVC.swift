//
//  AboutVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-09-10.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

class AboutVC: UITableViewController {
    @IBOutlet weak var contactSupportCell: UITableViewCell!
    @IBOutlet weak var writeReviewCell: UITableViewCell!
    
    static func make() -> UIViewController {
        let vc = AboutVC.instantiateFromStoryboard()
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let selectedCell = tableView.cellForRow(at: indexPath) else { return }
        switch selectedCell {
        case contactSupportCell:
            SupportEmailComposer.show(includeDiagnostics: false, completion: nil)
        case writeReviewCell:
            AppStoreReviewHelper.writeReview()
        default:
            break
        } 
    }
}
