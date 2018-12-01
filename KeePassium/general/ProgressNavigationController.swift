//
//  ProgressNavigationController.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-15.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

//TODO: probably not used anymore, remove this file
/// Navigation controller with an embedded progress view.
class ProgressNavigationController: UINavigationController {

    var progressView: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()

        progressView = UIProgressView()
        self.view.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:[navBar]-0-[progressView]",
            options: .directionLeadingToTrailing,
            metrics: nil,
            views: [
                "progressView" : progressView,
                "navBar" : self.navigationBar
            ]
        ))
        self.view.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[progressView]|",
            options: .directionLeadingToTrailing,
            metrics: nil,
            views: [
                "progressView" : progressView
            ]
        ))
        progressView.isHidden = true
    }
}

