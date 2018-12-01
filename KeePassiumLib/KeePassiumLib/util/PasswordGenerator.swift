//
//  PasswordGenerator.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-09-12.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

/// Generates randor passwords with given parameters.
public class PasswordGenerator {
    /// Default length for generated passwords
    public static let defaultLength = 20
    
    public static let charSetLower: Set<String> = [
        "a","b","c","d","e","f","g","h","i","j","k","l","m",
        "n","o","p","q","r","s","t","u","v","w","x","y","z"]
    public static let charSetUpper: Set<String> = [
        "A","B","C","D","E","F","G","H","I","J","K","L","M",
        "N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    public static let charSetDigits: Set<String> =
        ["0","1","2","3","4","5","6","7","8","9"]
    public static let charSetSpecials: Set<String> = [
        "`","~","!","@","#","$","%","^","&","*","_","+","(",")","[","]",
        "{","}","<",">","\\","|",":",";",",",".","?","/","'","\""]
    public static let charSetLookAlike: Set<String> =
        ["I","l","|","1","0","O","S","5"]
    
    public enum Parameters {
        case includeLowerCase
        case includeUpperCase
        case includeSpecials
        case includeDigits
        case includeLookAlike
    }
    
    /// - Throws: CryptoManager.rngError
    public static func generate(length: Int, parameters: Set<Parameters>) throws -> String {
        var charSet: Set<String> = []
        if parameters.contains(.includeLowerCase) {
            charSet.formUnion(charSetLower)
        }
        if parameters.contains(.includeUpperCase) {
            charSet.formUnion(charSetUpper)
        }
        if parameters.contains(.includeSpecials) {
            charSet.formUnion(charSetSpecials)
        }
        if parameters.contains(.includeDigits) {
            charSet.formUnion(charSetDigits)
        }
        if !parameters.contains(.includeLookAlike) {
            charSet.subtract(charSetLookAlike)
        }
        
        assert(charSet.count < 0xFF, "charSet has more than 256 entries, password generation will be suboptimal")
        let charSetArray = charSet.sorted()
        
        let randomSeq = try CryptoManager.getRandomBytes(count: length) // throws CryptoManager.rngError
        let randomBytes = randomSeq.bytesCopy()
        
        var password: [String] = []
        for byte in randomBytes {
            password.append(charSetArray[Int(byte) % charSet.count])
        }
        return password.joined()
    }
}
