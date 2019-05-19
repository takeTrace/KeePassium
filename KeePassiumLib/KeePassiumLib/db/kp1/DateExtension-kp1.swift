//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation

/// Adds support for KP1-specific time format
extension Date {
    /// Bytes in KP1 packed binary time format.
    public static let kp1TimestampSize = 5

    //TODO: test if "Never" works
    /// Magic timestamp that is considered as "Never"
    /// (QDate(2999, 12, 28), QTime(23, 59, 59, 0), Qt::LocalTime)
    public static let kp1Never: Date = DateComponents(
        calendar: Calendar(identifier: .iso8601),
        year: 2999, month: 12, day: 28,
        hour: 23, minute: 59, second: 59, nanosecond: 0)
        .date! // ok to force-unwrap

    /// Inits a `Date` from the KeePass1 packed 5-byte array.
    init?(kp1Bytes dw: ByteArray) {
        guard dw.count == Date.kp1TimestampSize else {
            Diag.error("Wrong KP1 date size [got \(dw.count), expected \(Date.kp1TimestampSize) bytes]")
            assertionFailure("KeePass1 packed date format requires \(Date.kp1TimestampSize) bytes")
            return nil
        }
        let year = (Int(dw[0]) << 6) | (Int(dw[1]) >> 2)
        let month = ((Int(dw[1]) & 0x00000003) << 2) | (Int(dw[2]) >> 6)
        let day = (Int(dw[2]) >> 1) & 0x0000001F
        let hour = ((Int(dw[2]) & 0x00000001) << 4) | (Int(dw[3]) >> 4)
        let minute = ((Int(dw[3]) & 0x0000000F) << 2) | (Int(dw[4]) >> 6)
        let second = Int(dw[4]) & 0x0000003F
        
        guard let date = DateComponents(
            calendar: Calendar(identifier: .iso8601),
            year: year, month: month, day: day,
            hour: hour, minute: minute, second: second, nanosecond: 0).date else
        {
            Diag.warning("KP1 packed date is not valid")
            return nil
        }
        self = date
    }
    
    /// Converts the date into kp1-specific binary time format.
    /// - Returns: 5 bytes
    func asKP1Bytes() -> ByteArray {
        let cal = Calendar(identifier: .iso8601)
        let dc = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)

        // year remains an Int
        let year   = dc.year!
        let month  = UInt8(dc.month!)
        let day    = UInt8(dc.day!)
        let hour   = UInt8(dc.hour!)
        let minute = UInt8(dc.minute!)
        let second = UInt8(dc.second!)
        
        var bytes = Array<UInt8>(repeating: 0, count: 5)
        bytes[0] = UInt8(year >> 6) & 0x3F
        bytes[1] = (UInt8(year & 0x3F) << 2) | ((month >> 2) & 0x03)
        bytes[2] = ((month & 0x03) << 6) | ((day & 0x1F) << 1) | ((hour >> 4) & 0x01)
        bytes[3] = (hour & 0x0F) << 4 | ((minute >> 2) & 0x0F)
        bytes[4] = ((minute & 0x03) << 6) | (second & 0x3F)
        return ByteArray(bytes: bytes)
    }
}
