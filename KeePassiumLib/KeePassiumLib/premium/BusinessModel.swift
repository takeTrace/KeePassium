//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation

/// Distinguishes whether the library is used in the freemium
/// or prepaid app, and switches some constants/features correspondingly.
public enum BusinessModel {

    /// Global framework-wide type of the used business model.
    /// Set this once, before using the library.
    public static var type: BusinessModel = .freemium

    case freemium
    case prepaid
}
