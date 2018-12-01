//
//  ViewEntryPagesVC.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-05-22.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import KeePassiumLib

/// Manages pages (sub-VCs) of the `ViewEntryVC`
class ViewEntryPagesVC: UIPageViewController {
    private var pages = [UIViewController]()
    private weak var entry: Entry?
    private var isHistoryMode = false
    
    internal static func make(with entry: Entry, historyMode: Bool = false) -> ViewEntryPagesVC {
        let vc = ViewEntryPagesVC.instantiateFromStoryboard()
        vc.entry = entry
        vc.isHistoryMode = historyMode
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        pages.append(ViewEntryFieldsVC.make(with: entry, historyMode: isHistoryMode))
        pages.append(ViewEntryFilesVC.make(with: entry, historyMode: isHistoryMode))
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
