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

/// Creates a file URL in app's `tmp` directory,
/// and removes the file on `deinit`.
public class TemporaryFileURL {
    public private(set) var url: URL
    
    public init(fileName: String) throws {
        let fileManager = FileManager.default
        let tmpFileDir = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        url = tmpFileDir.appendingPathComponent(fileName, isDirectory: false)
        do {
            try fileManager.createDirectory(
                at: tmpFileDir,
                withIntermediateDirectories: true,
                attributes: nil)
        } catch {
            Diag.error("Failed to create temporary file [error: \(error.localizedDescription)]")
            throw error
        }
    }
    
    deinit {
        cleanup()
    }
    
    private func cleanup() {
        Diag.verbose("Will remove temporary file")
        try? FileManager.default.removeItem(at: url)
        Diag.debug("Temporary file removed")
    }
}
