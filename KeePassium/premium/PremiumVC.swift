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
        
        statusLabel.text = NSLocalizedString(
            "[Premium/Upgrade/Progress] Contacting AppStore...",
            value: "Contacting AppStore...",
            comment: "Status message when downloading available in-app purchases")
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
    public func setAvailableProducts(_ unsortedProducts: [SKProduct]) {
        assert(self.products == nil)
        
        // show expensive first
        let products = unsortedProducts.sorted { (product1, product2) -> Bool in
            let isP1BeforeP2 = product1.price.doubleValue < product2.price.doubleValue
            return isP1BeforeP2
        }
        
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
        guard let iap = InAppProduct(rawValue: product.productIdentifier) else {
            assertionFailure()
            return NSAttributedString(string: "")
        }
        
        let productPrice: String
        switch iap.period {
        case .oneTime:
            productPrice = String.localizedStringWithFormat(
                NSLocalizedString(
                    "[Premium/Upgrade/price] %@ once",
                    value: "%@ once",
                    comment: "Product price for once-and-forever premium. [localizedPrice: String]"),
                [product.localizedPrice])
        case .yearly:
            productPrice = String.localizedStringWithFormat(
                NSLocalizedString(
                    "[Premium/Upgrade/price] %@ / year",
                    value: "%@ / year",
                    comment: "Product price for annual premium subscription. [localizedPrice: String]"),
                [product.localizedPrice])
        case .monthly:
            productPrice = String.localizedStringWithFormat(
                NSLocalizedString(
                    "[Premium/Upgrade/price] %@ / month",
                    value: "%@ / month",
                    comment: "Product price for monthly premium subscription. [localizedPrice: String]"),
                [product.localizedPrice])
        case .other:
            assertionFailure("Should not be here")
            productPrice = "\(product.localizedPrice)"
        }

        // Make the button title:
        //        Product Title
        //         $NN / year
        //          footnote
        
        let buttonTitle = NSMutableAttributedString(string: "")
        
        // Title
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.paragraphSpacing = 0.0
        titleParagraphStyle.alignment = .center
        let attributedTitle = NSMutableAttributedString(
            string: product.localizedTitle,
            attributes: [
                NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline),
                NSAttributedString.Key.paragraphStyle: titleParagraphStyle
            ]
        )
        buttonTitle.append(attributedTitle)
        
        // Description
        if iap.hasPrioritySupport {
            let prioritySupportDescription = NSLocalizedString(
                "[Premium/Upgrade/description] with priority support",
                value: "with priority support",
                comment: "Description of a premium option. Lowercase. For example 'Business Premium / with priority support'.")
            let descriptionParagraphStyle = NSMutableParagraphStyle()
            descriptionParagraphStyle.paragraphSpacingBefore = -3.0
            descriptionParagraphStyle.alignment = .center
            let attributedDescription = NSMutableAttributedString(
                string: "\n" + prioritySupportDescription,
                attributes: [
                    NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1),
                    NSAttributedString.Key.paragraphStyle: descriptionParagraphStyle
                ]
            )
            buttonTitle.append(attributedDescription)
        }
        
        // Price
        let priceParagraphStyle = NSMutableParagraphStyle()
        priceParagraphStyle.paragraphSpacingBefore = 3.0
        priceParagraphStyle.alignment = .center
        let attributedPrice = NSMutableAttributedString(
            string: "\n" + productPrice,
            attributes: [
                NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline),
                NSAttributedString.Key.paragraphStyle: priceParagraphStyle
            ]
        )
        buttonTitle.append(attributedPrice)

        return buttonTitle
    }
    
    private func makePurchaseButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 66).isActive = true
        button.setContentHuggingPriority(.required, for: .vertical)
        button.backgroundColor = UIColor.actionTint
        button.titleLabel?.textColor = UIColor.actionText
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.cornerRadius = 10.0
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
            showMessage(NSLocalizedString(
                "[Premium/Upgrade/Progress] Contacting AppStore...",
                value: "Contacting AppStore...",
                comment: "Status message when downloading available in-app purchases")
            )
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
