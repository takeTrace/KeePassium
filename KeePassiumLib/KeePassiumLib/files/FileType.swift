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

public enum FileType {
    public static let databaseUTIs = [
        "com.keepassium.kdb", "com.keepassium.kdbx",
        "com.jflan.MiniKeePass.kdb", "com.jflan.MiniKeePass.kdbx",
        "com.kptouch.kdb", "com.kptouch.kdbx",
        "com.markmcguill.strongbox.kdb",
        "com.markmcguill.strongbox.kdbx",
        "be.kyuran.kypass.kdb"]
    
    public static let keyFileUTIs =
        ["com.keepassium.keyfile", "public.data", "public.content"]
    
    public static let databaseExtensions = ["kdb", "kdbx"]
    //public static let keyFileExtensions = anything except database
    
    case database
    case keyFile

    init(for url: URL) {
        if FileType.databaseExtensions.contains(url.pathExtension) {
            self = .database
        } else {
            self = .keyFile
        }
    }

    /// `true` if the `url` has a KeePass database extension
    public static func isDatabaseFile(url: URL) -> Bool {
        return databaseExtensions.contains(url.pathExtension)
    }
}
