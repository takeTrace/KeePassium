//
//  TOTPHelper.swift
//  KeePassiumLib
//
//  Created by Andrei Popleteev on 2019-03-11.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import Foundation

open class TOTPGeneratorFactory {
    
    /// Parses given TOTP parameters and returns a suitable instance of
    /// `TOTPGenerator` (or `nil` if failed to parse parameters)
    ///
    /// - Parameters:
    ///   - seed: string with TOTP secret/seed
    ///   - settings: other TOTP settings, such as time step and number of digits
    /// - Returns: initialized `TOTPGenerator` instance defined by the settings.
    public static func makeGenerator(
        seed seedString: String,
        settings settingsString: String
    ) -> TOTPGenerator? {
        guard let seed = parseSeedString(seedString) else {
            Diag.warning("Unrecognized TOTP seed format")
            return nil
        }
        
        let settings = settingsString.split(separator: ";")
        guard settings.count == 2 else {
            Diag.warning("Unexpected TOTP settings number [expected: 2, got: \(settings.count)]")
            return nil
        }
        guard let timeStep = Int(settings[0]) else {
            Diag.warning("Failed to parse TOTP time step as Int")
            return nil
        }
        guard timeStep > 0 else {
            Diag.warning("Invalid TOTP time step value: \(timeStep)")
            return nil
        }
        
        if let length = Int(settings[1]) {
            return TOTPGeneratorRFC6238(seed: seed, timeStep: timeStep, length: length)
        } else if settings[1] == TOTPGeneratorSteam.typeSymbol {
            return TOTPGeneratorSteam(seed: seed, timeStep: timeStep)
        } else {
            Diag.warning("Unexpected TOTP size or type: '\(settings[1])'")
            return nil
        }
    }
    
    static func parseSeedString(_ seedString: String) -> ByteArray? {
        let trimmedSeed = seedString.replacingOccurrences(of: "=", with: "")
        if let seedData = base32DecodeToData(trimmedSeed) {
            return ByteArray(data: seedData)
        }
        if let seedData = base32HexDecodeToData(trimmedSeed) {
            return ByteArray(data: seedData)
        }
        if let seedData = Data(base64Encoded: trimmedSeed) {
            return ByteArray(data: seedData)
        }
        return nil
    }
}

public protocol TOTPGenerator: class {
    /// Fraction of TOTP's timeStep elapsed: `(now - timeOfGeneration) / timeStep`
    /// Increases from 0.0 to 1.0, then resets to zero.
    var elapsedTimeFraction: Double { get }
    
    /// Returns TOTP value for current time
    func generate() -> String
}

public class TOTPGeneratorRFC6238: TOTPGenerator {
    private let seed: ByteArray
    private let timeStep: Int
    private let length: Int
    
    fileprivate init?(seed: ByteArray, timeStep: Int, length: Int) {
        guard length >= 4 && length <= 8 else { return nil }
        
        self.seed = seed
        self.timeStep = timeStep
        self.length = length
    }

    public var elapsedTimeFraction: Double {
        //TODO
        return 0
    }
    
    public func generate() -> String {
        let counter = UInt64(floor(Date.now.timeIntervalSince1970 / Double(timeStep))).bigEndian
        let counterBytes = counter.bytes
        
        let hmac = CryptoManager.hmacSHA1(data: ByteArray(bytes: counterBytes), key: seed)
        let fullCode = hmac.withBytes { (hmacBytes) -> UInt32 in
            let startPos = Int(hmacBytes[hmacBytes.count - 1] & 0x0F)
            let hmacBytesSlice = ByteArray(bytes: hmacBytes[startPos..<(startPos+4)])
            let code = UInt32(data: hmacBytesSlice)!.byteSwapped
            return code & 0x7FFFFFFF
        }
        let power = Int(pow(Double(10), Double(length)))
        let trimmedCode = Int(fullCode) % power
        return String(format: "%0.\(length)d", arguments: [trimmedCode])
    }
}


public class TOTPGeneratorSteam: TOTPGenerator {
    public static let typeSymbol = "S"
    private let steamChars = [
        "2","3","4","5","6","7","8","9","B","C","D","F","G",
        "H","J","K","M","N","P","Q","R","T","V","W","X","Y"]

    private let seed: ByteArray
    private let timeStep: Int
    private let length = 5
    
    fileprivate init?(seed: ByteArray, timeStep: Int) {
        self.seed = seed
        self.timeStep = timeStep
    }

    public var elapsedTimeFraction: Double {
        return 0 // TODO
    }
    
    ///TODO: WRONG RESULTS
    public func generate() -> String {
        let counter = UInt64(floor(Date.now.timeIntervalSince1970 / Double(timeStep))).bigEndian
        let counterBytes = counter.bytes
        
        let hmac = CryptoManager.hmacSHA1(data: ByteArray(bytes: counterBytes), key: seed)
        let fullCode = hmac.withBytes { (hmacBytes) -> UInt32 in
            let startPos = Int(hmacBytes[hmacBytes.count - 1] & 0x0F)
            let hmacBytesSlice = ByteArray(bytes: hmacBytes[startPos..<(startPos+4)])
            let code = UInt32(data: hmacBytesSlice)!.byteSwapped
            return code & 0x7FFFFFFF
        }

        var code = Int(fullCode)
        var result = [String]()
        for _ in 0..<length {
            let index = code % steamChars.count
            result.append(steamChars[index])
            code /= steamChars.count
        }
        return result.joined()
    }
}
