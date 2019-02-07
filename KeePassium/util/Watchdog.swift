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
import LocalAuthentication

class Watchdog {
    public static let shared = Watchdog()
    
    public enum Notifications {
        /// Notification name for watchdog triggers
        public static let appLockDidEngage = Notification.Name("com.keepassium.Watchdog.appLockDidEngage")
        public static let databaseLockDidEngage = Notification.Name("com.keepassium.Watchdog.databaseLockDidEngage")
    }
    
    /// True if AppLock is engaged (asking for passcode/biometrics)
    public var isAppLocked: Bool { return appLockWindow != nil }

    /// True if main app UI is protected by a cover window
    public var isAppCovered: Bool { return appCoverWindow != nil }
    
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
    
    private var appCoverWindow: UIWindow?
    private var appLockWindow: UIWindow?
    private var isBiometricAuthShown = false
    private var wasShowingBiometricAuth = false
    
    private var appLockTimer: Timer?
    private var databaseLockTimer: Timer?

    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidFinishLaunching),
            name: UIApplication.didFinishLaunchingNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
    }
    
    // MARK: - App state transitions
    
    @objc private func appDidFinishLaunching(_ notification: Notification) {
        print("App did finish launching")
    }
    @objc private func appWillEnterForeground(_ notification: Notification) {
        print("App will enter foreground")
    }
    @objc private func appDidBecomeActive(_ notification: Notification) {
        print("App did become active")
        restartAppTimer()
        restartDatabaseTimer()
        if wasShowingBiometricAuth {
            wasShowingBiometricAuth = false
        } else {
            maybeLockSomething()
        }
        hideAppCover()
    }
    @objc private func appWillResignActive(_ notification: Notification) {
        print("App will resign active")
        showAppCover(application: KPApplication.shared)
        if isBiometricAuthShown { return }
        if isAppLocked { return }

        let databaseTimeout = Settings.current.databaseCloseTimeout
        if databaseTimeout == .immediately {
            Diag.debug("Going to background: Database Lock engaged")
            engageDatabaseLock()
        }
        
        let appTimeout = Settings.current.appLockTimeout
        if appTimeout == .immediately {
            Diag.debug("Going to background: App Lock engaged")
            // do nothing, this case is handled on appDidBecomeActive
        }
        
        // Timers don't run reliably in background anyway, so kill them
        appLockTimer?.invalidate()
        databaseLockTimer?.invalidate()
        appLockTimer = nil
        databaseLockTimer = nil
    }
    
    @objc private func appDidEnterBackground(_ notification: Notification) {
        print("App did enter background")
    }
    
    // MARK: - Watchdog functions
    
    @objc private func maybeLockSomething() {
        if isShouldEngageAppLock() {
            engageAppLock()
        }
        if isShouldEngageDatabaseLock() {
            engageDatabaseLock()
        }
    }
    
    open func restart() {
        guard !isAppLocked else { return }
        Settings.current.recentUserActivityTimestamp = Date.now
        restartAppTimer()
        restartDatabaseTimer()
    }

    private func isShouldEngageAppLock() -> Bool {
        guard Settings.current.isAppLockEnabled else { return false }
        let timeout = Settings.current.appLockTimeout
        switch timeout {
        case .never: // app lock disabled
            return false
        case .immediately:
            return true
        default:
            let timestampOfRecentActivity = Settings.current
                .recentUserActivityTimestamp
                .timeIntervalSinceReferenceDate
            let timestampNow = Date.now.timeIntervalSinceReferenceDate
            let secondsPassed = timestampNow - timestampOfRecentActivity
            return secondsPassed > Double(timeout.seconds)
        }
    }
    
    private func isShouldEngageDatabaseLock() -> Bool {
        let timeout = Settings.current.databaseCloseTimeout
        switch timeout {
        case .never:
            return false
        case .immediately:
            return true
        default:
            let timestampOfRecentActivity = Settings.current
                .recentUserActivityTimestamp
                .timeIntervalSinceReferenceDate
            let timestampNow = Date.now.timeIntervalSinceReferenceDate
            let secondsPassed = timestampNow - timestampOfRecentActivity
            return secondsPassed > Double(timeout.seconds)
        }
    }
    
    private func restartAppTimer() {
        if let appLockTimer = appLockTimer {
            appLockTimer.invalidate()
        }
        
        let timeout = Settings.current.appLockTimeout
        switch timeout {
        case .never, .immediately:
            return
        default:
            self.appLockTimer = Timer.scheduledTimer(
                timeInterval: Double(timeout.seconds),
                target: self,
                selector: #selector(maybeLockSomething),
                userInfo: nil,
                repeats: false)
        }
    }

    private func restartDatabaseTimer() {
        if let databaseLockTimer = databaseLockTimer {
            databaseLockTimer.invalidate()
        }
        
        let timeout = Settings.current.databaseCloseTimeout
        Diag.verbose("Database Lock timeout: \(timeout.seconds)")
        switch timeout {
        case .never, .immediately:
            return
        default:
            databaseLockTimer = Timer.scheduledTimer(
                timeInterval: Double(timeout.seconds),
                target: self,
                selector: #selector(maybeLockSomething),
                userInfo: nil,
                repeats: false)
        }
    }

    /// Triggers an app lock timeout notification.
    private func engageAppLock() {
        guard !isAppLocked else { return }
        Diag.info("Engaging App Lock")
        self.appLockTimer?.invalidate()
        self.appLockTimer = nil
        showAppLockScreen()
        NotificationCenter.default.post(name: Watchdog.Notifications.appLockDidEngage, object: self)
    }
    
    /// Triggers a database timeout notification (only if there is an open DB).
    private func engageDatabaseLock() {
        Diag.info("Engaging Database Lock")
        self.databaseLockTimer?.invalidate()
        self.databaseLockTimer = nil
        DatabaseManager.shared.closeDatabase(
            completion: {
                NotificationCenter.default.post(
                    name: Watchdog.Notifications.databaseLockDidEngage,
                    object: self)
            },
            clearStoredKey: true)
    }
    
    // MARK: - Application cover UI
    
    /// Obscures the UI while in background
    private func showAppCover(application: UIApplication)  {
        guard appCoverWindow == nil else { return }
        
        appCoverWindow = UIWindow(frame: UIScreen.main.bounds)
        appCoverWindow!.screen = UIScreen.main
        appCoverWindow!.windowLevel = UIWindow.Level.alert
        let coverVC = AppCoverVC.make()
        appCoverWindow!.rootViewController = coverVC
        appCoverWindow!.makeKeyAndVisible()
        print("App cover shown")
        
        coverVC.view.snapshotView(afterScreenUpdates: true)
    }
    
    private func hideAppCover() {
        guard let appCoverWindow = appCoverWindow else { return }
        appCoverWindow.isHidden = true
        self.appCoverWindow = nil
        print("App cover hidden")
    }
    
    // MARK: - App Lock UI
    
    /// Shows biometric authentication UI, if supported and enabled.
    ///
    /// - Parameter completion: called after biometric authentication,
    ///         with a `Bool` parameter indicating success of the bioauth.
    private func maybeShowBiometricAuth(completion: @escaping ((Bool) -> Void)) {
        guard Settings.current.isBiometricAppLockEnabled else { return }
        guard !isBiometricAuthShown else { return }
        
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        context.localizedFallbackTitle = "" // hide "Enter Password" fallback; nil won't work
        if isBiometricsAvailable() {
            context.evaluatePolicy(policy, localizedReason: LString.titleTouchID) {
                [unowned self] (authSuccessful, authError) in
                self.isBiometricAuthShown = false
                DispatchQueue.main.async { [unowned self] in
                    self.wasShowingBiometricAuth = true
                    if authSuccessful {
                        self.unlockApp()
                        completion(true)
                    } else {
                        Diag.warning("TouchID failed [message: \(authError?.localizedDescription ?? "nil")]")
                        completion(false)
                    }
                }
            }
            isBiometricAuthShown = true
        }
        isBiometricAuthShown = false
    }
    
    open func unlockApp() {
        guard isAppLocked else { return }
        hideAppLockScreen()
        restart()
    }
    
    /// Shows the lock screen.
    private func showAppLockScreen() {
        let isRepeatedBiometricsAllowed = isBiometricsAvailable()
            && Settings.current.isBiometricAppLockEnabled
        appLockWindow = UIWindow(frame: UIScreen.main.bounds)
        appLockWindow!.screen = UIScreen.main
        appLockWindow!.windowLevel = UIWindow.Level.alert
        let passcodeInputVC = PasscodeInputVC.instantiateFromStoryboard()
        passcodeInputVC.delegate = self
        passcodeInputVC.mode = .verification
        passcodeInputVC.isCancelAllowed = false // for the main app
        passcodeInputVC.isBiometricsAllowed = isRepeatedBiometricsAllowed
        appLockWindow!.rootViewController = passcodeInputVC
        appLockWindow!.makeKeyAndVisible()
        print("appLockWindow shown")
        
        maybePerformBiometricUnlock(passcodeInput: passcodeInputVC)
    }
    
    private func hideAppLockScreen() {
        appLockWindow?.isHidden = true
        appLockWindow = nil
        print("appLockWindow hidden")
    }
    
    /// True if hardware provides biometric authentication, and the app supports it.
    public func isBiometricsAvailable() -> Bool {
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        return context.canEvaluatePolicy(policy, error: nil)
    }
    
    /// Shows biometric auth, if available
    private func maybePerformBiometricUnlock(passcodeInput: PasscodeInputVC?) {
        weak var _passcodeInput = passcodeInput
        maybeShowBiometricAuth() {
            [weak self] (isAuthSuccessful) in
            guard let _self = self else { return }
            if isAuthSuccessful {
                _self.unlockApp()
            } else {
                let isAnotherBiometricsAttemptAllowed = _self.isBiometricsAvailable()
                    && Settings.current.isBiometricAppLockEnabled
                _passcodeInput?.isBiometricsAllowed = isAnotherBiometricsAttemptAllowed
            }
        }
    }
}

extension Watchdog: PasscodeInputDelegate {
    func passcodeInput(_ sender: PasscodeInputVC, didEnterPasscode passcode: String) {
        do {
            if try Keychain.shared.isAppPasscodeMatch(passcode) { // throws KeychainError
                unlockApp()
            } else {
                sender.animateWrongPassccode()
            }
        } catch {
            let alert = UIAlertController.make(
                title: LString.titleKeychainError,
                message: error.localizedDescription)
            sender.present(alert, animated: true, completion: nil)
        }
    }
    
    func passcodeInputDidRequestBiometrics(_ sender: PasscodeInputVC) {
        maybePerformBiometricUnlock(passcodeInput: sender)
    }
}
