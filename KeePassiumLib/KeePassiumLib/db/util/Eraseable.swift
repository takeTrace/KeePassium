//
//  Eraseable.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-08.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

public protocol Eraseable {
    /// Erases property values from memory whenever possible (e.g. fills with zeros).
    /// Recursively erases and removes elements from collections.
    func erase()
}

public protocol EraseableStruct {
    /// Erases property values from memory whenever possible (e.g. fills with zeros).
    /// Recursively erases and removes elements from collections.
    mutating func erase()
}

extension Array where Element: EraseableStruct {
    /// Recursively erases each element, then removes them all
    mutating func erase() {
        for i in 0..<count {
            self[i].erase()
        }
        removeAll()
    }
}

extension Array where Element: Eraseable {
    /// Recursively erases each element, then removes them all
    mutating func erase() {
        for i in 0..<count {
            self[i].erase()
        }
        removeAll()
    }
}

//extension Array {
//    /// Recursively erases each element, then removes them all
//    func erase<T:Eraseable>(_ array: inout Array<T>) {
//        for i in 0..<count {
//            array[i].erase()
//        }
//        array.removeAll()
//    }
//}

extension Dictionary where Key: Eraseable, Value: Eraseable {
    mutating func erase() {
        forEach({ (key, value) in
            key.erase()
            value.erase()
        })
        removeAll()
    }
}
extension Dictionary where Value: Eraseable {
    mutating func erase() {
        forEach({ (key, value) in
            value.erase()
        })
        removeAll()
    }
}
