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

import UIKit

/// Generic document to access external files.
public class FileDocument: UIDocument {
    public enum InternalError: LocalizedError {
        case generic
        public var errorDescription: String? {
            return NSLocalizedString("Unexpected file error, please contact us.", comment: "A very generic error message")
        }
    }
    
    public var data = ByteArray()
    public private(set) var error: Error?
    public var hasError: Bool { return error != nil }
    
    public func open(successHandler: @escaping(() -> Void), errorHandler: @escaping((Error)->Void)) {
        super.open(completionHandler: { success in
            if success {
                self.error = nil
                successHandler()
            } else {
                guard let error = self.error else {
                    // This should not happen, but might. So we'll gracefully throw
                    // a generic error instead of crashing on force-unwrap.
                    assertionFailure()
                    errorHandler(FileDocument.InternalError.generic)
                    return
                }
                errorHandler(error)
            }
        })
    }
    
    override public func contents(forType typeName: String) throws -> Any {
        error = nil
        return data.asData
    }
    
    override public func load(fromContents contents: Any, ofType typeName: String?) throws {
        assert(contents is Data)
        error = nil
        if let contents = contents as? Data {
            data = ByteArray(data: contents)
        } else {
            data = ByteArray()
        }
    }
    
    override public func handleError(_ error: Error, userInteractionPermitted: Bool) {
        self.error = error
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
    }
}
