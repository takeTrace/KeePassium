//
//  UserDefaults+appGroupShared.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-10-01.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation

public extension UserDefaults {
    /// Instance shared across the app group.
    public static var appGroupShared: UserDefaults {
        guard let instance = UserDefaults(suiteName: AppGroup.id) else {
            fatalError("Failed to create app group user defaults.")
        }
        return instance
    }
}
