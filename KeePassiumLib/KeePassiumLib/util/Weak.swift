//
//  Weak.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-02.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

// Weak wrapper for arrays of weak references
public class Weak<T: AnyObject> {
    public weak var value: T?
    public init(_ value: T) {
        self.value = value
    }
}
