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
