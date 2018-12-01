//
//  GroupChangeObserver+Notifier.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-07-02.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import Foundation
import KeePassiumLib

protocol GroupChangeObserver: class {
    /// Called when there is a notification about a group change
    func groupDidChange(group: Group)
}

class GroupChangeNotifications {
    private static let groupChanged = Notification.Name("com.keepassium.GroupChanged")
    private static let userInfoGroupKey = "ChangedGroup"

    private weak var observer: GroupChangeObserver?
    
    init(observer: GroupChangeObserver) {
        self.observer = observer
    }
    
    /// Adds `self` as observer of group changes
    func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(groupDidChange),
            name: GroupChangeNotifications.groupChanged,
            object: nil)
    }
    
    func stopObserving() {
        NotificationCenter.default.removeObserver(
            self,
            name: GroupChangeNotifications.groupChanged,
            object: nil)
    }
    
    @objc private func groupDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let group = userInfo[GroupChangeNotifications.userInfoGroupKey] as? Group else { return }
        observer?.groupDidChange(group: group)
    }

    /// Posts a notification about a group change
    static func post(groupDidChange group: Group) {
        NotificationCenter.default.post(
            name: GroupChangeNotifications.groupChanged,
            object: nil,
            userInfo: [
                GroupChangeNotifications.userInfoGroupKey: group
            ]
        )
    }
}
