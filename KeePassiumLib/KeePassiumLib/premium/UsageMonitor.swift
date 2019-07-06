//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation

/// App usage stats history since first launch: [daysSinceReferenceDate: appUseDuration]
public typealias DailyAppUsageHistory = [Int: TimeInterval]

public class UsageMonitor {
    /// Defines the time interval for which to report the use duration.
    public enum ReportType {
        case perMonth
        case perYear

        fileprivate var scale: Double {
            switch self {
            case .perMonth:
                return 1.0
            case .perYear:
                return 12.0
            }
        }
    }
    
    private let appUseDurationKey = "dailyAppUsageDuration"
    private var startTime: Date?

    /// Start of time for statistics
    private let referenceDate = Date(timeIntervalSinceReferenceDate: 0.0)
    
    /// Number of history entries to keep (possibly sparse)
    private let maxHistoryLength = 30
    
    private var cachedUsageDuration = 0.0
    private var cachedUsageDurationNeedUpdate = true
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startInterval),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopInterval),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        cleanupObsoleteData()
    }
    
    private var isMonitoringEnabled: Bool {
        switch PremiumManager.shared.status {
        case .initialGracePeriod,
             .subscribed:
            return false
        case .lapsed, // keeping count in case it will never be renewed
             .freeLightUse,
             .freeHeavyUse:
            return true
        }
    }
    
    // MARK: - Start/stop event handlers
    
    /// Starts counting the time of a use interval.
    @objc public func startInterval() {
        if isMonitoringEnabled {
            startTime = Date.now
        } else {
            // don't monitor
            startTime = nil
        }
    }
    
    /// Updates the time counter to account for the ongoing use.
    public func refresh() {
        guard startTime != nil else { return } // time monitoring is not active
        
        stopInterval()
        startInterval()
    }
    
    /// Stops counting the time of a use interval.
    @objc public func stopInterval() {
        guard let startTime = startTime else { return }
        let endTime = Date.now
        let secondsElapsed = abs(endTime.timeIntervalSince(startTime))
        self.startTime = nil // block successive calls to stopInterval()
        
        var history = loadHistoryData()
        let todaysIndex = daysSinceReferenceDate(date: endTime)
        let todaysUsage = history[todaysIndex] ?? 0.0
        history[todaysIndex] = todaysUsage + secondsElapsed
        saveHistoryData(history)
        
        Diag.verbose(String(format: "Usage time added: %.1f s", secondsElapsed))
    }
    
    // MARK: - Stats reports
    
    /// Returns app usage duration over the last `maxHistoryLength` days.
    /// Can be expensive, but results are cached for subsequent calls.
    public func getAppUsageDuration(_ reportType: ReportType) -> TimeInterval {
        guard cachedUsageDurationNeedUpdate else {
            return cachedUsageDuration * reportType.scale
        }

        cachedUsageDuration = 0.0
        cachedUsageDurationNeedUpdate = false
        let history = loadHistoryData()
        let from = daysSinceReferenceDate(date: Date.now) - maxHistoryLength
        history.forEach { (dayIndex, dayUsage) in
            // no limit in the future, to avoid "rewind the clock" abuse
            guard dayIndex > from else { return }
            cachedUsageDuration += dayUsage
        }
        return cachedUsageDuration * reportType.scale
    }
    
    /// Converts the `date` to an index for the DailyUsageStatsHistory,
    /// aka number of days since the reference date.
    private func daysSinceReferenceDate(date: Date) -> Int {
        let calendar = Calendar.current
        guard let days = calendar.dateComponents([.day], from: referenceDate, to: date).day else {
            assertionFailure()
            return 0
        }
        return days
    }
    
    // MARK: - Persistant storage
    
    private func loadHistoryData() -> DailyAppUsageHistory {
        guard let historyData = UserDefaults.appGroupShared.data(forKey: appUseDurationKey) else {
            // probably first launch, make a fresh history
            return DailyAppUsageHistory()
        }
        guard let history = NSKeyedUnarchiver.unarchiveObject(with: historyData)
            as? DailyAppUsageHistory else
        {
            assertionFailure()
            Diag.warning("Failed to parse history data, ignoring.")
            return DailyAppUsageHistory()
        }
        return history
    }
    
    private func saveHistoryData(_ history: DailyAppUsageHistory) {
        let historyData = NSKeyedArchiver.archivedData(withRootObject: history)
        UserDefaults.appGroupShared.set(historyData, forKey: appUseDurationKey)
        cachedUsageDurationNeedUpdate = true
    }
    
    /// Removes excessive old history entries.
    private func cleanupObsoleteData() {
        let history = loadHistoryData()
        guard history.keys.count > maxHistoryLength else {
            // too small to bother
            return
        }
        
        let earliestDayIndexToKeep = daysSinceReferenceDate(date: Date.now) - maxHistoryLength
        // now remove all entries that are older than trimmingDaystamp
        let trimmedHistory = history.filter { (dayIndex, dayUsage) in
            let shouldKeep = dayIndex < earliestDayIndexToKeep
            return shouldKeep
        }
        Diag.debug("Usage stats trimmed from \(history.keys.count) to \(trimmedHistory.keys.count) entries")
        saveHistoryData(trimmedHistory)
    }
    
    #if DEBUG
    /// Clears the daily usage statistics.
    public func resetStats() {
        let emptyHistory = DailyAppUsageHistory()
        saveHistoryData(emptyHistory)
    }
    #endif
}
