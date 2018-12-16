//
//  FirstSetupVC.swift
//  KeePassium AutoFill
//
//  Created by Andrei Popleteev on 2018-12-12.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

class FirstSetupVC: UIViewController {
    
    private weak var coordinator: MainCoordinator?
    
    static func make(coordinator: MainCoordinator) -> FirstSetupVC {
        let vc = FirstSetupVC.instantiateFromStoryboard()
        vc.coordinator = coordinator
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    @IBAction func didPressCancelButton(_ sender: Any) {
        coordinator?.dismissAndQuit()
    }
    
    @IBAction func didPressAddDatabase(_ sender: Any) {
        coordinator?.addDatabase()
    }
}
