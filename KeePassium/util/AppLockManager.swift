//
//  AppLockManager.swift
//  KeePassium
//
// Created by Andrei Popleteev on 2018-07-31.
// Copyright (c) 2018 Andrei Popleteev. All rights reserved.
//

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
    /// - Returns: `true` if biometric authentication shown, `false` otherwise.
    open func maybeShowBiometricAuth() -> Bool {
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
                    } else {
                        print("FaceID failed")
                        Diag.warning("TouchID failed [error: \(authError?.localizedDescription ?? "nil")]")
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
        do {
            if try isPasscodeSet() { // throws KeychainError
                Diag.info("App locked")
                showLockScreen()
            } else {
                Diag.debug("App Lock passcode not set, skipping the lock")
            }
        } catch { // KeychainError
            showLockScreen(message: error.localizedDescription)
        }
    }
    
    open func unlock() {
        guard isLocked else { return }
        hideLockScreen()
    }
    
    /// Shows the lock screen, with an optional custom message.
    private func showLockScreen(message: String? = nil) {
        lockWindow = UIWindow(frame: UIScreen.main.bounds)
        lockWindow!.screen = UIScreen.main
        lockWindow!.windowLevel = UIWindow.Level.alert
        lockWindow!.rootViewController = AppLockVC.make(message: message)
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
        return try Keychain.shared.isAppPasscodeSet() // throws KeychainError
    }

    /// Saves the given passcode.
    /// - Throws: KeychainError
    internal func setPasscode(passcode: String) throws {
        try Keychain.shared.setAppPasscode(passcode) // throws KeychainError
    }

    /// Removes App Lock passcode.
    /// - Throws: KeychainError
    internal func resetPasscode() throws {
        try Keychain.shared.removeAppPasscode() // throws KeychainError
    }

    /// Checks if `passcode` value matches the previously saved one.
    /// - Throws: KeychainError
    internal func isPasscodeMatch(passcode: String) throws -> Bool {
        return try Keychain.shared.isAppPasscodeMatch(passcode) // throws KeychainError
    }
    
    /// True if hardware provides biometric authentication, and the app supports it.
    public func isBiometricsAvailable() -> Bool {
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        return context.canEvaluatePolicy(policy, error: nil)
    }
}
