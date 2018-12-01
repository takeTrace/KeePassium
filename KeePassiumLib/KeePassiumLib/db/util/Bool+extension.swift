//
//  Bool+extension.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-04-03.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

extension Bool {
    /// Correctly parses mixed-case "TRuE"/"FaLsE" strings, everything else means `nil`
    init?(optString value: String?) {
        guard let value = value else {
            return nil
        }
        
        switch value.lowercased() {
        case "true":
            self = true
        case "false":
            self = false
        default:
            return nil
        }
    }
    /// Correctly parses mixed-case "true", any other string means `false`.
    init(string: String) {
        if string.lowercased() == "true" {
            self = true
        } else {
            self = false
        }
    }
    /// Correctly parses mixed-case "true", any other string or `nil` means `false`.
    init(string: String?) {
        self.init(string: string ?? "")
    }
}
