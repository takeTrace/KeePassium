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

/// Protocol for key derivation functions
protocol KeyDerivationFunction {
    /// Predefined UUID of this KDF
    var uuid: UUID { get }
    /// Human-readable KDF name
    var name: String { get }
    /// A `KDFParams` instance prefilled with some reasonable default values
    var defaultParams: KDFParams { get }
    
    /// Returns a fresh instance of key derivation progress
    func initProgress() -> Progress

    init()
    
    /// Performs key transformation using given params.
    /// - Throws: CryptoError, ProgressInterruption
    /// - Returns: resulting key
    func transform(key: SecureByteArray, params: KDFParams) throws -> SecureByteArray
    
    /// Randomize KDF parameters (before saving the DB)
    /// - Throws: CryptoError.rngError
    func randomize(params: inout KDFParams) throws
}

/// Creates a KDF instance by its UUID.
final class KDFFactory {
    private static let argon2kdf = Argon2KDF()
    private static let aeskdf = AESKDF()

    private init() {
        // nothing to do here
    }
    
    /// - Returns: a suitable KDF instance, or `nil` for unknown UUID.
    public static func createFor(uuid: UUID) -> KeyDerivationFunction? {
        switch uuid {
        case argon2kdf.uuid:
            Diag.info("Creating Argon2 KDF")
            return Argon2KDF()
        case aeskdf.uuid:
            Diag.info("Creating AES KDF")
            return AESKDF()
        default:
            Diag.warning("Unrecognized KDF UUID")
            return nil
        }
    }
}
