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

class Watchdog {
    public static let `default` = Watchdog()
    
    public enum Notifications {
        /// Notification name for watchdog timeout
        public static let appLockTimeout = Notification.Name("com.keepassium.Watchdog.appLockTimeout")
        public static let databaseCloseTimeout = Notification.Name("com.keepassium.Watchdog.databaseCloseTimeout")
    }
    
    /// Returns `true` *once* after the database timeout was triggered.
    /// After the first call, resets back to `false`.
    public var isDatabaseTimeoutExpired: Bool {
        if _isDatabaseTimeoutExpired {
           _isDatabaseTimeoutExpired = false
            return true
        } else {
            return false
        }
    }
    private var _isDatabaseTimeoutExpired = false
    
    private var appDeadline: Date?
    private var databaseDeadline: Date?
    private var appTimer: Timer?
    private var databaseTimer: Timer?

    init() {
        // left empty
    }
    
    func restart() {
        restartAppTimer()
        restartDatabaseTimer()
    }

    func restartAppTimer() {
        if let timer = appTimer {
            timer.invalidate()
        }
        
        let timeout = Settings.current.appLockTimeout
        Diag.verbose("App Lock timeout: \(timeout.seconds)")
        switch timeout {
        case .never: // watchdog disabled
            return
        case .immediately: // handled in `appWillResignActive`
            // Not setting a timer, only a deadline sufficient for the app to return to foreground
            appDeadline = Date(timeIntervalSinceNow: Double(1.0))
            return
        default:
            // actual timer delay, process further
            appDeadline = Date(timeIntervalSinceNow: Double(timeout.seconds))
            appTimer = Timer.scheduledTimer(
                timeInterval: Double(timeout.seconds),
                target: self,
                selector: #selector(appDidTimeout),
                userInfo: nil,
                repeats: false)
        }
    }

    func restartDatabaseTimer() {
        if let timer = databaseTimer {
            timer.invalidate()
        }
        
        let timeout = Settings.current.databaseCloseTimeout
        Diag.verbose("Database Lock timeout: \(timeout.seconds)")
        switch timeout {
        case .never: // watchdog disabled
            return
        case .immediately: // handled in `appWillResignActive`
            return
        default:
            // actual timer delay, process further
            databaseDeadline = Date(timeIntervalSinceNow: Double(timeout.seconds))
            databaseTimer = Timer.scheduledTimer(
                timeInterval: Double(timeout.seconds),
                target: self,
                selector: #selector(databaseDidTimeout),
                userInfo: nil,
                repeats: false)
        }
    }

    @objc private func appDidTimeout() {
        Diag.debug("Watchdog: App Lock timeout")
        triggerApp()
    }
    
    @objc private func databaseDidTimeout() {
        Diag.debug("Watchdog: Database Lock timeout")
        triggerDatabase()
    }

    /// Triggers an app lock timeout notification.
    private func triggerApp() {
        self.appDeadline = nil
        self.appTimer?.invalidate()
        self.appTimer = nil
        AppLockManager.shared.maybeLock()
        NotificationCenter.default.post(name: Watchdog.Notifications.appLockTimeout, object: self)
    }
    
    // A flag to prevent repeated closeDatabase() calls
    private var isDatabaseCloseScheduled = false
    
    /// Triggers a database timeout notification (only if there is an open DB).
    private func triggerDatabase() {
        guard DatabaseManager.shared.isDatabaseOpen else {
            Diag.debug("Watchdog: no DB open, nothing to do")
            return
        }
        guard !isDatabaseCloseScheduled else {
            Diag.warning("Watchdog: repeated attempt to close DB ignored")
            return
        }
        Diag.info("Watchdog: DB timeout, closing current database")
        isDatabaseCloseScheduled = true
        self.databaseDeadline = nil
        self.databaseTimer?.invalidate()
        self.databaseTimer = nil
        DatabaseManager.shared.closeDatabase(
            completion: {
                self._isDatabaseTimeoutExpired = true
                NotificationCenter.default.post(
                    name: Watchdog.Notifications.databaseCloseTimeout,
                    object: self)
                self.isDatabaseCloseScheduled = false
            },
            clearStoredKey: true)
    }
    
    /// Pauses the timer -- for example, before the app going to background.
    func pause() {
        appTimer?.invalidate()
        databaseTimer?.invalidate()
        appTimer = nil
        databaseTimer = nil
    }
    
    /// Called externally from `applicationWIllResignActive`.
    func appWillResignActive() {
        let databaseTimeout = Settings.current.databaseCloseTimeout
        if databaseTimeout == .immediately {
            Diag.debug("Going to background: database watchdog triggered")
            triggerDatabase()
        }
        
        let appTimeout = Settings.current.appLockTimeout
        if appTimeout == .immediately {
            Diag.debug("Going to background: app watchdog triggered")
//            triggerApp()
            restartAppTimer()
        }
        
        pause()
    }
    
    /// Called externally from AppDelegate.
    func appDidBecomeActive() {
        // When we are here, the watchdog is either disabled or paused.
        // So we check each manually or restart if needed.
        let now = Date.now
        
        // (Workaround for https://forums.developer.apple.com/thread/91384)
        // When we show biometric auth window, the app becomes inactive then active again -
        // all within split-second. This is enough to miss the appDeadline,
        // so we get stuck in an infinite loop of Face ID requests.
        // Workaround: postpone the deadline by a second in these cases.
        var appExtraTime = 0.0
        if Settings.current.appLockTimeout == .immediately
            && Settings.current.isBiometricAppLockEnabled
        {
            appExtraTime = 1.0
        }
        
        if let appDeadline = appDeadline, now > appDeadline + appExtraTime {
            Diag.debug("Returned from background: app timeout expired")
            triggerApp()
        } else {
            Diag.debug("Returned from background: restarting app timer")
            restartAppTimer()
        }
        
        if let dbDeadline = databaseDeadline, now > dbDeadline {
            Diag.debug("Returned from background: database timeout expired")
            triggerDatabase()
        } else {
            Diag.debug("Returned from background: restarting database timer")
            restartDatabaseTimer()
        }
    }
}
