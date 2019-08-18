//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation

public enum CryptoError: LocalizedError {
    case invalidKDFParam(kdfName: String, paramName: String)
    case paddingError(code: Int)
    case aesInitError(code: Int)
    case aesEncryptError(code: Int)
    case aesDecryptError(code: Int)
    case argon2Error(code: Int)
    case twofishError(code: Int)
    case rngError(code: Int)
    public var errorDescription: String? {
        switch self {
        case .invalidKDFParam(let kdfName, let paramName):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid KDF parameter: %@ - %@. File corrupt?",
                    comment: "Error message about key derivation function (KDF) parameters. [kdfName: String, paramName: String]"),
                [kdfName, paramName])
        case .paddingError(let code):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid data padding (code %d). File corrupt?",
                    comment: "Error message about PKCS7 padding. [errorCode: Int]"),
                [code])
        case .aesInitError(let code):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "AES initialization error (code %d)",
                    comment: "Error message about AES cipher. [errorCode: Int]"),
                [code])
        case .aesEncryptError(let code):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "AES encryption error (code %d)",
                    comment: "Error message about AES cipher. [errorCode: Int]"),
                [code])
        case .aesDecryptError(let code):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "AES decryption error (code %d)",
                    comment: "Error message about AES cipher. [errorCode: Int]"),
                [code])
        case .argon2Error(let code):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Argon2 hashing error (code %d)",
                    comment: "Error message about Argon2 hashing function. [errorCode: Int]"),
                [code])
        case .twofishError(let code):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Twofish cipher error (code %d)",
                    comment: "Error message about Twofish cipher. [errorCode: Int]"),
                [code])
        case .rngError(let code):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Random number generator error (code %d)",
                    comment: "Error message about random number generator. [errorCode: Int]"),
                [code])
        }
    }
}
