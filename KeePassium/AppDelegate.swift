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
import KeePassiumLib

//@UIApplicationMain - replaced by main.swift to subclass UIApplication
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool
    {
        AppGroup.applicationShared = application
        let _ = Watchdog.shared // init Watchdog
        return true
    }
    
    func application(
        _ application: UIApplication,
        open inputURL: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
        ) -> Bool
    {
        AppGroup.applicationShared = application
        let isOpenInPlace = (options[.openInPlace] as? Bool) ?? false

        Diag.info("Opened with URL: \(inputURL.redacted) [inPlace: \(isOpenInPlace)]")
        
        // By now, we might not have the UI to show import progress or errors.
        // So defer the operation until there is UI.
        FileKeeper.shared.prepareToAddFile(
            url: inputURL,
            mode: isOpenInPlace ? .openInPlace : .import)
        
        DatabaseManager.shared.closeDatabase(clearStoredKey: false)
        return true
    }
    
}
