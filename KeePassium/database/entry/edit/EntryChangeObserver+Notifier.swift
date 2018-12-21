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

protocol EntryChangeObserver: class {
    /// Called when there is a notification about an entry change
    func entryDidChange(entry: Entry)
}

class EntryChangeNotifications {
    private static let entryChanged = Notification.Name("com.keepassium.EntryChanged")
    private static let userInfoEntryKey = "ChangedEntry"
    
    private weak var observer: EntryChangeObserver?
    
    init(observer: EntryChangeObserver) {
        self.observer = observer
    }
    
    func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(entryDidChange(_:)),
            name: EntryChangeNotifications.entryChanged,
            object: nil)
    }
    
    func stopObserving() {
        NotificationCenter.default.removeObserver(
            self,
            name: EntryChangeNotifications.entryChanged,
            object: nil)
    }

    @objc func entryDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let entry = userInfo[EntryChangeNotifications.userInfoEntryKey] as? Entry else { return }
        
        observer?.entryDidChange(entry: entry)
    }
    
    /// Posts a notification about an entry change
    static func post(entryDidChange entry: Entry) {
        let userInfo = [EntryChangeNotifications.userInfoEntryKey: entry]
        NotificationCenter.default.post(
            name: EntryChangeNotifications.entryChanged,
            object: nil,
            userInfo: userInfo)
    }
}
