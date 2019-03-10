//
//  CrashReportVC.swift
//  KeePassium AutoFill
//
//  Created by Andrei Popleteev on 2019-03-10.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import UIKit

protocol CrashReportDelegate: class {
    func didPressDismiss(in crashReport: CrashReportVC)
}

class CrashReportVC: UIViewController {

    public weak var delegate: CrashReportDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func didPressDismiss(_ sender: Any) {
        delegate?.didPressDismiss(in: self)
    }
}
