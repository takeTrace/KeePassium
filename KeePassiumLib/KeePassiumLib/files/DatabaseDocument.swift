//
//  DatabaseDocument.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-08-24.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

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
