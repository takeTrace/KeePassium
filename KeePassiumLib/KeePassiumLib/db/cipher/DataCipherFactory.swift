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

final class DataCipherFactory {
    public static let instance = DataCipherFactory()
    private let aes: AESDataCipher
    private let chacha20: ChaCha20DataCipher
    private let twofish: TwofishDataCipher
    private init() {
        aes = AESDataCipher()
        chacha20 = ChaCha20DataCipher()
        twofish = TwofishDataCipher()
    }
    
    public func createFor(uuid: UUID) -> DataCipher? {
        switch uuid {
        case aes.uuid:
            Diag.info("Creating AES cipher")
            return AESDataCipher()
        case chacha20.uuid:
            Diag.info("Creating ChaCha20 cipher")
            return ChaCha20DataCipher()
        case twofish.uuid:
            Diag.info("Creating Twofish cipher")
            return TwofishDataCipher()
        default:
            Diag.warning("Unrecognized cipher UUID")
            return nil
        }
    }
}
