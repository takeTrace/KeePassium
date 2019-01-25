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
import LocalAuthentication
import KeePassiumLib

public class AppLockManager {
    static let shared = AppLockManager()

    public var isLocked: Bool { return lockWindow != nil }

    private var coverWindow: UIWindow?
    private var lockWindow: UIWindow?
    private var isBiometricAuthShown = false

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
    
    @objc private func appDidFinishLaunching(_ notification: Notification) {
        print("App did finish launching")
        maybeLock()
    }
    @objc private func appWillEnterForeground(_ notification: Notification) {
        print("App will enter foreground")
        Watchdog.default.appDidBecomeActive()
        hideCover()
    }
    @objc private func appDidBecomeActive(_ notification: Notification) {
        print("App did become active")
        Watchdog.default.appDidBecomeActive()
        hideCover()
    }
    @objc private func appWillResignActive(_ notification: Notification) {
        print("App will resign active")
        Watchdog.default.appWillResignActive()
        showCover(application: KPApplication.shared)
    }

    @objc private func appDidEnterBackground(_ notification: Notification) {
        print("App did enter background")
    }

    
    /// Obscures the UI while in background
    func showCover(application: UIApplication)  {
        guard coverWindow == nil else { return }
        
        coverWindow = UIWindow(frame: UIScreen.main.bounds)
        coverWindow!.screen = UIScreen.main
        coverWindow!.windowLevel = UIWindow.Level.alert
        let coverVC = AppCoverVC.make()
        coverWindow!.rootViewController = coverVC
        coverWindow!.makeKeyAndVisible()
        print("Cover shown")

        coverVC.view.snapshotView(afterScreenUpdates: true)
    }
    
    func hideCover() {
        guard let coverWindow = coverWindow else { return }
        coverWindow.isHidden = true
        self.coverWindow = nil
        print("Cover hidden")
    }
    
    /// Shows biometric authentication UI, if supported and enabled.
    ///
    /// - Parameter completion: called after biometric authentication,
    ///         with a `Bool` parameter indicating success of the bioauth.
    /// - Returns: `true` if biometric authentication shown, `false` otherwise.
    open func maybeShowBiometricAuth(completion: @escaping ((Bool) -> Void)) -> Bool {
        guard Settings.current.isBiometricAppLockEnabled else { return false }
        guard !isBiometricAuthShown else { return false }
        
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        context.localizedFallbackTitle = "" // hide "Enter Password" fallback; nil won't work
        if AppLockManager.shared.isBiometricsAvailable() {
            print("FaceID: showing request")
            context.evaluatePolicy(policy, localizedReason: LString.titleTouchID) {
                [unowned self] (authSuccessful, authError) in
                self.isBiometricAuthShown = false
                DispatchQueue.main.async { [unowned self] in
                    if authSuccessful {
                        print("FaceID success")
                        self.unlock()
                        Watchdog.default.restart()
                        completion(true)
                    } else {
                        print("FaceID failed")
                        Diag.warning("TouchID failed [error: \(authError?.localizedDescription ?? "nil")]")
                        completion(false)
                    }
                }
            }
            return true
        }
        return false
    }
    
    /// Engages app lock, if enabled.
    open func maybeLock() {
        guard !isLocked else { return }
        guard Settings.current.appLockTimeout != .never else { return }
        if Settings.current.isAppLockEnabled {
            Diag.info("AppLock engaged")
            showLockScreen()
        } else {
            Diag.debug("AppLock disabled, skipping the lock")
        }
    }
    
    open func unlock() {
        guard isLocked else { return }
        hideLockScreen()
    }
    
    /// Shows the lock screen.
    private func showLockScreen() {
        lockWindow = UIWindow(frame: UIScreen.main.bounds)
        lockWindow!.screen = UIScreen.main
        lockWindow!.windowLevel = UIWindow.Level.alert
        let passcodeInputVC = PasscodeInputVC.instantiateFromStoryboard()
        passcodeInputVC.delegate = self
        passcodeInputVC.mode = .verification
        passcodeInputVC.isCancellable = false // for the main app
        lockWindow!.rootViewController = passcodeInputVC
        lockWindow!.makeKeyAndVisible()
        print("LockScreen shown")
    }

    private func hideLockScreen() {
        lockWindow?.isHidden = true
        lockWindow = nil
        print("LockScreen hidden")
    }
    
    /// Checks if there is a stored App Lock passcode.
    /// - Throws: KeychainError
    public func isPasscodeSet() throws -> Bool {
        let hasPasscode = try Keychain.shared.isAppPasscodeSet() // throws KeychainError
        return Settings.current.isAppLockEnabled && hasPasscode
    }

    /// True if hardware provides biometric authentication, and the app supports it.
    public func isBiometricsAvailable() -> Bool {
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        return context.canEvaluatePolicy(policy, error: nil)
    }
}

extension AppLockManager: PasscodeInputDelegate {
    func passcodeInput(_ sender: PasscodeInputVC, didEnterPasscode passcode: String) {
        do {
            if try Keychain.shared.isAppPasscodeMatch(passcode) { // throws KeychainError
                hideLockScreen()
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
}
