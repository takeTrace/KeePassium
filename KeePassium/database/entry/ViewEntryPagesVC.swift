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

/// Manages pages (sub-VCs) of the `ViewEntryVC`
class ViewEntryPagesVC: UIPageViewController {
    private var pages = [UIViewController]()
    private weak var entry: Entry?
    private var isHistoryMode = false
    private weak var progressViewHost: ProgressViewHost?
    
    internal static func make(
        with entry: Entry,
        historyMode: Bool = false,
        progressViewHost: ProgressViewHost?
    ) -> ViewEntryPagesVC {
        let vc = ViewEntryPagesVC.instantiateFromStoryboard()
        vc.entry = entry
        vc.isHistoryMode = historyMode
        vc.progressViewHost = progressViewHost
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        pages.append(ViewEntryFieldsVC.make(with: entry, historyMode: isHistoryMode))
        pages.append(ViewEntryFilesVC.make(
            with: entry,
            historyMode: isHistoryMode,
            progressViewHost: progressViewHost))
        pages.append(ViewEntryHistoryVC.make(with: entry, historyMode: isHistoryMode))
        setViewControllers([pages.first!], direction: .forward, animated: true, completion: nil)
    }
    
    internal var currentPageIndex: Int {
        let presentedVC = viewControllers!.first!
        return pages.index(of: presentedVC)!
    }
    
    internal func switchToPage(index: Int) {
        let curIndex = currentPageIndex
        let direction: UIPageViewController.NavigationDirection
        if index < curIndex {
            direction = .reverse
        } else {
            direction = .forward
        }
        setViewControllers([pages[index]], direction: direction, animated: true, completion: nil)
    }
}

extension ViewEntryPagesVC: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
        ) -> UIViewController?
    {
        guard let currentIndex = pages.index(of: viewController) else {
            assertionFailure("No such page")
            return nil
        }
        
        if currentIndex > 0 {
            return pages[currentIndex - 1]
        } else {
            return nil
        }
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
        ) -> UIViewController?
    {
        guard let currentIndex = pages.index(of: viewController) else {
            assertionFailure("No such page")
            return nil
        }
        
        if currentIndex < pages.count - 1 {
            return pages[currentIndex + 1]
        } else {
            return nil
        }
    }
}
