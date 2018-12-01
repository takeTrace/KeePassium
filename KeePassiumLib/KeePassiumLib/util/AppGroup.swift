//
//  AppGroup.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-10-01.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

public class AppGroup {
    /// App Group identifier string.
    public static let id = "group.com.keepassium"
    
    // True when running in main app, false for app extensions.
    public static var isMainApp: Bool {
        return applicationShared != nil
    }
    
    // In main app: same as UIApplication.shared (must be manually set on launch)
    // In app extension: nil
    public static weak var applicationShared: UIApplication?
}
