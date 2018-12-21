//  KeePassium Password Manager
//  Copyright © 2018 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
