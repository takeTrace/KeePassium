//
//  ProgressInterruption.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-09.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

/// An exception thrown when a long-running operation is interrupted (for example, by the user).
public enum ProgressInterruption: LocalizedError {
    case cancelledByUser() // the user pressed "cancel"
    
    public var errorDescription: String? {
        switch self {
        case .cancelledByUser():
            return NSLocalizedString("Cancelled by user", comment: "Error message when a long-running operation is cancelled by user")
        }
    }
}
