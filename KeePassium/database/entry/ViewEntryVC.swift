//
//  ViewEntryVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-05-22.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

class ViewEntryVC: UIViewController, Refreshable {
    //MARK: - Storyboard stuff
    @IBOutlet weak var pageSelector: UISegmentedControl!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    private var pagesVC: ViewEntryPagesVC!
    private weak var entry: Entry?
    private var isHistoryMode = false
    private var entryChangeNotifications: EntryChangeNotifications!
    
    /// Instantiates `ViewEntryVC` in normal or history-viewing mode.
    static func make(with entry: Entry, historyMode: Bool = false) -> UIViewController {
        let viewEntryVC = ViewEntryVC.instantiateFromStoryboard()
        viewEntryVC.entry = entry
        viewEntryVC.isHistoryMode = historyMode
        viewEntryVC.refresh()
        if !historyMode {
            // In normal mode, we need to wrap the VC in a navigation controller
            // to show eventual history-mode VCs nicely.
            let navVC = UINavigationController(rootViewController: viewEntryVC)
            return navVC
        } else {
            return viewEntryVC
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagesVC = ViewEntryPagesVC.make(with: entry!, historyMode: isHistoryMode)
        pagesVC.delegate = self
        addChild(pagesVC)
        pagesVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pagesVC.view.frame = containerView.bounds
        containerView.addSubview(pagesVC.view)
        pagesVC.didMove(toParent: self)
        
        entryChangeNotifications = EntryChangeNotifications(observer: self)
        refresh()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        entryChangeNotifications.startObserving()
        
        // Now, replace the decoy button set in storyboard.
        // Without a decoy, it would just appear without animation.
        navigationItem.rightBarButtonItem =
            pagesVC?.viewControllers?.first?.navigationItem.rightBarButtonItem
    }

    override func viewDidDisappear(_ animated: Bool) {
        entryChangeNotifications.stopObserving()
        super.viewDidDisappear(animated)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        refresh()
    }
    
    @IBAction func didChangePage(_ sender: Any) {
        let selIndex = pageSelector.selectedSegmentIndex
        pagesVC.switchToPage(index: selIndex)
        navigationItem.rightBarButtonItem =
            pagesVC?.viewControllers?.first?.navigationItem.rightBarButtonItem
    }

    func refresh() {
        guard let entry = entry else { return }
        titleLabel?.text = entry.title
        titleImageView?.image = UIImage.kpIcon(forEntry: entry)
        if isHistoryMode {
            if traitCollection.horizontalSizeClass == .compact {
                subtitleLabel?.text = DateFormatter.localizedString(
                    from: entry.lastModificationTime,
                    dateStyle: .medium,
                    timeStyle: .short)
            } else {
                subtitleLabel?.text = DateFormatter.localizedString(
                    from: entry.lastModificationTime,
                    dateStyle: .full,
                    timeStyle: .medium)
            }
            subtitleLabel?.isHidden = false
        } else {
            subtitleLabel?.isHidden = true
        }
    }
}

extension ViewEntryVC: EntryChangeObserver {
    func entryDidChange(entry: Entry) {
        refresh()
    }
}

extension ViewEntryVC: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool)
    {
        if finished && completed {
            pageSelector.selectedSegmentIndex = pagesVC.currentPageIndex
            navigationItem.rightBarButtonItem =
                pagesVC?.viewControllers?.first?.navigationItem.rightBarButtonItem
        }
    }
}
