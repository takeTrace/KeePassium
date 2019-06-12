//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation

public extension Date {
    /// A readability-improving wrapper for `Date()`
    static var now: Date { return Date() }
    
    /// Cached instance of date formatter, for better performance.
    private static let iso8601DateFormatter = { () -> DateFormatter in
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }()
    
    /// Number of seconds between 0001-01-01 00:00 and 2001-01-01 00:00,
    /// in .NET context (Swift thinks there are 2 days less)
    static internal let secondsBetweenSwiftAndDotNetReferenceDates = Int64(63113904000)

    /// Creates date from an ISO8601-formatted string.
    init?(iso8601string string: String?) {
        guard let string = string else { return nil }
        if let date = Date.iso8601DateFormatter.date(from:string) {
            self = date
        } else {
            return nil
        }
    }
    
    /// Creates date from a base-64 encoded Int64 of seconds
    /// since `Date.dotNetTimeZero` (KP2v4)
    init?(base64Encoded string: String?) {
        guard let data = ByteArray(base64Encoded: string) else { return nil }
        guard let secondsSinceDotNetReferenceDate = Int64(data: data) else { return nil }
        let secondsSinceSwiftReferenceDate =
            secondsSinceDotNetReferenceDate - Date.secondsBetweenSwiftAndDotNetReferenceDates
        self = Date(timeIntervalSinceReferenceDate: Double(secondsSinceSwiftReferenceDate))
    }
    
    /// Returns the date as an ISO8601-formatted string
    func iso8601String() -> String {
        return ISO8601DateFormatter().string(from: self)
    }
    
    /// Returns the date as Base64-encoded UInt64 of seconds since
    /// `Date.dotNetTimeZero` (KP2v4)
    func base64EncodedString() -> String {
        let secondsSinceSwiftReferenceDate = Int64(self.timeIntervalSinceReferenceDate)
        let secondsSinceDotNetReferenceDate =
            secondsSinceSwiftReferenceDate + Date.secondsBetweenSwiftAndDotNetReferenceDates
        return secondsSinceDotNetReferenceDate.data.base64EncodedString()
    }
}
