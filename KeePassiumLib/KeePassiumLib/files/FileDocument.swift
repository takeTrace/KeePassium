//
//  FileDocument.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-08-24.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

/// Generic document to access external files.
public class FileDocument: UIDocument {
    public var data = ByteArray()
    public private(set) var error: Error?
    public var hasError: Bool { return error != nil }
    
    public func open(successHandler: @escaping(() -> Void), errorHandler: @escaping((Error)->Void)) {
        super.open(completionHandler: { success in
            if success {
                self.error = nil
                successHandler()
            } else {
                errorHandler(self.error!)
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
