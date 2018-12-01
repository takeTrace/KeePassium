//
//  String+extensions.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-08-19.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

extension String {
    
    /// `true` if the string looks like a URL and can be opened by this application.
    var isOpenableURL: Bool {
        guard let url = URL(string: self) else {
            return false
        }
        guard url.scheme != nil else {
            return false
        }
        guard UIApplication.shared.canOpenURL(url) else {
            return false
        }
        return true
    }
}
