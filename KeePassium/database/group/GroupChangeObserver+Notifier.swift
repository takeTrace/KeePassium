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
