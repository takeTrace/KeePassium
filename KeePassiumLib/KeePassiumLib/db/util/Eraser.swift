//
//  Eraser.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-02-26.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

final class Eraser {
    /// Fills the given array with zeros (does not change size)
    public static func erase(array: inout [UInt8]) {
        for i in 0..<array.count {
            array[i] = 0
        }
    }
    
    /// Erases each item separately and removes them from `array`.
    public static func erase<T: Eraseable>(_ array: inout [T]) {
        for item in array {
            item.erase()
        }
        array.removeAll()
    }
}




