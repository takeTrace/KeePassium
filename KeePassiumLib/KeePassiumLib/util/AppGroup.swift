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
