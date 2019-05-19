//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation

// Weak wrapper for arrays of weak references
public class Weak<T: AnyObject> {
    public weak var value: T?
    public init(_ value: T) {
        self.value = value
    }
    
    /// Converts an array of strong references into array of weak references.
    public static func wrapped(_ array: [T]) -> [Weak<T>] {
        return array.map { Weak($0) }
    }
    
    /// Converts an array of weak references into array of strong references.
    public static func unwrapped(_ array: [Weak<T>]) -> [T] {
        var result = [T]()
        array.forEach {
            if let value = $0.value {
                result.append(value)
            }
        }
        return result
    }
}
