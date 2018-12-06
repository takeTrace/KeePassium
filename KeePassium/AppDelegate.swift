//
//  AppDelegate.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-04-14.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

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
        AppLockManager.shared.maybeLock() // init AppLockManager (it subscribes to notifications)
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

