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

public extension Date {
    /// A readability-improving wrapper for `Date()`
    public static var now: Date { return Date() }
    
    /// .NET's DateTime reference date: January 1, 0001 at 00:00:00.000 in the Gregorian calendar.
    static internal let dotNetTimeZero = DateComponents(
        calendar: Calendar(identifier: .gregorian),
        timeZone: TimeZone(abbreviation: "UTC"),
        year: 1, month: 1, day: 1,
        hour: 0, minute: 0, second: 0, nanosecond: 0
        ).date!

    /// Creates date from an ISO8601-formatted string.
    init?(iso8601string string: String?) {
        guard let string = string else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = dateFormatter.date(from:string) {
            self = date
        } else {
            return nil
        }
    }
    
    /// Creates date from a base-64 encoded Int64 of seconds
    /// since `Date.dotNetTimeZero` (KP2v4)
    init?(base64Encoded string: String?) {
        guard let data = ByteArray(base64Encoded: string) else { return nil }
        guard let seconds = Int64(data: data) else { return nil }
        self = Date(timeInterval: Double(seconds), since: Date.dotNetTimeZero)
    }
    
    /// Returns the date as an ISO8601-formatted string
    public func iso8601String() -> String {
        return ISO8601DateFormatter().string(from: self)
    }
    
    /// Returns the date as Base64-encoded UInt64 of seconds since
    /// `Date.dotNetTimeZero` (KP2v4)
    public func base64EncodedString() -> String {
        let secondsSinceRef = Int64(self.timeIntervalSince(Date.dotNetTimeZero))
        return secondsSinceRef.data.base64EncodedString()
    }
}
