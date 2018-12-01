//
//  main.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-03.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit


_ = UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    NSStringFromClass(KPApplication.self), // custom app class
    NSStringFromClass(AppDelegate.self))   // custom delegate
