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

