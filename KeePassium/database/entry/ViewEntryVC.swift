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

class ViewEntryVC: UIViewController, Refreshable {
    //MARK: - Storyboard stuff
    @IBOutlet weak var pageSelector: UISegmentedControl!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    var pagesViewController: UIPageViewController!
    
    private weak var entry: Entry?
    private var isHistoryMode = false
    private var entryChangeNotifications: EntryChangeNotifications!
    private var progressOverlay: ProgressOverlay?
    private var pages = [UIViewController]()
    private var currentPageIndex = 0

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
        guard let entry = entry else { return }
        
        pages.append(ViewEntryFieldsVC.make(with: entry, historyMode: isHistoryMode))
        pages.append(ViewEntryFilesVC.make(
            with: entry,
            historyMode: isHistoryMode,
            progressViewHost: self))
        pages.append(ViewEntryHistoryVC.make(with: entry, historyMode: isHistoryMode))
        
        pagesViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil)
        pagesViewController.delegate = self
        pagesViewController.dataSource = self

        addChild(pagesViewController)
        pagesViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pagesViewController.view.frame = containerView.bounds
        containerView.addSubview(pagesViewController.view)
        pagesViewController.didMove(toParent: self)
        
        entryChangeNotifications = EntryChangeNotifications(observer: self)
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // we might have missed some changes, so force refresh
        refresh()

        switchTo(page: Settings.current.entryViewerPage)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        entryChangeNotifications.startObserving()
        
        // Now, replace the decoy button set in storyboard.
        // Without a decoy, it would just appear without animation.
        navigationItem.rightBarButtonItem =
            pagesViewController.viewControllers?.first?.navigationItem.rightBarButtonItem
    }

    override func viewDidDisappear(_ animated: Bool) {
        Settings.current.entryViewerPage = pageSelector.selectedSegmentIndex
        entryChangeNotifications.stopObserving()
        super.viewDidDisappear(animated)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        refresh()
    }
    
    private func switchTo(page index: Int) {
        let direction: UIPageViewController.NavigationDirection
        if index >= currentPageIndex {
            direction = .forward
        } else {
            direction = .reverse
        }

        let targetPageVC = pages[index]
        pagesViewController.setViewControllers(
            [targetPageVC],
            direction: direction,
            animated: true,
            completion: { [weak self] (finished) in
                guard let _self = self else { return }
                _self.pageSelector.selectedSegmentIndex = index
                _self.currentPageIndex = index
                _self.navigationItem.rightBarButtonItem =
                    targetPageVC.navigationItem.rightBarButtonItem
            }
        )
        
    }
    
    @IBAction func didChangePage(_ sender: Any) {
        switchTo(page: pageSelector.selectedSegmentIndex)
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

// MARK: - ProgressViewHost

extension ViewEntryVC: ProgressViewHost {
    func showProgressView(title: String, allowCancelling: Bool) {
        //FIXME: should disable master VC on iPad
        if progressOverlay != nil {
            // something is already shown, just update it
            progressOverlay?.title = title
            progressOverlay?.isCancellable = allowCancelling
            return
        }
        
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem?.isEnabled = false
        progressOverlay = ProgressOverlay.addTo(
            view,
            title: title,
            animated: true)
        progressOverlay?.isCancellable = allowCancelling
    }
    
    func updateProgressView(with progress: ProgressEx) {
        progressOverlay?.update(with: progress)
    }
    
    func hideProgressView() {
        guard progressOverlay != nil else { return }
        navigationItem.hidesBackButton = false
        navigationItem.rightBarButtonItem?.isEnabled = true
        progressOverlay?.dismiss(animated: true) {
            [weak self] (finished) in
            guard let _self = self else { return }
            _self.progressOverlay?.removeFromSuperview()
            _self.progressOverlay = nil
        }
    }
}

// MARK: - UIPageViewControllerDelegate

extension ViewEntryVC: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool)
    {
        if finished && completed {
            guard let selectedVC = pageViewController.viewControllers?.first,
                let selectedIndex = pages.index(of: selectedVC) else { return }
            currentPageIndex = selectedIndex
            pageSelector.selectedSegmentIndex = selectedIndex
            navigationItem.rightBarButtonItem = selectedVC.navigationItem.rightBarButtonItem
        }
    }
}

// MARK: - UIPageViewControllerDataSource

extension ViewEntryVC: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
        ) -> UIViewController?
    {
        guard let vcIndex = pages.index(of: viewController) else { return nil }
        if vcIndex > 0 {
            return pages[vcIndex - 1]
        } else {
            return nil
        }
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
        ) -> UIViewController?
    {
        guard let vcIndex = pages.index(of: viewController) else { return nil }
        if vcIndex < pages.count - 1 {
            return pages[vcIndex + 1]
        } else {
            return nil
        }
    }
}
