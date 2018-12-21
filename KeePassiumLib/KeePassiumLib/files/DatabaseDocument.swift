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

public class DatabaseDocument: UIDocument {
    var encryptedData = ByteArray()
    var database: Database?
    var errorMessage: String?
    var hasError: Bool { return errorMessage != nil }
    
    public func open(successHandler: @escaping(() -> Void), errorHandler: @escaping((String?)->Void)) {
        super.open(completionHandler: { success in
            if success {
                self.errorMessage = nil
                successHandler()
            } else {
                errorHandler(self.errorMessage)
            }
        })
    }
    
    public func save(successHandler: @escaping(() -> Void), errorHandler: @escaping((String?)->Void)) {
        super.save(to: fileURL, for: .forOverwriting, completionHandler: { success in
            if success {
                self.errorMessage = nil
                successHandler()
            } else {
                errorHandler(self.errorMessage)
            }
        })
    }
    
    public func close(successHandler: @escaping(() -> Void), errorHandler: @escaping((String?)->Void)) {
        super.close(completionHandler: { success in
            if success {
                self.errorMessage = nil
                successHandler()
            } else {
                errorHandler(self.errorMessage)
            }
        })
    }
    
    override public func contents(forType typeName: String) throws -> Any {
        errorMessage = nil
        return encryptedData.asData
    }
    
    override public func load(fromContents contents: Any, ofType typeName: String?) throws {
        assert(contents is Data)
        errorMessage = nil
        if let contents = contents as? Data {
            encryptedData = ByteArray(data: contents)
        } else {
            encryptedData = ByteArray()
        }
    }
    
    override public func handleError(_ error: Error, userInteractionPermitted: Bool) {
        errorMessage = error.localizedDescription
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
    }
}
