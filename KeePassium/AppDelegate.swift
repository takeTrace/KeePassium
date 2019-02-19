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

//@UIApplicationMain - replaced by main.swift to subclass UIApplication
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var watchdog: Watchdog
    private var appCoverWindow: UIWindow?
    private var appLockWindow: UIWindow?
    private var isBiometricAuthShown = false
    
    override init() {
        watchdog = Watchdog.shared // init
        super.init()
        watchdog.delegate = self
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool
    {
        AppGroup.applicationShared = application
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

extension AppDelegate: WatchdogDelegate {
    var isAppCoverVisible: Bool {
        return appCoverWindow != nil
    }
    var isAppLockVisible: Bool {
        return appLockWindow != nil || isBiometricAuthShown
    }
    func showAppCover(_ sender: Watchdog) {
        showAppCover(application: KPApplication.shared)
    }
    func hideAppCover(_ sender: Watchdog) {
        hideAppCover()
    }
    func showAppLock(_ sender: Watchdog) {
        showAppLockScreen()
    }
    func hideAppLock(_ sender: Watchdog) {
        hideAppLockScreen()
    }
    
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
    
    /// Shows the lock screen.
    private func showAppLockScreen() {
        guard !isAppLockVisible else { return }
        
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
        guard isAppLockVisible else { return }
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
    
    /// Shows biometric auth, if supported and enabled.
    private func maybePerformBiometricUnlock(passcodeInput: PasscodeInputVC?) {
        weak var _passcodeInput = passcodeInput
        guard Settings.current.isBiometricAppLockEnabled else { return }
        guard !isBiometricAuthShown else { return }
        
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        context.localizedFallbackTitle = "" // hide "Enter Password" fallback; nil won't work
        if isBiometricsAvailable() {
            context.evaluatePolicy(policy, localizedReason: LString.titleTouchID) {
                [weak self] (authSuccessful, authError) in
                guard let _self = self else { return }
                _self.isBiometricAuthShown = false
                DispatchQueue.main.async { [weak self] in
                    guard let _self = self else { return }
                    if authSuccessful {
                        _self.watchdog.unlockApp(fromAnotherWindow: true)
                    } else {
                        Diag.warning("TouchID failed [message: \(authError?.localizedDescription ?? "nil")]")
                        let isAnotherBiometricsAttemptAllowed = _self.isBiometricsAvailable()
                            && Settings.current.isBiometricAppLockEnabled
                        _passcodeInput?.isBiometricsAllowed = isAnotherBiometricsAttemptAllowed
                    }
                }
            }
            isBiometricAuthShown = true
        }
        isBiometricAuthShown = false
    }
}


extension AppDelegate: PasscodeInputDelegate {
    func passcodeInput(_ sender: PasscodeInputVC, didEnterPasscode passcode: String) {
        do {
            if try Keychain.shared.isAppPasscodeMatch(passcode) { // throws KeychainError
                watchdog.unlockApp(fromAnotherWindow: false)
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
