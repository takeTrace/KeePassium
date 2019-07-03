//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit
import KeePassiumLib
import LocalAuthentication

class SettingsVC: UITableViewController, Refreshable {
    @IBOutlet weak var startWithSearchSwitch: UISwitch!

    @IBOutlet weak var appSafetyCell: UITableViewCell!
    @IBOutlet weak var dataSafetyCell: UITableViewCell!
    @IBOutlet weak var dataBackupCell: UITableViewCell!
    @IBOutlet weak var autoFillCell: UITableViewCell!
    
    @IBOutlet weak var diagnosticLogCell: UITableViewCell!
    @IBOutlet weak var contactSupportCell: UITableViewCell!
    @IBOutlet weak var rateTheAppCell: UITableViewCell!
    @IBOutlet weak var aboutAppCell: UITableViewCell!
    
    @IBOutlet weak var premiumTrialCell: UITableViewCell!
    @IBOutlet weak var premiumStatusCell: UITableViewCell!
    @IBOutlet weak var restorePurchasesCell: UITableViewCell!
    @IBOutlet weak var manageSubscriptionCell: UITableViewCell!
    
    private var settingsNotifications: SettingsNotifications!
    
    /// For static cells that can hide/appear dynamically
    private enum CellIndexPath {
        static let premiumTrial = IndexPath(row: 0, section: 4)
        static let premiumStatus = IndexPath(row: 1, section: 4)
        static let restorePurchase = IndexPath(row: 2, section: 4)
        static let manageSubscription = IndexPath(row: 3, section: 4)
    }
    /// Indices of hidden cells (for now set only in refreshPremiumStatus)
    private var hiddenIndexPaths = Set<IndexPath>()
    
    static func make(popoverFromBar barButtonSource: UIBarButtonItem?=nil) -> UIViewController {
        let vc = SettingsVC.instantiateFromStoryboard()
        
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .popover
        if let popover = navVC.popoverPresentationController {
            popover.barButtonItem = barButtonSource
        }
        return navVC
    }

    // MARK: - VC life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        
        settingsNotifications = SettingsNotifications(observer: self)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshPremiumStatus),
            name: PremiumManager.statusUpdateNotification,
            object: nil)
        refreshPremiumStatus(animated: false)
        #if DEBUG
        premiumStatusCell.accessoryType = .detailButton
        premiumTrialCell.accessoryType = .detailButton
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settingsNotifications.startObserving()
        refresh()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        settingsNotifications.stopObserving()
        super.viewWillDisappear(animated)
    }
    
    func dismissPopover(animated: Bool) {
        navigationController?.dismiss(animated: animated, completion: nil)
    }
    
    func refresh() {
        let settings = Settings.current
        startWithSearchSwitch.isOn = settings.isStartWithSearch
        
        let biometryType = LAContext.getBiometryType()
        if let biometryTypeName = biometryType.name {
            appSafetyCell.detailTextLabel?.text = NSLocalizedString(
                "App Lock, \(biometryTypeName), timeout",
                comment: "Settings: subtitle of the `App Protection` section. biometryTypeName will be either 'Touch ID' or 'Face ID'.")
        } else {
            appSafetyCell.detailTextLabel?.text = NSLocalizedString(
                "App Lock, passcode, timeout",
                comment: "Settings: subtitle of the `App Protection` section when biometric auth is not available.")
        }
        refreshPremiumStatus(animated: false)
    }
    
    /// Marks given cell as hidden/visible. The caller is responsible for refreshing the table.
    private func setCellVisibility(_ cell: UITableViewCell, isHidden: Bool) {
        cell.isHidden = isHidden
        if isHidden {
            switch cell {
            case premiumTrialCell:
                hiddenIndexPaths.insert(CellIndexPath.premiumTrial)
            case premiumStatusCell:
                hiddenIndexPaths.insert(CellIndexPath.premiumStatus)
            case restorePurchasesCell:
                hiddenIndexPaths.insert(CellIndexPath.restorePurchase)
            case manageSubscriptionCell:
                hiddenIndexPaths.insert(CellIndexPath.manageSubscription)
            default:
                break
            }
        } else {
            switch cell {
            case premiumTrialCell:
                hiddenIndexPaths.remove(CellIndexPath.premiumTrial)
            case premiumStatusCell:
                hiddenIndexPaths.remove(CellIndexPath.premiumStatus)
            case restorePurchasesCell:
                hiddenIndexPaths.remove(CellIndexPath.restorePurchase)
            case manageSubscriptionCell:
                hiddenIndexPaths.remove(CellIndexPath.manageSubscription)
            default:
                break
            }
        }
    }
    
    /// Returns App Lock status description: needs passcode/timeout/error
    private func getAppLockStatus() -> String {
        if Settings.current.isAppLockEnabled {
            return Settings.current.appLockTimeout.shortTitle
        } else {
            return LString.statusAppLockIsDisabled
        }
    }
    
    /// Hides hidden cells
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if hiddenIndexPaths.contains(indexPath) {
            return 0.0
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let selectedCell = tableView.cellForRow(at: indexPath) else { return }
        switch selectedCell {
        case appSafetyCell:
            let appLockSettingsVC = SettingsAppLockVC.instantiateFromStoryboard()
            show(appLockSettingsVC, sender: self)
        case autoFillCell:
            let autoFillSettingsVC = SettingsAutoFillVC.instantiateFromStoryboard()
            show(autoFillSettingsVC, sender: self)
        case dataSafetyCell:
            let dataProtectionSettingsVC = SettingsDataProtectionVC.instantiateFromStoryboard()
            show(dataProtectionSettingsVC, sender: self)
        case dataBackupCell:
            let dataBackupSettingsVC = SettingsBackupVC.instantiateFromStoryboard()
            show(dataBackupSettingsVC, sender: self)
        case premiumStatusCell:
            break // not interactive
        case premiumTrialCell:
            didPressUpgradeToPremium()
        case restorePurchasesCell:
            didPressRestorePurchses()
        case manageSubscriptionCell:
            didPressManageSubscription()
        case diagnosticLogCell:
            let viewer = ViewDiagnosticsVC.make()
            show(viewer, sender: self)
        case contactSupportCell:
            SupportEmailComposer.show(includeDiagnostics: false)
        case rateTheAppCell:
            AppStoreReviewHelper.writeReview()
        case aboutAppCell:
            let aboutVC = AboutVC.make()
            show(aboutVC, sender: self)
        default:
            break
        }
    }
    
    override func tableView(
        _ tableView: UITableView,
        accessoryButtonTappedForRowWith indexPath: IndexPath)
    {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        switch cell {
#if DEBUG
        case premiumStatusCell, premiumTrialCell:
            PremiumManager.shared.resetSubscription()
            refreshPremiumStatus(animated: true)
#endif
        default:
            assertionFailure() // should not be here
        }
    }
    
    // MARK: Actions
    @IBAction func doneButtonTapped(_ sender: Any) {
        dismissPopover(animated: true)
    }
    
    @IBAction func didChangeStartWithSearch(_ sender: Any) {
        Settings.current.isStartWithSearch = startWithSearchSwitch.isOn
        refresh()
    }
    
    // MARK: - Premium-related actions
    
    private var premiumCoordinator: PremiumCoordinator? // strong ref
    func didPressUpgradeToPremium() {
        assert(premiumCoordinator == nil)
        premiumCoordinator = PremiumCoordinator(presentingViewController: self)
        premiumCoordinator!.delegate = self
        premiumCoordinator!.start()
    }
    
    func didPressRestorePurchses() {
        assert(premiumCoordinator == nil)
        premiumCoordinator = PremiumCoordinator(presentingViewController: self)
        premiumCoordinator!.delegate = self
        premiumCoordinator!.start(tryRestoringPurchasesFirst: true)
    }
    
    func didPressManageSubscription() {
        guard let application = AppGroup.applicationShared,
            let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions")
            else { assertionFailure(); return }
        // open Manage Subscriptions page in AppStore
        application.open(url, options: [:])
    }
    
    // MARK: - Premium status
    
    #if DEBUG
    private let premiumRefreshInterval = 1.0
    #else
    private let premiumRefreshInterval = 10.0
    #endif
    
    @objc private func refreshPremiumStatus(animated: Bool) {
        let premiumManager = PremiumManager.shared
        premiumManager.updateStatus()
        switch premiumManager.status {
        case .initialGracePeriod:
            setCellVisibility(premiumTrialCell, isHidden: false)
            setCellVisibility(premiumStatusCell, isHidden: true)
            setCellVisibility(restorePurchasesCell, isHidden: false)
            setCellVisibility(manageSubscriptionCell, isHidden: true)
            
            let secondsLeft = premiumManager.gracePeriodSecondsRemaining
            let timeFormatted = DateComponentsFormatter.format(
                secondsLeft,
                allowedUnits: [.day, .hour, .minute, .second],
                maxUnitCount: 2) ?? "?"
            premiumTrialCell.detailTextLabel?.text = "Free trial: \(timeFormatted) remaining".localized(comment: "Status: remaining time of free trial. For example: `Free trial: 2d 23h remaining`")
            // make sure the countdown timer updates
            DispatchQueue.main.asyncAfter(deadline: .now() + premiumRefreshInterval) {
                [weak self] in
                self?.refreshPremiumStatus(animated: false)
            }
        case .subscribed:
            setCellVisibility(premiumTrialCell, isHidden: true)
            setCellVisibility(premiumStatusCell, isHidden: false)
            setCellVisibility(restorePurchasesCell, isHidden: true)
            setCellVisibility(manageSubscriptionCell, isHidden: false)
            
            let premiumStatusText: String
            if let expiryDate = premiumManager.getPremiumExpiryDate() {
                if expiryDate == .distantFuture {
                    premiumStatusText = "Valid forever".localized(comment: "Status: validity period of once-and-forever premium")
                } else {
                    #if DEBUG
                    let expiryDateString = DateFormatter
                        .localizedString(from: expiryDate, dateStyle: .medium, timeStyle: .short)
                    #else
                    let expiryDateString = DateFormatter
                        .localizedString(from: expiryDate, dateStyle: .medium, timeStyle: .none)
                    #endif
                    premiumStatusText = "Next renewal on \(expiryDateString)".localized(comment: "Status: scheduled renewal date of a premium subscription. For example: `Next renewal on 1 Jan 2050`")
                }
            } else {
                assertionFailure()
                premiumStatusText = "?"
            }
            premiumStatusCell.detailTextLabel?.text = premiumStatusText
        case .lapsed:
            setCellVisibility(premiumTrialCell, isHidden: false)
            setCellVisibility(premiumStatusCell, isHidden: false)
            setCellVisibility(restorePurchasesCell, isHidden: true)
            setCellVisibility(manageSubscriptionCell, isHidden: false)
            
            let premiumStatusText: String
            if let secondsSinceExpiration = premiumManager.secondsSinceExpiration {
                let timeFormatted = DateComponentsFormatter.format(
                    secondsSinceExpiration,
                    allowedUnits: [.day, .hour, .minute],
                    maxUnitCount: 1) ?? "?"
                premiumStatusText = "Expired \(timeFormatted) ago. Please renew.".localized(comment: "Status: premium subscription has expired. For example: `Expired 1 day ago`")
            } else {
                assertionFailure()
                premiumStatusText = "?"
            }
            premiumTrialCell.detailTextLabel?.text = ""
            premiumStatusCell.detailTextLabel?.text = premiumStatusText
            premiumStatusCell.detailTextLabel?.textColor = .errorMessage
            DispatchQueue.main.asyncAfter(deadline: .now() + premiumRefreshInterval) {
                [weak self] in
                self?.refreshPremiumStatus(animated: false)
            }
        case .expired:
            setCellVisibility(premiumTrialCell, isHidden: false)
            setCellVisibility(premiumStatusCell, isHidden: true)
            setCellVisibility(restorePurchasesCell, isHidden: false)
            setCellVisibility(manageSubscriptionCell, isHidden: true)
            
            if let subscriptionExpiryDate = premiumManager.getPremiumExpiryDate() {
                // had a subscription, it expired
                let secondsAgo = abs(subscriptionExpiryDate.timeIntervalSinceNow)
                let timeFormatted = DateComponentsFormatter.format(
                    secondsAgo,
                    allowedUnits: [.year, .month, .day, .hour, .minute, .second], //TODO: get rid of seconds
                    maxUnitCount: 1,
                    style: .full) ?? "?"
                premiumTrialCell.detailTextLabel?.text = "Expired \(timeFormatted) ago".localized(comment: "Status: how long ago the premium subscription has expired. For example: `Expired 12 days ago`")
            } else {
                // had a grace period, it ended
                let secondsAgo = abs(premiumManager.gracePeriodSecondsRemaining)
                let timeFormatted = DateComponentsFormatter.format(
                    secondsAgo,
                    allowedUnits: [.year, .month, .day, .hour, .minute, .second], //TODO: get rid of seconds
                    maxUnitCount: 1,
                    style: .full) ?? "?"
                premiumTrialCell.detailTextLabel?.text = "Free trial ended \(timeFormatted) ago".localized(comment: "Status: how long ago the free trial (grace period) has expired. For example: `Free trial ended 12 days ago`")
                
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + premiumRefreshInterval) {
                [weak self] in
                self?.refreshPremiumStatus(animated: false)
            }
        }
        if animated {
            tableView.beginUpdates()
            tableView.endUpdates()
        } else {
            tableView.reloadData()
        }
    }
}

// MARK: - SettingsObserver
extension SettingsVC: SettingsObserver {
    func settingsDidChange(key: Settings.Keys) {
        guard key != .recentUserActivityTimestamp else { return }
        refresh()
    }
}

// MARK: - PremiumCoordinatorDelegate
extension SettingsVC: PremiumCoordinatorDelegate {
    func didFinish(_ premiumCoordinator: PremiumCoordinator) {
        self.premiumCoordinator = nil
    }
}

extension DateComponentsFormatter {
    /// Converts number of seconds to human-readable string, e.g. "2h 25m"
    static func format(
        _ interval: TimeInterval,
        allowedUnits: NSCalendar.Unit,
        maxUnitCount: Int = 3,
        style: DateComponentsFormatter.UnitsStyle = .abbreviated,
        addRemainingPhrase: Bool = false
        ) -> String?
    {
        let timeFormatter = DateComponentsFormatter()
        timeFormatter.allowedUnits = allowedUnits
        timeFormatter.collapsesLargestUnit = true
        timeFormatter.includesTimeRemainingPhrase = addRemainingPhrase
        timeFormatter.maximumUnitCount = maxUnitCount
        timeFormatter.unitsStyle = style
        return timeFormatter.string(from: interval)
    }
}
