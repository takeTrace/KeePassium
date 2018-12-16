//
//  Coordinator.swift
//  KeePassium AutoFill
//
//  Created by Andrei Popleteev on 2018-12-12.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

protocol Coordinator: class {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}
