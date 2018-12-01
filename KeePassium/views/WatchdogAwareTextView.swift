//
//  WatchdogAwareTextView.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-24.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

/// UITextView which restarts the watchdog when edited.
class WatchdogAwareTextView: UITextView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onTextChanged),
            name: UITextView.textDidChangeNotification,
            object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self, name: UITextView.textDidChangeNotification, object: nil)
    }
    
    @objc
    func onTextChanged() {
        Watchdog.default.restart()
    }
}
