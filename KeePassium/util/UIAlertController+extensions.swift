//
//  UIAlertController+extensions.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-08-19.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    /// Creates a UIAlertController with a cancel button.
    /// If `cancelButtonTitle` is undefined, it defaults to 'Dismiss'.
    static func make(
        title: String?,
        message: String?,
        cancelButtonTitle: String? = nil
        ) -> UIAlertController
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(
            title: cancelButtonTitle ?? LString.actionDismiss,
            style: .cancel,
            handler: nil)
        alert.addAction(cancelAction)
        return alert
    }
}
