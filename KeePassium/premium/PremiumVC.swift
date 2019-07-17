//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit
import KeePassiumLib
import StoreKit

protocol PremiumDelegate: class {
    func didPressCancel(in premiumController: PremiumVC)
    func didPressRestorePurchases(in premiumController: PremiumVC)
    func didPressBuy(product: SKProduct, in premiumController: PremiumVC)
}

class PremiumVC: UIViewController {

    fileprivate let termsAndConditionsURL = URL(string: "https://keepassium.com/terms/app")!
    fileprivate let privacyPolicyURL = URL(string: "https://keepassium.com/privacy/app")!
    
    weak var delegate: PremiumDelegate?
    
    var allowRestorePurchases: Bool = true {
        didSet {
            guard isViewLoaded else { return }
            restorePurchasesButton.isHidden = !allowRestorePurchases
        }
    }
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var buttonStack: UIStackView!
    @IBOutlet weak var activityIndcator: UIActivityIndicatorView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var restorePurchasesButton: UIButton!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
    private var products: [SKProduct]?
    private var purchaseButtons = [UIButton]()
    
    
    public static func create(
        delegate: PremiumDelegate? = nil
        ) -> PremiumVC
    {
        let vc = PremiumVC.instantiateFromStoryboard()
        vc.delegate = delegate
        return vc
    }
    
    // MARK: - VC life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusLabel.text = "Contacting AppStore...".localized(comment: "Status message before downloading available in-app purchases")
        activityIndcator.isHidden = false
        restorePurchasesButton.isHidden = !allowRestorePurchases
        footerView.isHidden = true
    }
    
    // MARK: - Error message routines
    
    public func showMessage(_ message: String) {
        statusLabel.text = message
        activityIndcator.isHidden = true
        UIView.animate(withDuration: 0.3) {
            self.statusLabel.isHidden = false
        }
    }
    
    public func hideMessage() {
        UIView.animate(withDuration: 0.3) {
            self.activityIndcator.isHidden = true
            self.statusLabel.isHidden = true
        }
    }
    
    // MARK: - Purchase options setup
    
    /// Sets products available for purchase.
    /// Must be called only once for the VC instance.
    public func setAvailableProducts(_ products: [SKProduct]) {
        assert(self.products == nil)
        self.products = products
        purchaseButtons.removeAll()
        for index in 0..<products.count {
            let product = products[index]
            let title = getActionText(for: product)

            let button = makePurchaseButton()
            button.tag = index
            button.setAttributedTitle(title, for: .normal)
            button.addTarget(self, action: #selector(didPressPurchaseButton), for: .touchUpInside)
            button.isHidden = true // needed for vertical-only animation later
            buttonStack.addArrangedSubview(button)
            purchaseButtons.append(button)
        }
        // Showing hidden buttons allows for vertical-only animation.
        // Otherwise they appear from top-left.
        purchaseButtons.forEach { button in
            UIView.animate(withDuration: 0.5) { button.isHidden = false }
        }
        activityIndcator.isHidden = true
        statusLabel.isHidden = true
        // Show conditions only when there are some products to buy.
        UIView.animate(withDuration: 0.5) {
            self.footerView.isHidden = false
        }
    }
    
    /// Returns formatted text for product's purchase button
    private func getActionText(for product: SKProduct) -> NSAttributedString {
        let productKind = InAppProduct.kind(productIdentifier: product.productIdentifier)
        let productTitle: String
        let productPrice: String
        switch productKind {
        case .oneTime:
            productTitle = "Lifetime".localized(comment: "Product description: once-and-forever premium")
            productPrice = "\(product.localizedPrice) once".localized(comment: "Product price for once-and-forever premium")
        case .yearly:
            productTitle = "1 year".localized(comment: "Product description: annual premium subscription")
            productPrice = "\(product.localizedPrice) / year".localized(comment: "Product price for annual premium subscription")
        case .monthly:
            productTitle = "1 month".localized(comment: "Product description: monthly premium subscription")
            productPrice = "\(product.localizedPrice) / month".localized(comment: "Product price for monthly premium subscription")
        case .other:
            assertionFailure("Should not be here")
            productTitle = ""
            productPrice = "\(product.localizedPrice)"
        }
        let attributedTitle = NSMutableAttributedString(
            string: productTitle + "\n",
            attributes: [
                NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)
            ]
        )
        let attributedPrice = NSMutableAttributedString(
            string: productPrice,
            attributes: [
                NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline)
            ]
        )
        attributedTitle.append(attributedPrice)
        return attributedTitle
    }
    
    private func makePurchaseButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
        button.setContentHuggingPriority(.required, for: .vertical)
        button.backgroundColor = UIColor.actionTint
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.titleLabel?.textColor = UIColor.actionText
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.cornerRadius = 5.0
        return button
    }
    
    // MARK: - Purchasing
    
    /// Locks/unlocks user interaction during purchase communication with AppStore.
    ///
    /// - Parameter isPurchasing: true when purchasing, false once done.
    public func setPurchasing(_ isPurchasing: Bool) {
        cancelButton.isEnabled = !isPurchasing
        restorePurchasesButton.isEnabled = !isPurchasing
        purchaseButtons.forEach { button in
            button.isEnabled = !isPurchasing
            UIView.animate(withDuration: 0.3) {
                button.alpha = isPurchasing ? 0.5 : 1.0
            }
        }
        if isPurchasing {
            showMessage("Contacting AppStore...".localized(comment: "Status: transaction related to in-app purchase (not necessarily a purchase) is in progress"))
            UIView.animate(withDuration: 0.3) {
                self.activityIndcator.isHidden = false
            }
        } else {
            hideMessage()
            UIView.animate(withDuration: 0.3) {
                self.activityIndcator.isHidden = true
            }
        }
    }

    // MARK: - Actions
    
    @IBAction func didPressCancel(_ sender: Any) {
        delegate?.didPressCancel(in: self)
    }
    
    @IBAction func didPressRestorePurchases(_ sender: Any) {
        setPurchasing(true)
        delegate?.didPressRestorePurchases(in: self)
    }
    
    @objc private func didPressPurchaseButton(_ sender: UIButton) {
        guard let products = products else { assertionFailure(); return }
        setPurchasing(true)
        let productIndex = sender.tag
        delegate?.didPressBuy(product: products[productIndex], in: self)
    }
    
    @IBAction func didPressTerms(_ sender: Any) {
        AppGroup.applicationShared?.open(termsAndConditionsURL, options: [:])
    }
    @IBAction func didPressPrivacyPolicy(_ sender: Any) {
        AppGroup.applicationShared?.open(privacyPolicyURL, options: [:])
    }
}
