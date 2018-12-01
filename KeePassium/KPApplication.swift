//
//  KPApplication.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-03.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

/// UIApplication subclass to keep track of user inactivity.
class KPApplication: UIApplication {
    
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        
        // Reset watchdog whenever anything is touched
        guard let allTouches = event.allTouches else { return }
        for touch in allTouches where touch.phase == .began {
            Watchdog.default.restart()
            break
        }
    }
}
