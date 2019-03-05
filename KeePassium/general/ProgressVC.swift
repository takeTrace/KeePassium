//
//  ProgressVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2019-03-05.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

class ProgressVC: UIViewController {
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    
    override public var title: String? {
        didSet { statusLabel?.text = title }
    }
    
    public var isCancellable = true {
        didSet { cancelButton?.isEnabled = isCancellable }
    }

    private weak var progress: ProgressEx?

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        progressView.progress = 0.0
        statusLabel.text = title
        percentLabel.text = nil
        cancelButton.setTitle(LString.actionCancel, for: .normal)
        cancelButton.isEnabled = isCancellable
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    public func update(with progress: ProgressEx) {
        percentLabel.text = String(format: "%.0f%%", 100.0 * progress.fractionCompleted)
        progressView.setProgress(Float(progress.fractionCompleted), animated: true)
        
        // once cancelled, there is no going back
        cancelButton.isEnabled = cancelButton.isEnabled &&
            progress.isCancellable &&
            !progress.isCancelled
        self.progress = progress
    }
    
    @IBAction func didPressCancel(_ sender: UIButton) {
        progress?.cancel()
    }
}
