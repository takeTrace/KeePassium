//
//  ProgressViewHost.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2019-03-06.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import Foundation
import KeePassiumLib

/// Protocol for objects that provide UI space for showing
/// some kind of progress view (such as `ProgressOverlay`)
public protocol ProgressViewHost: class {
    func showProgressView(title: String, allowCancelling: Bool)
    func updateProgressView(with progress: ProgressEx)
    func hideProgressView()
}
