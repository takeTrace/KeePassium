//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit
import KeePassiumLib

class SettingsAutoFillVC: UITableViewController {

    @IBOutlet weak var copyTOTPSwitch: UISwitch!
    
    // MARK: - VC life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    func refresh() {
        copyTOTPSwitch.isOn = Settings.current.isCopyTOTPOnAutoFill
    }
    
    // MARK: - Actions
    
    @IBAction func didToggleCopyTOTP(_ sender: UISwitch) {
        Settings.current.isCopyTOTPOnAutoFill = copyTOTPSwitch.isOn
        refresh()
    }
}
