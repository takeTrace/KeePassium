//
//  WatchdogAwareTextField.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-14.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

/// UITextField which restarts the watchdog when edited.
class WatchdogAwareTextField: UITextField {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addTarget(self, action: #selector(onEditingChanged), for: .editingChanged)
    }
    
    @objc
    func onEditingChanged(textField: UITextField) {
        Watchdog.default.restart()
    }
}
