//
//  StringExtension.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-04-03.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

extension String {
    public var isNotEmpty: Bool { return !isEmpty }
    
    /// Intended to safely zero out and erase string's data.
    /// But likely not possible in practice: https://forums.developer.apple.com/thread/4879
    /// More: https://stackoverflow.com/questions/27715985/secure-memory-for-swift-objects
    mutating func erase() {
        self.removeAll()
    }
}
