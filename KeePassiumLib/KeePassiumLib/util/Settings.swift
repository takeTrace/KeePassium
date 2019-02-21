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

public protocol SettingsObserver: class {
    /// Called whenever settings have changed.
    /// Make sure to `subscribeToSettingsNotifications` first.
    func settingsDidChange(key: Settings.Keys)
}

public class SettingsNotifications {
    private weak var observer: SettingsObserver!
    
    public init(observer: SettingsObserver) {
        self.observer = observer
    }
    
    /// Starts observing notifications about settings changes.
    public func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange(_:)),
            name: Settings.Notifications.settingsChanged,
            object: nil)
    }
    
    /// Stops observing notifications about settings changes.
    public func stopObserving() {
        NotificationCenter.default.removeObserver(
            self,
            name: Settings.Notifications.settingsChanged,
            object: nil)
    }
    
    @objc private func settingsDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let keyString = userInfo[Settings.Notifications.userInfoKey] as? String else { return }
        
        guard let key = Settings.Keys(rawValue: keyString) else {
            assertionFailure("Unknown Settings.Keys value: \(keyString)")
            return
        }
        observer?.settingsDidChange(key: key)
    }
}

/// Singleton for KeePassium app settings.
public class Settings {
    public static let latestVersion = 3
    public static let current = Settings()
    
    public enum Keys: String {
        case settingsVersion
        case startupDatabase
        case appLockEnabled
        case appLockTimeout
        case databaseCloseTimeout
        case clipboardTimeout
        case entryListDetail
        case groupSortOrder
        case filesSortOrder
        case keepKeyFileAssociations
        case keyFileAssociations
        case startWithSearch
        case backupDatabaseOnSave
        case backupFilesVisible
        case biometricAppLockEnabled
        case rememberDatabaseKey
        case passwordGeneratorLength
        case passwordGeneratorIncludeLowerCase
        case passwordGeneratorIncludeUpperCase
        case passwordGeneratorIncludeSpecials
        case passwordGeneratorIncludeDigits
        case passwordGeneratorIncludeLookAlike
        case passcodeKeyboardType
        case recentUserActivityTimestamp
    }

    /// Notification constants
    fileprivate enum Notifications {
        static let settingsChanged = Notification.Name("com.keepassium.SettingsChanged")
        static let userInfoKey = "changedKey" // userInfo dict key - which Settings.Keys was changed
    }

    public enum AppLockTimeout: Int {
        public static let allValues = [
            immediately, /* after5seconds,*/ after15seconds, after30seconds,
            after1minute, after2minutes, after5minutes /*, never */]
        case never = -1
        case immediately = 0
        case after5seconds = 5
        case after15seconds = 15
        case after30seconds = 30
        case after1minute = 60
        case after2minutes = 120
        case after5minutes = 300
        
        public var seconds: Int {
            return self.rawValue
        }
        
        public var fullTitle: String {
            switch self {
            case .never:
                return NSLocalizedString("Never", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be full description. Will be shown as 'Timeouts: Lock Application: Never'")
            case .immediately:
                return NSLocalizedString("Immediately", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be full description. Will be shown as 'Timeouts: Lock Database: Immediately'")
            case .after5seconds:
                return NSLocalizedString("After 5 seconds", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be full description. Will be shown as 'Timeouts: Lock Application: After 5 seconds'")
            case .after15seconds:
                return NSLocalizedString("After 15 seconds", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be full description. Will be shown as 'Timeouts: Lock Application: After 15 seconds'")
            case .after30seconds:
                return NSLocalizedString("After 30 seconds", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be full description. Will be shown as 'Timeouts: Lock Application: After 30 seconds'")
            case .after1minute:
                return NSLocalizedString("After 1 minute", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be full description. Will be shown as 'Timeouts: Lock Application: After 1 minute'")
            case .after2minutes:
                return NSLocalizedString("After 2 minutes", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be full description. Will be shown as 'Timeouts: Lock Application: After 2 minutes'")
            case .after5minutes:
                return NSLocalizedString("After 5 minutes", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be full description. Will be shown as 'Timeouts: Lock Application: After 5 minutes'")
            }
        }
        public var shortTitle: String {
            switch self {
            case .never:
                return NSLocalizedString("Never", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be as a short version of 'Never'. Will be shown as 'Timeouts: Lock Application: Never'")
            case .immediately:
                return NSLocalizedString("Immediately", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be a short description of 'Immediately'. Will be shown as 'Timeouts: Lock Application: Immediately'")
            case .after5seconds:
                return NSLocalizedString("5 s", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be a short description of '(after) 5 seconds'. Will be shown as 'Timeouts: Lock Application: 5 s'")
            case .after15seconds:
                return NSLocalizedString("15 s", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be a short description of '(after) 15 seconds'. Will be shown as 'Timeouts: Lock Application: 15 s'")
            case .after30seconds:
                return NSLocalizedString("30 s", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be a short description of '(after) 30 seconds'. Will be shown as 'Timeouts: Lock Application: 30 s'")
            case .after1minute:
                return NSLocalizedString("1 min", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be a short description of '(after) 1 minute'. Will be shown as 'Timeouts: Lock Application: 1 min'")
            case .after2minutes:
                return NSLocalizedString("2 min", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be a short description of '(after) 2 minute'. Will be shown as 'Timeouts: Lock Application: 2 min'")
            case .after5minutes:
                return NSLocalizedString("5 min", comment: "One of the possible values of the 'Lock Application Timeout' setting. This should be a short description of '(after) 5 minutes'. Will be shown as 'Timeouts: Lock Application: 5 min'")
            }
        }
        public var description: String? {
            switch self {
            case .immediately:
                return NSLocalizedString("When leaving the app", comment: "A description for the 'Lock Application: Immediately'.")
            default:
                return nil
            }
        }
    }

    public enum DatabaseCloseTimeout: Int {
        public static let allValues = [
            immediately, /*after5seconds, after15seconds, */after30seconds,
            after1minute, after2minutes, after5minutes, after10minutes,
            after30minutes, after1hour, never]
        case never = -1
        case immediately = 0
        case after5seconds = 5
        case after15seconds = 15
        case after30seconds = 30
        case after1minute = 60
        case after2minutes = 120
        case after5minutes = 300
        case after10minutes = 600
        case after30minutes = 1800
        case after1hour = 3600

        public var seconds: Int {
            return self.rawValue
        }
        
        public var fullTitle: String {
            switch self {
            case .never:
                return NSLocalizedString("Never", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be full description. Will be shown as 'Timeouts: Close Database: Never'")
            case .immediately:
                return NSLocalizedString("Immediately", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be full description. Will be shown as 'Timeouts: Close Database: Immediately'")
            case .after5seconds:
                return NSLocalizedString("After 5 seconds", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be full description. Will be shown as 'Timeouts: Close Database: After 5 seconds'")
            case .after15seconds:
                return NSLocalizedString("After 15 seconds", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be full description. Will be shown as 'Timeouts: Close Database: After 15 seconds'")
            case .after30seconds:
                return NSLocalizedString("After 30 seconds", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be full description. Will be shown as 'Timeouts: Close Database: After 30 seconds'")
            case .after1minute:
                return NSLocalizedString("After 1 minute", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be full description. Will be shown as 'Timeouts: Close Database: After 1 minute'")
            case .after2minutes:
                return NSLocalizedString("After 2 minutes", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be full description. Will be shown as 'Timeouts: Close Database: After 2 minutes'")
            case .after5minutes:
                return NSLocalizedString("After 5 minutes", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be full description. Will be shown as 'Timeouts: Close Database: After 5 minutes'")
            case .after10minutes:
                return NSLocalizedString("After 10 minutes", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be full description. Will be shown as 'Timeouts: Close Database: After 10 minutes'")
            case .after30minutes:
                return NSLocalizedString("After 30 minutes", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be full description. Will be shown as 'Timeouts: Close Database: After 30 minutes'")
            case .after1hour:
                return NSLocalizedString("After 1 hour", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be full description. Will be shown as 'Timeouts: Close Database: After 1 hour'")
            }
        }
        public var shortTitle: String {
            switch self {
            case .never:
                return NSLocalizedString("Never", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be as a short version of 'Never'. Will be shown as 'Timeouts: Close Database: Never'")
            case .immediately:
                return NSLocalizedString("Immediately", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be a short description of 'Immediately'. Will be shown as 'Timeouts: Close Database: Immediately'")
            case .after5seconds:
                return NSLocalizedString("5 s", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be a short description of '(after) 5 seconds'. Will be shown as 'Timeouts: Close Database: 5 s'")
            case .after15seconds:
                return NSLocalizedString("15 s", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be a short description of '(after) 15 seconds'. Will be shown as 'Timeouts: Close Database: 15 s'")
            case .after30seconds:
                return NSLocalizedString("30 s", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be a short description of '(after) 30 seconds'. Will be shown as 'Timeouts: Close Database: 30 s'")
            case .after1minute:
                return NSLocalizedString("1 min", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be a short description of '(after) 1 minute'. Will be shown as 'Timeouts: Close Database: 1 min'")
            case .after2minutes:
                return NSLocalizedString("2 min", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be a short description of '(after) 2 minutes'. Will be shown as 'Timeouts: Close Database: 2 min'")
            case .after5minutes:
                return NSLocalizedString("5 min", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be a short description of '(after) 5 minutes'. Will be shown as 'Timeouts: Close Database: 5 min'")
            case .after10minutes:
                return NSLocalizedString("10 min", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be a short description of '(after) 10 minutes'. Will be shown as 'Timeouts: Close Database: 10 min'")
            case .after30minutes:
                return NSLocalizedString("30 min", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be a short description of '(after) 30 minutes'. Will be shown as 'Timeouts: Close Database: 30 min'")
            case .after1hour:
                return NSLocalizedString("1 hour", comment: "One of the possible values of the 'Close Database Timeout' setting. This should be a short description of '(after) 1 hour'. Will be shown as 'Timeouts: Close Database: 1 hour'")
            }
        }
        public var description: String? {
            switch self {
            case .immediately:
                return NSLocalizedString("When leaving the app", comment: "A description for the 'Close Database: Immediately'.")
            default:
                return nil
            }
        }
    }
    
    public enum ClipboardTimeout: Int {
        public static let allValues =
            [after10seconds, after20seconds, after30seconds, after1minute, after2minutes, never]
        case never = -1
        case after10seconds = 10
        case after20seconds = 20
        case after30seconds = 30
        case after1minute = 60
        case after2minutes = 120
        
        public var seconds: Int {
            return self.rawValue
        }
        
        public var fullTitle: String {
            switch self {
            case .never:
                return NSLocalizedString("Never", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be full description. Will be shown as 'Clear Clipboard: Never'")
            case .after10seconds:
                return NSLocalizedString("After 10 seconds", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be full description. Will be shown as 'Clear Clipboard: After 10 seconds'")
            case .after20seconds:
                return NSLocalizedString("After 20 seconds", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be full description. Will be shown as 'Clear Clipboard: After 20 seconds'")
            case .after30seconds:
                return NSLocalizedString("After 30 seconds", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be full description. Will be shown as 'Clear Clipboard: After 30 seconds'")
            case .after1minute:
                return NSLocalizedString("After 1 minute", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be full description. Will be shown as 'Clear Clipboard: After 1 minute'")
            case .after2minutes:
                return NSLocalizedString("After 5 minutes", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be full description. Will be shown as 'Clear Clipboard: After 2 minutes'")
            }
        }
        public var shortTitle: String {
            switch self {
            case .never:
                return NSLocalizedString("Never", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be a short version of 'Never'. Will be shown as 'Clear Clipboard: Never'")
            case .after10seconds:
                return NSLocalizedString("10 s", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be a short version of 'After 5 seconds'. Will be shown as 'Clear Clipboard: 10 s'")
            case .after20seconds:
                return NSLocalizedString("20 s", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be a short version of 'After 20 seconds'. Will be shown as 'Clear Clipboard: 20 s'")
            case .after30seconds:
                return NSLocalizedString("30 s", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be a short version of 'After 30 seconds'. Will be shown as 'Clear Clipboard: 30 s'")
            case .after1minute:
                return NSLocalizedString("1 min", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be a short version of 'After 1 minute'. Will be shown as 'Clear Clipboard: 1 min'")
            case .after2minutes:
                return NSLocalizedString("2 min", comment: "One of the possible values of the 'Clear Clipboard Timeout' setting. This should be a short version of 'After 2 minutes'. Will be shown as 'Clear Clipboard: 2 min'")
            }
        }
    }
    
    /// Info to show in the second line of entry lsists
    public enum EntryListDetail: Int {
        public static let allValues = [none, userName, password, url, notes, lastModifiedDate]
        
        case none
        case userName
        case password
        case url
        case notes
        case lastModifiedDate
        
        public var shortTitle: String {
            return longTitle
        }
        public var longTitle: String {
            switch self {
            case .none:
                return NSLocalizedString("None", comment: "One of the possible values of the 'Entry List Details' setting. Will be shown as 'Entry List Details   None', meaningin that no entry details will be shown in any lists.")
            case .userName:
                return NSLocalizedString("User Name", comment: "One of the possible values of the 'Entry List Details' setting; it refers to login information rather than person name. Will be shown as 'Entry List Details   User Name'.")
            case .password:
                return NSLocalizedString("Password", comment: "One of the possible values of the 'Entry List Details' setting. Will be shown as 'Entry List Details   Password'.")
            case .url:
                return NSLocalizedString("URL", comment: "One of the possible values of the 'Entry List Details' setting. URL stands for 'internet address' or 'internet link'. Will be shown as 'Entry List Details   URL'.")
            case .notes:
                return NSLocalizedString("Notes", comment: "One of the possible values of the 'Entry List Details' setting; it refers to comments or additional text information contained in an entry. Will be shown as 'Entry List Details   Notes'.")
            case .lastModifiedDate:
                return NSLocalizedString("Last Modified Date", comment: "One of the possible values of the 'Entry List Details' setting; it referst fo the most recent time when the entry was modified. Will be shown as 'Entry List Details   Last Modified Time'.")
            }
        }
    }

    /// Sort order of group lists
    public enum GroupSortOrder: Int {
        public static let allValues = [
            noSorting,
            nameAsc, nameDesc,
            creationTimeDesc, creationTimeAsc,
            modificationTimeDesc, modificationTimeAsc]
        
        case noSorting
        case nameAsc
        case nameDesc
        case creationTimeAsc
        case creationTimeDesc
        case modificationTimeAsc
        case modificationTimeDesc
        
        public var longTitle: String {
            switch self {
            case .noSorting:
                return NSLocalizedString("No Sorting", comment: "One of possible values of the 'Sort Groups By' setting (full title). Example: 'Sort Groups: No Sorting'")
            case .nameAsc:
                return NSLocalizedString("By Title (A..Z)", comment: "One of possible values of the 'Sort Groups By' setting (full title). Example: 'Sort Groups: By Title (A..Z)'")
            case .nameDesc:
                return NSLocalizedString("By Title (Z..A)", comment: "One of possible values of the 'Sort Groups By' setting (full title). Example: 'Sort Groups: By Title (Z..A)'")
            case .creationTimeAsc:
                return NSLocalizedString("By Creation Date (Old..New)", comment: "One of possible values of the 'Sort Groups By' setting (full title). Example: 'Sort Groups: By Creation Date (Old..New)'")
            case .creationTimeDesc:
                return NSLocalizedString("By Creation Date (New..Old)", comment: "One of possible values of the 'Sort Groups By' setting (full title). Example: 'Sort Groups: By Creation Date (New..Old)'")
            case .modificationTimeAsc:
                return NSLocalizedString("By Modification Date (Old..New)", comment: "One of possible values of the 'Sort Groups By' setting (full title). Example: 'Sort Groups: By Modification Date (Old..New)'")
            case .modificationTimeDesc:
                return NSLocalizedString("By Modification Date (New..Old)", comment:  "One of possible values of the 'Sort Groups By' setting (full title). Example: 'Sort Groups: By Modification Date (New..Old)'")
            }
        }
        public var shortTitle: String {
            switch self {
            case .noSorting:
                return NSLocalizedString("None", comment: "One of possible values of the 'Sort Groups By' setting (short title for 'No Sorting'). Example: 'Sort Groups: None'")
            case .nameAsc:
                return NSLocalizedString("A..Z", comment: "One of possible values of the 'Sort Groups By' setting (short title for 'Title (A..Z)'). Example: 'Sort Groups: A..Z'")
            case .nameDesc:
                return NSLocalizedString("Z..A", comment: "One of possible values of the 'Sort Groups By' setting (short title for 'Title (Z..A)'). Example: 'Sort Groups: Z..A'")
            case .creationTimeAsc:
                return NSLocalizedString("Creation Date", comment: "One of possible values of the 'Sort Groups By' setting (short title for 'By Creation Date (Old..New)'). Example: 'Sort Groups: Creation Date'")
            case .creationTimeDesc:
                return NSLocalizedString("Creation Date", comment: "One of possible values of the 'Sort Groups By' setting (short title for 'By Creation Date (New..Old)'). Example: 'Sort Groups: Creation Date'")
            case .modificationTimeAsc:
                return NSLocalizedString("Last Modified", comment: "One of possible values of the 'Sort Groups By' setting (short title for 'By Modification Date (Old..New)'). Example: 'Sort Groups: Last Modified'")
            case .modificationTimeDesc:
                return NSLocalizedString("Last Modified", comment: "One of possible values of the 'Sort Groups By' setting (short title for 'By Modification Date (New..Old)'). Example: 'Sort Groups: Last Modified'")
            }
        }
        /// Comparator function for sorting
        public func compare(_ group1: Group, _ group2: Group) -> Bool {
            switch self {
            case .noSorting:
                return false
            case .nameAsc:
                return group1.name.localizedStandardCompare(group2.name) == .orderedAscending
            case .nameDesc:
                return group1.name.localizedStandardCompare(group2.name) == .orderedDescending
            case .creationTimeAsc:
                return group1.creationTime.compare(group2.creationTime) == .orderedAscending
            case .creationTimeDesc:
                return group1.creationTime.compare(group2.creationTime) == .orderedDescending
            case .modificationTimeAsc:
                return group1.lastModificationTime.compare(group2.lastModificationTime) == .orderedAscending
            case .modificationTimeDesc:
                return group1.lastModificationTime.compare(group2.lastModificationTime) == .orderedDescending
            }
        }
        public func compare(_ entry1: Entry, _ entry2: Entry) -> Bool {
            switch self {
            case .noSorting:
                return false
            case .nameAsc:
                return entry1.title.localizedStandardCompare(entry2.title) == .orderedAscending
            case .nameDesc:
                return entry1.title.localizedStandardCompare(entry1.title) == .orderedDescending
            case .creationTimeAsc:
                return entry1.creationTime.compare(entry2.creationTime) == .orderedAscending
            case .creationTimeDesc:
                return entry1.creationTime.compare(entry2.creationTime) == .orderedDescending
            case .modificationTimeAsc:
                return entry1.lastModificationTime.compare(entry2.lastModificationTime) == .orderedAscending
            case .modificationTimeDesc:
                return entry1.lastModificationTime.compare(entry2.lastModificationTime) == .orderedDescending
            }
        }
    }
    
    /// Sort order of file lists
    public enum FilesSortOrder: Int {
        public static let allValues = [
            noSorting,
            nameAsc, nameDesc,
            creationTimeDesc, creationTimeAsc,
            modificationTimeDesc, modificationTimeAsc]
        
        case noSorting
        case nameAsc
        case nameDesc
        case creationTimeAsc
        case creationTimeDesc
        case modificationTimeAsc
        case modificationTimeDesc
        
        public var longTitle: String {
            switch self {
            case .noSorting:
                return NSLocalizedString("No Sorting", comment: "A settings option which defines sorting of items in lists. Example: 'Sort order   No Sorting'")
            case .nameAsc:
                return NSLocalizedString("Name (A..Z)", comment: "One of the possible values of the 'File Sort Order' setting. Will be displayed as 'File Sort Order: Name (A..Z)'")
            case .nameDesc:
                return NSLocalizedString("Name (Z..A)", comment: "One of the possible values of the 'File Sort Order' setting. Will be displayed as 'File Sort Order: Name (Z..A)'")
            case .creationTimeAsc:
                return NSLocalizedString("Date Created (Oldest First)", comment: "One of the possible values of the 'File Sort Order' setting. Will be displayed as 'File Sort Order: Date Created (Oldest First)")
            case .creationTimeDesc:
                return NSLocalizedString("Date Created (Recent First)", comment: "One of the possible values of the 'File Sort Order' setting. Will be displayed as 'File Sort Order: Date Created (Recent First)'")
            case .modificationTimeAsc:
                return NSLocalizedString("Date Modified (Oldest First)", comment: "One of the possible values of the 'File Sort Order' setting. Will be displayed as 'File Sort Order: Date Modified (Oldest First)'")
            case .modificationTimeDesc:
                return NSLocalizedString("Date Modified (Recent First)", comment: "One of the possible values of the 'File Sort Order' setting. Will be displayed as 'File Sort Order: Date Modified (Recent First)'")
            }
        }

        /// Comparator function for sorting.
        public func compare(_ lhs: URLReference, _ rhs: URLReference) -> Bool {
            switch self {
            case .noSorting:
                return false
            case .nameAsc:
                return lhs.info.fileName.localizedCaseInsensitiveCompare(rhs.info.fileName) == .orderedAscending
            case .nameDesc:
                return lhs.info.fileName.localizedCaseInsensitiveCompare(rhs.info.fileName) == .orderedDescending
            case .creationTimeAsc:
                guard let date1 = lhs.info.creationDate,
                    let date2 = rhs.info.creationDate else { return false }
                return date1.compare(date2) == .orderedAscending
            case .creationTimeDesc:
                guard let date1 = lhs.info.creationDate,
                    let date2 = rhs.info.creationDate else { return false }
                return date1.compare(date2) == .orderedDescending
            case .modificationTimeAsc:
                guard let date1 = lhs.info.modificationDate,
                    let date2 = rhs.info.modificationDate else { return false }
                return date1.compare(date2) == .orderedAscending
            case .modificationTimeDesc:
                guard let date1 = lhs.info.modificationDate,
                    let date2 = rhs.info.modificationDate else { return false }
                return date1.compare(date2) == .orderedDescending
            }
        }
    }
    
    /// Type of keyboard to use for App Lock passcode
    public enum PasscodeKeyboardType: Int {
        public static let allValues = [numeric, alphanumeric]
        case numeric
        case alphanumeric
        public var title: String {
            switch self {
            case .numeric:
                return NSLocalizedString("Numeric", comment: "Type of keyboard to show for App Lock passcode: digits-only.")
            case .alphanumeric:
                return NSLocalizedString("Alphanumeric", comment: "Type of keyboard to show for App Lock passcode: letters and digits.")
            }
        }
    }
    
    public var settingsVersion: Int {
        get {
            let storedVersion = UserDefaults.appGroupShared
                .object(forKey: Keys.settingsVersion.rawValue)
                as? Int
            return storedVersion ?? 0
        }
        set {
            let oldValue = settingsVersion
            UserDefaults.appGroupShared.set(newValue, forKey: Keys.settingsVersion.rawValue)
            if newValue != oldValue {
                postChangeNotification(changedKey: Keys.settingsVersion)
            }
        }
    }
    
    /// Last used/default database file to open on app launch.
    public var startupDatabase: URLReference? {
        get {
            if let data = UserDefaults.appGroupShared.data(forKey: Keys.startupDatabase.rawValue) {
                return URLReference.deserialize(from: data)
            } else {
                return nil
            }
        }
        set {
            let oldValue = startupDatabase
            UserDefaults.appGroupShared.set(
                newValue?.serialize(),
                forKey: Keys.startupDatabase.rawValue)
            if newValue != oldValue {
                postChangeNotification(changedKey: Keys.startupDatabase)
            }
        }
    }

    /// Should we keep track of which key file is used with which database?
    public var isKeepKeyFileAssociations: Bool {
        get {
            if contains(key: Keys.keepKeyFileAssociations) {
                return UserDefaults.appGroupShared.bool(forKey: Keys.keepKeyFileAssociations.rawValue)
            } else {
                return true
            }
        }
        set {
            let oldValue = isKeepKeyFileAssociations
            UserDefaults.appGroupShared.set(newValue, forKey: Keys.keepKeyFileAssociations.rawValue)
            if !newValue {
                // clear existing associations
                UserDefaults.appGroupShared.setValue(
                    Dictionary<String, Data>(),
                    forKey: Keys.keyFileAssociations.rawValue)
            }
            if newValue != oldValue {
                postChangeNotification(changedKey: Keys.keepKeyFileAssociations)
            }
        }
    }
    
    /// Returns a URL reference to the key file last used with the given database.
    public func getKeyFileForDatabase(databaseRef: URLReference) -> URLReference? {
        guard let db2key = UserDefaults.appGroupShared
            .dictionary(forKey: Keys.keyFileAssociations.rawValue) else { return nil }
        
        let databaseID = databaseRef.info.fileName
        if let keyFileRefData = db2key[databaseID] as? Data {
            return URLReference.deserialize(from: keyFileRefData)
        } else { 
            return nil
        }
    }
    
    /// Associates given keyFile as the one used with the given database,
    /// (if enabled by `keepKeyFileAssociations`, otherwise does nothing).
    public func setKeyFileForDatabase(databaseRef: URLReference, keyFileRef: URLReference?) {
        guard isKeepKeyFileAssociations else { return }
        var db2key: Dictionary<String, Data> = [:]
        if let storedDict = UserDefaults.appGroupShared
            .dictionary(forKey: Keys.keyFileAssociations.rawValue)
        {
            for (storedDatabaseID, storedKeyFileRefData) in storedDict {
                guard let storedKeyFileRefData = storedKeyFileRefData as? Data else { continue }
                db2key[storedDatabaseID] = storedKeyFileRefData
            }
        }
        
        let databaseID = databaseRef.info.fileName
        db2key[databaseID] = keyFileRef?.serialize()
        UserDefaults.appGroupShared.setValue(db2key, forKey: Keys.keyFileAssociations.rawValue)
        postChangeNotification(changedKey: Keys.keyFileAssociations)
    }
    
    /// Removes any database associations with the given key file.
    public func forgetKeyFile(_ keyFileRef: URLReference) {
        guard isKeepKeyFileAssociations else { return }
        var db2key = Dictionary<String, Data>()
        if let storedDict = UserDefaults.appGroupShared
            .dictionary(forKey: Keys.keyFileAssociations.rawValue)
        {
            for (storedDatabaseID, storedKeyFileRefData) in storedDict {
                guard let storedKeyFileRefData = storedKeyFileRefData as? Data else { continue }
                if keyFileRef != URLReference.deserialize(from: storedKeyFileRefData) {
                    db2key[storedDatabaseID] = storedKeyFileRefData
                }
            }
        }
        UserDefaults.appGroupShared.setValue(db2key, forKey: Keys.keyFileAssociations.rawValue)
    }
    
    public var isAppLockEnabled: Bool {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.appLockEnabled.rawValue)
                as? Bool
            return stored ?? false
        }
        set {
            updateAndNotify(
                oldValue: isAppLockEnabled,
                newValue: newValue,
                key: .appLockEnabled)
        }
    }
    /// Timeout for automatically locking the app, in seconds.
    public var appLockTimeout: AppLockTimeout {
        get {
            if let rawValue = UserDefaults.appGroupShared
                    .object(forKey: Keys.appLockTimeout.rawValue) as? Int,
                let timeout = AppLockTimeout(rawValue: rawValue)
            {
                return timeout
            }
            return AppLockTimeout.immediately
        }
        set {
            let oldValue = appLockTimeout
            UserDefaults.appGroupShared.set(newValue.rawValue, forKey: Keys.appLockTimeout.rawValue)
            if newValue != oldValue {
                postChangeNotification(changedKey: Keys.appLockTimeout)
            }
        }
    }
    
    /// Timeout for automatically closing the database, in seconds.
    public var databaseCloseTimeout: DatabaseCloseTimeout {
        get {
            if let rawValue = UserDefaults.appGroupShared
                    .object(forKey: Keys.databaseCloseTimeout.rawValue) as? Int,
                let timeout = DatabaseCloseTimeout(rawValue: rawValue)
            {
                return timeout
            }
            return DatabaseCloseTimeout.after1hour
        }
        set {
            let oldValue = databaseCloseTimeout
            UserDefaults.appGroupShared.set(
                newValue.rawValue,
                forKey: Keys.databaseCloseTimeout.rawValue)
            if newValue != oldValue {
                postChangeNotification(changedKey: Keys.databaseCloseTimeout)
            }
        }
    }
    
    /// Timeout for temporary clipboard content, in seconds.
    public var clipboardTimeout: ClipboardTimeout {
        get {
            if let rawValue = UserDefaults.appGroupShared
                    .object(forKey: Keys.clipboardTimeout.rawValue) as? Int,
                let timeout = ClipboardTimeout(rawValue: rawValue)
            {
                return timeout
            }
            return ClipboardTimeout.after1minute
        }
        set {
            let oldValue = clipboardTimeout
            UserDefaults.appGroupShared.set(newValue.rawValue, forKey: Keys.clipboardTimeout.rawValue)
            if newValue != oldValue {
                postChangeNotification(changedKey: Keys.clipboardTimeout)
            }
        }
    }
    
    /// Which field to use for entry subtitles in ViewGroupVC
    public var entryListDetail: EntryListDetail {
        get {
            if let rawValue = UserDefaults.appGroupShared
                    .object(forKey: Keys.entryListDetail.rawValue) as? Int,
                let detail = EntryListDetail(rawValue: rawValue)
            {
                return detail
            }
            return EntryListDetail.userName
        }
        set {
            let oldValue = entryListDetail
            UserDefaults.appGroupShared.set(newValue.rawValue, forKey: Keys.entryListDetail.rawValue)
            if newValue != oldValue {
                postChangeNotification(changedKey: Keys.entryListDetail)
            }
        }
    }
    
    /// Which field to use for entry subtitles in ViewGroupVC
    public var groupSortOrder: GroupSortOrder {
        get {
            if let rawValue = UserDefaults.appGroupShared
                    .object(forKey: Keys.groupSortOrder.rawValue) as? Int,
                let sortOrder = GroupSortOrder(rawValue: rawValue)
            {
                return sortOrder
            }
            return GroupSortOrder.noSorting
        }
        set {
            let oldValue = groupSortOrder
            UserDefaults.appGroupShared.set(newValue.rawValue, forKey: Keys.groupSortOrder.rawValue)
            if newValue != oldValue {
                postChangeNotification(changedKey: Keys.groupSortOrder)
            }
        }
    }

    /// Sort order for the file lists
    public var filesSortOrder: FilesSortOrder {
        get {
            if let rawValue = UserDefaults.appGroupShared
                    .object(forKey: Keys.filesSortOrder.rawValue) as? Int,
                let sortOrder = FilesSortOrder(rawValue: rawValue)
            {
                return sortOrder
            }
            return FilesSortOrder.noSorting
        }
        set {
            let oldValue = filesSortOrder
            UserDefaults.appGroupShared.set(newValue.rawValue, forKey: Keys.filesSortOrder.rawValue)
            if newValue != oldValue {
                postChangeNotification(changedKey: Keys.filesSortOrder)
            }
        }
    }

    /// Whether to create a backup copy everytime database is saved.
    public var isBackupDatabaseOnSave: Bool {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.backupDatabaseOnSave.rawValue)
                as? Bool
            return stored ?? true
        }
        set {
            updateAndNotify(
                oldValue: isBackupDatabaseOnSave,
                newValue: newValue,
                key: .backupDatabaseOnSave)
        }
    }
    
    /// Whether to show backup files in file lists
    public var isBackupFilesVisible: Bool {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.backupFilesVisible.rawValue)
                as? Bool
            return stored ?? false
        }
        set {
            updateAndNotify(
                oldValue: isBackupFilesVisible,
                newValue: newValue,
                key: .backupFilesVisible)
        }
    }
    
    /// Automatically show search bar after opening a database.
    public var isStartWithSearch: Bool {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.startWithSearch.rawValue)
                as? Bool
            return stored ?? false
        }
        set {
            updateAndNotify(
                oldValue: isStartWithSearch,
                newValue: newValue,
                key: .startWithSearch)
        }
    }
    
    /// Whether the user can use TouchID/FaceID to unlock the app
    public var isBiometricAppLockEnabled: Bool {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.biometricAppLockEnabled.rawValue)
                as? Bool
            return stored ?? true
        }
        set {
            updateAndNotify(
                oldValue: isBiometricAppLockEnabled,
                newValue: newValue,
                key: .biometricAppLockEnabled)
        }
    }

    /// Whether to store database's key in keychain after unlock
    public var isRememberDatabaseKey: Bool {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.rememberDatabaseKey.rawValue)
                as? Bool
            return stored ?? false
        }
        set {
            updateAndNotify(
                oldValue: isRememberDatabaseKey,
                newValue: newValue,
                key: .rememberDatabaseKey)
        }
    }
    
    /// Timestamp of most recent user activity event (touching or typing).
    public var recentUserActivityTimestamp: Date {
        get {
            if let storedTimestamp = UserDefaults.appGroupShared
                .object(forKey: Keys.recentUserActivityTimestamp.rawValue)
                as? Date
            {
                return storedTimestamp
            }
            return Date.now
        }
        set {
            if contains(key: Keys.recentUserActivityTimestamp) {
                // We'll ignore sub-second differences, just to avoid too frequent writes.
                // (They are probably cached, but anyway.)
                let oldWholeSeconds = floor(recentUserActivityTimestamp.timeIntervalSinceReferenceDate)
                let newWholeSeconds = floor(newValue.timeIntervalSinceReferenceDate)
                if newWholeSeconds == oldWholeSeconds {
                    return
                }
            }
            UserDefaults.appGroupShared.set(
                newValue,
                forKey: Keys.recentUserActivityTimestamp.rawValue)
            postChangeNotification(changedKey: Keys.recentUserActivityTimestamp)
        }
    }
    
    /// Password generator: length of generated passwords
    public var passwordGeneratorLength: Int {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.passwordGeneratorLength.rawValue)
                as? Int
            return stored ?? PasswordGenerator.defaultLength
        }
        set {
            updateAndNotify(
                oldValue: passwordGeneratorLength,
                newValue: newValue,
                key: .passwordGeneratorLength)
        }
    }
    public var passwordGeneratorIncludeLowerCase: Bool {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.passwordGeneratorIncludeLowerCase.rawValue)
                as? Bool
            return stored ?? true
        }
        set {
            updateAndNotify(
                oldValue: passwordGeneratorIncludeLowerCase,
                newValue: newValue,
                key: .passwordGeneratorIncludeLowerCase)
        }
    }
    public var passwordGeneratorIncludeUpperCase: Bool {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.passwordGeneratorIncludeUpperCase.rawValue)
                as? Bool
            return stored ?? true
        }
        set {
            updateAndNotify(
                oldValue: passwordGeneratorIncludeUpperCase,
                newValue: newValue,
                key: .passwordGeneratorIncludeUpperCase)
        }
    }
    public var passwordGeneratorIncludeSpecials: Bool {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.passwordGeneratorIncludeSpecials.rawValue)
                as? Bool
            return stored ?? true
        }
        set {
            updateAndNotify(
                oldValue: passwordGeneratorIncludeSpecials,
                newValue: newValue,
                key: .passwordGeneratorIncludeSpecials)
        }
    }
    public var passwordGeneratorIncludeDigits: Bool {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.passwordGeneratorIncludeDigits.rawValue)
                as? Bool
            return stored ?? true
        }
        set {
            updateAndNotify(
                oldValue: passwordGeneratorIncludeDigits,
                newValue: newValue,
                key: .passwordGeneratorIncludeDigits)
        }
    }
    public var passwordGeneratorIncludeLookAlike: Bool {
        get {
            let stored = UserDefaults.appGroupShared
                .object(forKey: Keys.passwordGeneratorIncludeLookAlike.rawValue)
                as? Bool
            return stored ?? false
        }
        set {
            updateAndNotify(
                oldValue: passwordGeneratorIncludeLookAlike,
                newValue: newValue,
                key: .passwordGeneratorIncludeLookAlike)
        }
    }
    
    /// Type of keyboard to show for App Lock passcode.
    public var passcodeKeyboardType: PasscodeKeyboardType {
        get {
            if let rawValue = UserDefaults.appGroupShared
                .object(forKey: Keys.passcodeKeyboardType.rawValue) as? Int,
                let keyboardType = PasscodeKeyboardType(rawValue: rawValue)
            {
                return keyboardType
            }
            return PasscodeKeyboardType.numeric
        }
        set {
            let oldValue = passcodeKeyboardType
            UserDefaults.appGroupShared.set(newValue.rawValue, forKey: Keys.passcodeKeyboardType.rawValue)
            if newValue != oldValue {
                postChangeNotification(changedKey: Keys.passcodeKeyboardType)
            }
        }
    }
    
    private init() {
        // nothing to do
    }

    /// Updates stored value, and notifies observers if the new value is different.
    private func updateAndNotify(oldValue: Bool, newValue: Bool, key: Keys) {
        UserDefaults.appGroupShared.set(newValue, forKey: key.rawValue)
        if newValue != oldValue {
            postChangeNotification(changedKey: key)
        }
    }

    /// Updates stored value, and notifies observers if the new value is different.
    private func updateAndNotify(oldValue: Int, newValue: Int, key: Keys) {
        UserDefaults.appGroupShared.set(newValue, forKey: key.rawValue)
        if newValue != oldValue {
            postChangeNotification(changedKey: key)
        }
    }

    /// Checks if given key is present in UserDefaults
    private func contains(key: Keys) -> Bool {
        return UserDefaults.appGroupShared.object(forKey: key.rawValue) != nil
    }

    /// Sends a notification about settigns change.
    fileprivate func postChangeNotification(changedKey: Settings.Keys) {
        NotificationCenter.default.post(
            name: Notifications.settingsChanged,
            object: self,
            userInfo: [
                Notifications.userInfoKey: changedKey.rawValue
            ]
        )
    }
}
