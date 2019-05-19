//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import LocalAuthentication
import UIKit

extension LAContext {
    /// Returns the type of supported biometric auth method.
    /// Unlike the `biometryType` property, this method makes
    /// the required pre-requisite call to `canEvaluatePolicy()`.
    public static func getBiometryType() -> LABiometryType {
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        // According to documentation, `biometryType` value
        // is set only after a call to `canEvaluatePolicy`.
        context.canEvaluatePolicy(policy, error: nil)
        return context.biometryType
    }
}

extension LABiometryType {
    /// Returns human-readable description of the biometric authentication type,
    /// or `nil` if no biometry is supported.
    var name: String? {
        switch self {
        case .touchID:
            return NSLocalizedString("Touch ID", comment: "Name of biometric authentication method")
        case .faceID:
            return NSLocalizedString("Face ID", comment: "Name of biometric authentication method")
        default:
            return nil
        }
    }
    
    /// Returns a list-item sized icon for this biometric authentication type,
    /// or `nil` if no biometry is supported.
    var icon: UIImage? {
        switch self {
        case .faceID:
            return UIImage(asset: .biometryFaceIDListitem)
        case .touchID:
            return UIImage(asset: .biometryTouchIDListitem)
        default:
            return nil
        }
    }
}
